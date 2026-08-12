# HeadUnit OS Carrier Board — KiCad Project

Open `headunit_carrier.kicad_pro` in KiCad (6/7/8). Everything the project needs — symbols, footprints, library tables — is stored relative to this folder (`headunit_carrier.kicad_sym`, `headunit_carrier.pretty/`, `sym-lib-table`, `fp-lib-table`), so it opens the same on any machine without depending on your global KiCad library setup.

This corresponds directly to `docs/pcb_carrier_board_design.md` and `docs/pcb_carrier_board_bom.xlsx` — read those first for the design rationale.

## What's done

- **Schematic** (`headunit_carrier.kicad_sch`): all 40 components from the BOM, fully wired — power input protection, buck/LDO regulation, ignition-sense + safe-shutdown logic, the RK3566/RK3568 SODIMM SoM socket, MIPI-DSI display connector, audio codec + isolation transformer, Si4713 FM transmitter, and USB/debug. Every pin is either connected to a net or explicitly flagged no-connect — verified with a script that checks for unconnected pins and accidental shorts (both come back clean).
- **PCB** (`headunit_carrier.kicad_pcb`): 6-layer stackup, board outline, 4 mounting holes, and all 40 footprints placed in a floorplan that mirrors the schematic's block layout, every pad pre-assigned to its net from the schematic.

## Routing status: routed via Freerouting, DRC-clean

The board is fully routed and **passes KiCad's Design Rules Checker with 0 errors, 0 unconnected items** (checked in KiCad 10 on 2026-08-09). Stats: 537 track segments, 162 vias, all 60 nets connected.

How it got there, for context: an earlier custom Python autorouter (`generator/gen_route.py`, kept in this repo for reference) got most of the way but kept producing real DRC violations (track crossings, clearance issues) that it couldn't fully self-correct. The board was re-routed instead using **Freerouting** (https://github.com/freerouting/freerouting), a mature open-source autorouter, via KiCad's official plugin (Tools → External Plugins → Freerouting, installed through the Plugin and Content Manager). That run is what's currently in `headunit_carrier.kicad_pcb`. If you want to re-run it yourself: Plugin and Content Manager → install "Freerouting" → open the board in PCB Editor → Tools → External Plugins → Freerouting (requires a Java 25+ JRE on the machine, e.g. Eclipse Temurin).

Remaining warnings (4, all cosmetic): DRC flags the 4 mounting-hole footprints (`MOUNTING_HOLE_M3`) as "not found in library 'headunit_carrier'" because they were placed programmatically without a matching `.kicad_mod` file — purely a library-metadata nitpick, not an electrical or manufacturing problem.

What a clean DRC does **not** cover — still worth doing before this is fab-final:
- **MIPI-DSI differential pairs** (`DSI_CLK_P/N`, `DSI_D0..D3_P/N`) — Freerouting routes for connectivity/clearance, not signal integrity. These should be reviewed/re-routed as coupled, length-matched pairs using KiCad's differential pair router before treating this as final for a high-speed interface.
- **Trace widths**: 0.2mm signal / 0.4mm power (GND, +12V*, +5V*, +3V3*, VLED_A, backlight switch node) — sane defaults, but re-check current-carrying nets (especially +12V input and +5V to the SoM) against your actual expected current draw.
- **No copper pour/plane fill** was added on `In1.Cu`/`In2.Cu` (nominally reserved as GND/PWR planes in the stackup). Decide during layout review whether to add solid pours there for better EMI/return-path quality, especially given the MIPI-DSI and DDR-adjacent signals here.

## What's still placeholder (not done, and not attempted here)

- **Footprints are generic** (simple pad arrays sized by pin count), not exact vendor packages. Before sending to fab, replace: the SODIMM socket footprint with the real connector's footprint from its datasheet, the display FPC connector with the exact panel vendor's footprint, and the USB-A/USB-C/SMA footprints with real ones (KiCad's stock `Connector_USB`/`Connector_SMA` libraries have these).
- **Board outline** (380×275mm placeholder rectangle) — resize to your actual dash cavity/enclosure dimensions; the current size was only picked to give the autorouter room to work.
- A few application circuits are simplified for schematic clarity (e.g. the Si4713 crystal network, mic bias) — cross-check against each part's datasheet reference design before finalizing.

## Regenerating

The `generator/` folder has the Python scripts (using the `kiutils` library) that built this project from the design doc's block list. If you want to add/remove a component or change a net, it's likely faster to edit `generator/gen_schematic.py`'s `components`/`nets` dicts and rerun `gen_symbols.py` → `gen_schematic.py` → `gen_pcb.py` (in that order) than to hand-edit the generated files. That leaves you with an unrouted board with nets assigned — re-route it via the Freerouting plugin as described above (this is the recommended path; `gen_route.py` is kept only for reference and is not what produced the current routed board).
