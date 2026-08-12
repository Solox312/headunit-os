import os, sys, uuid
sys.path.insert(0, '.')
if 'gen_schematic' in sys.modules: del sys.modules['gen_schematic']
import gen_schematic as g   # reuses components/nets/symdefs already validated

from kiutils.board import Board, Net as BNet, LayerToken
from kiutils.footprint import Footprint, Pad, DrillDefinition, Attributes
from kiutils.items.fpitems import FpText, FpLine
from kiutils.items.common import Position, Effects, Font
from kiutils.items.gritems import GrLine

LIB = "headunit_carrier"
PRETTY_DIR = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.pretty"
os.makedirs(PRETTY_DIR, exist_ok=True)

def u():
    return str(uuid.uuid4())

# ---------------------------------------------------------------------------
# Build one generic footprint per unique (fp name) used in the schematic, with
# pad COUNT and NUMBERING taken directly from that component's symbol pins,
# so PCB nets line up exactly with the schematic (no separate hand-authored
# pad map to get out of sync). Physical pad size/pitch are generic placeholders
# -- swap in exact vendor footprints (SODIMM socket, FPC connector, USB, ICs)
# before sending to fab.
# ---------------------------------------------------------------------------
fp_pins = {}   # fp_name -> list of (pin_number, pin_name)
for c in g.components:
    sdef = g.symdefs[c["entry"]]
    pins = [(p.number, p.name) for p in sdef.pins]
    if c["fp"] in fp_pins:
        assert len(fp_pins[c["fp"]]) == len(pins), f"pin count mismatch for {c['fp']}"
    else:
        fp_pins[c["fp"]] = pins

def build_footprint(name, pins):
    fpobj = Footprint()
    fpobj.libraryNickname = LIB
    fpobj.entryName = name
    fpobj.version = "20211014"
    fpobj.generator = "headunit_gen"
    fpobj.layer = "F.Cu"
    fpobj.attributes = Attributes(type="smd")
    fpobj.tstamp = u()

    n = len(pins)
    pitch = 1.27
    pad_size = Position(X=0.8, Y=0.8)
    pads = []

    if n <= 2:
        # simple 2-terminal passive, pads left/right
        span = 3.0
        pad_size = Position(X=1.0, Y=1.2)
        xs = [-span/2, span/2]
        for i, (num, pname) in enumerate(pins):
            pads.append(Pad(number=num, type="smd", shape="roundrect", roundrectRatio=0.25,
                             position=Position(X=xs[i], Y=0, angle=0), size=pad_size,
                             layers=["F.Cu", "F.Paste", "F.Mask"]))
        courtyard = (span/2 + 1.2, 1.2)
    else:
        # dual-row (or single row if small), pin 1 at top-left, numbering down
        # then up the other side -- like a DIP/SODIMM edge footprint.
        row_pitch = max(6.0, pitch * (n / 2) * 0.15 + 4.0)
        half = (n + 1) // 2
        for i, (num, pname) in enumerate(pins):
            if i < half:
                x = -row_pitch / 2
                y = -((half - 1) * pitch) / 2 + i * pitch
            else:
                x = row_pitch / 2
                j = i - half
                y = -((n - half - 1) * pitch) / 2 + j * pitch
            pads.append(Pad(number=num, type="smd", shape="roundrect", roundrectRatio=0.25,
                             position=Position(X=round(x,3), Y=round(y,3), angle=0), size=pad_size,
                             layers=["F.Cu", "F.Paste", "F.Mask"]))
        courtyard = (row_pitch/2 + 1.5, (half*pitch)/2 + 1.5)

    fpobj.pads = pads

    cy_x, cy_y = courtyard
    fpobj.graphicItems = [
        FpLine(start=Position(X=-cy_x, Y=-cy_y), end=Position(X=cy_x, Y=-cy_y), layer="F.CrtYd", width=0.05),
        FpLine(start=Position(X=cy_x, Y=-cy_y), end=Position(X=cy_x, Y=cy_y), layer="F.CrtYd", width=0.05),
        FpLine(start=Position(X=cy_x, Y=cy_y), end=Position(X=-cy_x, Y=cy_y), layer="F.CrtYd", width=0.05),
        FpLine(start=Position(X=-cy_x, Y=cy_y), end=Position(X=-cy_x, Y=-cy_y), layer="F.CrtYd", width=0.05),
        FpLine(start=Position(X=-cy_x, Y=-cy_y-0.3), end=Position(X=cy_x, Y=-cy_y-0.3), layer="F.SilkS", width=0.12),
        FpText(type="reference", text="REF**", position=Position(X=0, Y=-cy_y-1.4, angle=0),
               layer="F.SilkS", effects=Effects(font=Font(height=1.0, width=1.0))),
        FpText(type="value", text=name, position=Position(X=0, Y=cy_y+1.4, angle=0),
               layer="F.Fab", effects=Effects(font=Font(height=1.0, width=1.0))),
    ]
    fpobj.filePath = os.path.join(PRETTY_DIR, f"{name}.kicad_mod")
    fpobj.to_file()
    return fpobj

