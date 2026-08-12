"""
First-pass grid autorouter for headunit_carrier.kicad_pcb.

Strategy: every SMD pad in this project lives on F.Cu only, so we drop a
via-in-pad at every pad and route the actual copper on the (otherwise
empty) B.Cu layer using A* on a coarse grid. This keeps the routing
problem to a single free layer instead of juggling F.Cu obstacles, at the
cost of a via under every pad -- flagged in the README as something to
clean up (move vias off-pad, spread nets across the inner signal layers)
during manual review.

Differential pairs (DSI) are routed as two independent single-ended nets
-- connectivity/DRC-clean, but NOT length-matched or coupled. That must be
redone by hand (or with KiCad's diff-pair router) before this is treated
as final for a high-speed interface.
"""
import heapq, math, uuid
import numpy as np
from kiutils.board import Board, Segment, Via, Net as BNet
from kiutils.items.common import Position

SRC = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.kicad_pcb"
DST = SRC

GRID = 0.6           # mm per cell
CLEARANCE_CELLS = 1  # inflate blocked regions by this many cells
VIA_SIZE = 0.6
VIA_DRILL = 0.3
ROUTE_LAYERS = ["B.Cu", "In4.Cu", "In3.Cu", "In2.Cu", "In1.Cu"]  # try in this order, fall back on congestion

POWER_NETS = {"GND", "+12V_RAW", "+12V_FUSED", "+12V_PROT", "+5V_OUT", "+5V_SWITCHED",
              "+3V3", "+3V3_STBY", "U1_SW_NODE", "VLED_A", "BL_SW"}

def u():
    return str(uuid.uuid4())

def trace_width(net_name):
    return 0.4 if net_name in POWER_NETS else 0.2

board = Board.from_file(SRC)

BX0, BY0, BX1, BY1 = 10, 10, 380, 285  # must match gen_pcb.py board outline
nx = int((BX1 - BX0) / GRID) + 1
ny = int((BY1 - BY0) / GRID) + 1
blocked = np.zeros((nx, ny), dtype=bool)

def to_grid(x, y):
    gx = int(round((x - BX0) / GRID))
    gy = int(round((y - BY0) / GRID))
    gx = min(max(gx, 0), nx - 1)
    gy = min(max(gy, 0), ny - 1)
    return gx, gy

def to_mm(gx, gy):
    return BX0 + gx * GRID, BY0 + gy * GRID

def block_disc(cx, cy, radius_mm):
    r = int(math.ceil(radius_mm / GRID))
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                gx, gy = cx + dx, cy + dy
                if 0 <= gx < nx and 0 <= gy < ny:
                    blocked[gx, gy] = True

# Block mounting holes (they have empty ref "MH*")
for fp in board.footprints:
    if fp.entryName == "MOUNTING_HOLE_M3":
        gx, gy = to_grid(fp.position.X, fp.position.Y)
        block_disc(gx, gy, 3.5)

# Collect pads per net, in absolute PCB coordinates (unrotated placement)
nets_pads = {}
for fp in board.footprints:
    ref = None
    for gi in fp.graphicItems:
        if getattr(gi, "type", None) == "reference":
            ref = gi.text
    for pad in fp.pads:
        if pad.net is None or pad.net.name == "":
            continue
        ax = fp.position.X + pad.position.X
        ay = fp.position.Y + pad.position.Y
        nets_pads.setdefault(pad.net.name, []).append((ref, pad.number, ax, ay))

print(f"Grid: {nx}x{ny} cells @ {GRID}mm | nets to route: {len(nets_pads)}")

def astar(start, goal, blocked, extra_blocked):
    if start == goal:
        return [start]
    openset = [(0, start)]
    gscore = {start: 0}
    came = {}
    closed = set()
    while openset:
        _, cur = heapq.heappop(openset)
        if cur in closed:
            continue
        if cur == goal:
            path = [cur]
            while cur in came:
                cur = came[cur]
                path.append(cur)
            path.reverse()
            return path
        closed.add(cur)
        cx, cy = cur
        # 4-directional only: diagonal moves let two different-net paths cross
        # like an X without ever sharing a grid cell, which the clearance
        # marking can't catch. Manhattan-only guarantees any real crossing
        # passes through a shared, blockable cell.
        for dx, dy, cost in ((1,0,1),(-1,0,1),(0,1,1),(0,-1,1)):
            nxp, nyp = cx + dx, cy + dy
            if not (0 <= nxp < blocked.shape[0] and 0 <= nyp < blocked.shape[1]):
                continue
            npt = (nxp, nyp)
            if npt != goal and (blocked[nxp, nyp] or npt in extra_blocked):
                continue
            ng = gscore[cur] + cost
            if ng < gscore.get(npt, 1e18):
                gscore[npt] = ng
                h = math.hypot(goal[0]-nxp, goal[1]-nyp)
                heapq.heappush(openset, (ng + h, npt))
                came[npt] = cur
    return None

def mark_path(path, extra_blocked):
    for (gx, gy) in path:
        for dx in range(-CLEARANCE_CELLS, CLEARANCE_CELLS + 1):
            for dy in range(-CLEARANCE_CELLS, CLEARANCE_CELLS + 1):
                extra_blocked.add((gx + dx, gy + dy))

def collapse(path_mm):
    """Collapse collinear runs of grid points into minimal segment endpoints."""
    if len(path_mm) < 2:
        return path_mm
    out = [path_mm[0]]
    for i in range(1, len(path_mm) - 1):
        x0, y0 = out[-1]
        x1, y1 = path_mm[i]
        x2, y2 = path_mm[i + 1]
        # collinear check (cross product ~ 0)
        cross = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
        if abs(cross) > 1e-6:
            out.append(path_mm[i])
    out.append(path_mm[-1])
    return out

global_blocked = {layer: set() for layer in ROUTE_LAYERS}  # per-layer, occupied by OTHER nets
routed_nets = 0
failed_edges = []
segments_out = []
vias_out = []
net_index = {n.name: n.number for n in board.nets}

# Pre-pass: every pad gets a through via-in-pad (spans every layer). Record
# which net owns each via's footprint (center + clearance halo) BEFORE any
# trace routing starts, so no OTHER net's trace can be routed across it on
# ANY layer -- this is what DRC flagged as "items shorting two nets".
via_owner = {}   # (gx, gy) -> net_name
VIA_HALO_MM = VIA_SIZE / 2 + 0.25
def halo_cells(cx, cy, radius_mm):
    r = int(math.ceil(radius_mm / GRID))
    cells = []
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                cells.append((cx + dx, cy + dy))
    return cells

for net_name, pads in nets_pads.items():
    for (ref, pinnum, ax, ay) in pads:
        gx, gy = to_grid(ax, ay)
        for cell in halo_cells(gx, gy, VIA_HALO_MM):
            via_owner[cell] = net_name

for net_name, pads in nets_pads.items():
    if net_name not in net_index:
        continue
    ncode = net_index[net_name]
    w = trace_width(net_name)

    other_via_blocked = {cell for cell, owner in via_owner.items() if owner != net_name}

    # Drop a through via-in-pad at every pad on this net (reaches every layer,
    # so it doesn't matter which inner layer the actual trace ends up on)
    grid_points = []
    for (ref, pinnum, ax, ay) in pads:
        vias_out.append(Via(type=None, position=Position(X=round(ax,3), Y=round(ay,3), angle=0),
                             size=VIA_SIZE, drill=VIA_DRILL, layers=["F.Cu", "B.Cu"],
                             net=ncode, tstamp=u()))
        grid_points.append(to_grid(ax, ay))

    # Prim's MST over Euclidean distance, then A* route each MST edge
    if len(grid_points) < 2:
        continue
    in_tree = {0}
    remaining = set(range(1, len(grid_points)))
    edges = []
    while remaining:
        best = None
        for i in in_tree:
            for j in remaining:
                d = math.hypot(grid_points[i][0]-grid_points[j][0], grid_points[i][1]-grid_points[j][1])
                if best is None or d < best[0]:
                    best = (d, i, j)
        _, i, j = best
        edges.append((i, j))
        in_tree.add(j)
        remaining.discard(j)

    net_local_blocked = {layer: set() for layer in ROUTE_LAYERS}  # this net's own cells: never self-block
    for (i, j) in edges:
        chosen_layer = None
        path = None
        for layer in ROUTE_LAYERS:
            combined_blocked = (global_blocked[layer] - net_local_blocked[layer]) | other_via_blocked
            path = astar(grid_points[i], grid_points[j], blocked, combined_blocked)
            if path is not None:
                chosen_layer = layer
                break
        if path is None:
            failed_edges.append((net_name, pads[i][:2], pads[j][:2]))
            continue
        mark_path(path, net_local_blocked[chosen_layer])
        path_mm = collapse([to_mm(gx, gy) for (gx, gy) in path])
        for k in range(len(path_mm) - 1):
            (x1, y1), (x2, y2) = path_mm[k], path_mm[k+1]
            if (x1, y1) == (x2, y2):
                continue
            segments_out.append(Segment(start=Position(X=round(x1,3), Y=round(y1,3)),
                                         end=Position(X=round(x2,3), Y=round(y2,3)),
                                         width=w, layer=chosen_layer, net=ncode, tstamp=u()))
    for layer in ROUTE_LAYERS:
        global_blocked[layer] |= net_local_blocked[layer]
    routed_nets += 1

board.traceItems = segments_out + vias_out
board.filePath = DST
board.to_file()

print(f"Routed {routed_nets} nets | segments: {len(segments_out)} | vias: {len(vias_out)}")
print(f"Failed edges (need manual routing): {len(failed_edges)}")
for f in failed_edges:
    print("  FAILED:", f)