footprint_templates = {}
for fp_name, pins in fp_pins.items():
    footprint_templates[fp_name] = build_footprint(fp_name, pins)

print(f"Generated {len(footprint_templates)} footprints in {PRETTY_DIR}")

# ---------------------------------------------------------------------------
# Compact floorplan: pack components tightly per block instead of reusing the
# spread-out schematic X/Y (those were sized for schematic *readability*, not
# real board area -- reusing them 1:1 produced a 370x275mm board, ~7x the area
# actually needed). Each block is shelf-packed on its own, blocks are then
# tiled on a grid with a routing-channel gap between them.
# ---------------------------------------------------------------------------
def fp_extent(fp_name):
    """Half-width, half-height of a footprint's courtyard (mirrors build_footprint's sizing)."""
    n = len(fp_pins[fp_name])
    pitch = 1.27
    if n <= 2:
        span = 3.0
        return (span / 2 + 1.2, 1.2)
    else:
        row_pitch = max(6.0, pitch * (n / 2) * 0.15 + 4.0)
        half = (n + 1) // 2
        return (row_pitch / 2 + 1.5, (half * pitch) / 2 + 1.5)

GAP = 4.0        # mm between adjacent footprints within a block
BLOCK_GAP = 20.0  # mm routing channel between blocks
MARGIN = 15.0     # mm board edge margin (also hosts the mounting holes)

def pack_block(comps, max_width):
    """Shelf-pack components into rows up to max_width wide. Returns
    ({ref: (x,y)} relative to block's own top-left, block_width, block_height)."""
    items = []
    for c in comps:
        hw, hh = fp_extent(c["fp"])
        items.append((c["ref"], hw, hh))
    items.sort(key=lambda t: -t[2])  # tallest first, for tidier shelves

    placements = {}
    x_cursor = y_cursor = shelf_h = max_w_used = 0.0
    for ref, hw, hh in items:
        w, h = hw * 2, hh * 2
        if x_cursor > 0 and x_cursor + w > max_width:
            x_cursor = 0.0
            y_cursor += shelf_h + GAP
            shelf_h = 0.0
        placements[ref] = (x_cursor + hw, y_cursor + hh)
        x_cursor += w + GAP
        shelf_h = max(shelf_h, h)
        max_w_used = max(max_w_used, x_cursor - GAP)
    return placements, max_w_used, y_cursor + shelf_h

by_block = {}
for c in g.components:
    by_block.setdefault(c["block"], []).append(c)

BLOCK_MAXW = dict(PWR=48, DCDC=48, IGN=48, USB=48, SOM=200, DISP=42, AUD=48, FM=42)
block_pack = {blk: pack_block(comps, BLOCK_MAXW[blk]) for blk, comps in by_block.items()}

# 3x3 grid: SOM (the hub) in the center, DCDC feeding it from above, DISP/USB
# either side (DSI + USB both terminate at the SOM), IGN/AUD/FM filling out
# the remaining electrical neighbors.
grid = {
    "PWR": (0, 0), "DCDC": (1, 0), "IGN": (2, 0),
    "USB": (0, 1), "SOM": (1, 1), "DISP": (2, 1),
                    "AUD": (1, 2), "FM": (2, 2),
}
ncols, nrows = 3, 3
col_w = [0.0] * ncols
row_h = [0.0] * nrows
for blk, (col, row) in grid.items():
    _, w, h = block_pack[blk]
    col_w[col] = max(col_w[col], w)
    row_h[row] = max(row_h[row], h)

col_x = [0.0] * ncols
for c in range(1, ncols):
    col_x[c] = col_x[c - 1] + col_w[c - 1] + BLOCK_GAP
row_y = [0.0] * nrows
for r in range(1, nrows):
    row_y[r] = row_y[r - 1] + row_h[r - 1] + BLOCK_GAP

pcb_pos = {}  # ref -> (x, y) relative to packed-content origin (0,0)
for blk, (col, row) in grid.items():
    placements, _, _ = block_pack[blk]
    ox, oy = col_x[col], row_y[row]
    for ref, (x, y) in placements.items():
        pcb_pos[ref] = (ox + x, oy + y)

content_w = col_x[-1] + col_w[-1]
content_h = row_y[-1] + row_h[-1]

# Sanity check: no two footprints' courtyards overlap.
comps_by_ref = {c["ref"]: c for c in g.components}
refs = list(pcb_pos.keys())
overlaps = []
for i in range(len(refs)):
    for j in range(i + 1, len(refs)):
        r1, r2 = refs[i], refs[j]
        x1, y1 = pcb_pos[r1]; x2, y2 = pcb_pos[r2]
        hw1, hh1 = fp_extent(comps_by_ref[r1]["fp"])
        hw2, hh2 = fp_extent(comps_by_ref[r2]["fp"])
        if abs(x1 - x2) < (hw1 + hw2) and abs(y1 - y2) < (hh1 + hh2):
            overlaps.append((r1, r2))
assert not overlaps, f"footprint overlaps detected: {overlaps}"
print(f"Compact floorplan: {content_w:.1f} x {content_h:.1f} mm content, 0 overlaps")

# ---------------------------------------------------------------------------
# Board: 6-layer stackup, outline, mounting holes, footprints placed on the
# compact grid above, nets assigned to every pad from the schematic netlist.
# ---------------------------------------------------------------------------
board = Board.create_new()
board.general.thickness = 1.6
board.layers = [
    LayerToken(ordinal=0, name="F.Cu", type="signal"),
    LayerToken(ordinal=1, name="In1.Cu", type="signal", userName="GND_PLANE"),
    LayerToken(ordinal=2, name="In2.Cu", type="signal", userName="PWR_PLANE"),
    LayerToken(ordinal=3, name="In3.Cu", type="signal"),
    LayerToken(ordinal=4, name="In4.Cu", type="signal"),
    LayerToken(ordinal=31, name="B.Cu", type="signal"),
    LayerToken(ordinal=32, name="B.Adhes", type="user", userName="B.Adhesive"),
    LayerToken(ordinal=33, name="F.Adhes", type="user", userName="F.Adhesive"),
    LayerToken(ordinal=34, name="B.Paste", type="user"),
    LayerToken(ordinal=35, name="F.Paste", type="user"),
    LayerToken(ordinal=36, name="B.SilkS", type="user", userName="B.Silkscreen"),
    LayerToken(ordinal=37, name="F.SilkS", type="user", userName="F.Silkscreen"),
    LayerToken(ordinal=38, name="B.Mask", type="user"),
    LayerToken(ordinal=39, name="F.Mask", type="user"),
    LayerToken(ordinal=44, name="Edge.Cuts", type="user"),
    LayerToken(ordinal=46, name="B.CrtYd", type="user", userName="B.Courtyard"),
    LayerToken(ordinal=47, name="F.CrtYd", type="user", userName="F.Courtyard"),
    LayerToken(ordinal=48, name="B.Fab", type="user"),
    LayerToken(ordinal=49, name="F.Fab", type="user"),
]

# Board outline: packed-content bbox plus MARGIN on every side (real size,
# not a placeholder -- see the compact floorplan block above).
BX0, BY0 = 10, 10
BX1, BY1 = round(BX0 + content_w + 2 * MARGIN, 1), round(BY0 + content_h + 2 * MARGIN, 1)
board.graphicItems = [
    GrLine(start=Position(X=BX0, Y=BY0), end=Position(X=BX1, Y=BY0), layer="Edge.Cuts", width=0.15),
    GrLine(start=Position(X=BX1, Y=BY0), end=Position(X=BX1, Y=BY1), layer="Edge.Cuts", width=0.15),
    GrLine(start=Position(X=BX1, Y=BY1), end=Position(X=BX0, Y=BY1), layer="Edge.Cuts", width=0.15),
    GrLine(start=Position(X=BX0, Y=BY1), end=Position(X=BX0, Y=BY0), layer="Edge.Cuts", width=0.15),
]

# Net table
net_names = ["" ] + sorted(g.nets.keys())  # net 0 is always the unconnected net
net_index = {name: i for i, name in enumerate(net_names)}
board.nets = [BNet(number=i, name=name) for i, name in enumerate(net_names)]

# Reverse map: (ref, pin) -> net name
pin_to_net = {}
for net_name, members in g.nets.items():
    for ref, pin in members:
        pin_to_net[(ref, str(pin))] = net_name

# Mounting holes (NPTH, 3.2mm) at four corners, 6mm inset
def mounting_hole(x, y, ref):
    fp = Footprint()
    fp.libraryNickname = LIB
    fp.entryName = "MOUNTING_HOLE_M3"
    fp.layer = "F.Cu"
    fp.attributes = Attributes(type=None, boardOnly=False, excludeFromBom=True, excludeFromPosFiles=True)
    fp.position = Position(X=x, Y=y, angle=0)
    fp.tstamp = u()
    fp.pads = [Pad(number="", type="np_thru_hole", shape="circle",
                    position=Position(X=0, Y=0, angle=0), size=Position(X=3.2, Y=3.2),
                    drill=DrillDefinition(diameter=3.2), layers=["*.Cu", "*.Mask"])]
    fp.graphicItems = [
        FpText(type="reference", text=ref, position=Position(X=0, Y=-3, angle=0),
               layer="F.SilkS", hide=True, effects=Effects(font=Font(height=1.0, width=1.0))),
    ]
    return fp

mount_positions = [(BX0+6, BY0+6), (BX1-6, BY0+6), (BX1-6, BY1-6), (BX0+6, BY1-6)]
for i, (x, y) in enumerate(mount_positions):
    board.footprints.append(mounting_hole(x, y, f"MH{i+1}"))

# Place one footprint instance per schematic component, at its packed compact
# position (offset into the board by BX0+MARGIN, BY0+MARGIN); assign nets to
# every pad from the schematic netlist.
placed = 0
unplaced_pads = 0
for c in g.components:
    tmpl = footprint_templates[c["fp"]]
    fp = Footprint.from_file(tmpl.filePath)  # fresh copy
    fp.libraryNickname = LIB
    fp.entryName = c["fp"]
    px, py = pcb_pos[c["ref"]]
    fp.position = Position(X=round(BX0 + MARGIN + px, 3), Y=round(BY0 + MARGIN + py, 3), angle=0)
    fp.tstamp = u()
    fp.attributes = Attributes(type="smd")
    for pad in fp.pads:
        key = (c["ref"], pad.number)
        net_name = pin_to_net.get(key)
        if net_name:
            pad.net = BNet(number=net_index[net_name], name=net_name)
        else:
            unplaced_pads += 1
    # Ref/value silkscreen text -> actual designator
    for item in fp.graphicItems:
        if isinstance(item, FpText) and item.type == "reference":
            item.text = c["ref"]
        if isinstance(item, FpText) and item.type == "value":
            item.text = c["value"][:24]
    board.footprints.append(fp)
    placed += 1

print(f"Placed {placed} footprints, {unplaced_pads} pads without a net (expected: only true NC pins)")

board.filePath = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.kicad_pcb"
board.to_file()
print("wrote PCB")
