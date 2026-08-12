import uuid
from kiutils.symbol import SymbolLib
from kiutils.schematic import (Schematic, SchematicSymbol, GlobalLabel, SymbolInstance,
                                HierarchicalSheetInstance, Text, NoConnect)
from kiutils.items.common import Position, Effects, Font, Property, Justify

LIB = "headunit_carrier"
libpath = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.kicad_sym"
symlib = SymbolLib.from_file(libpath)
symdefs = {s.entryName: s for s in symlib.symbols}

def u():
    return str(uuid.uuid4())

# ---------------------------------------------------------------------------
# Component placements: ref, entry (symbol name), value, footprint, x, y, block
# ---------------------------------------------------------------------------
components = [
    # --- Power Input & Protection ---
    dict(ref="J1", entry="CONN_3W", value="PWR_IN_HARNESS", fp="CONN_3W_TERMINAL", x=25, y=35, block="PWR"),
    dict(ref="F1", entry="FUSE", value="3A_PTC", fp="FUSE_1210", x=45, y=25, block="PWR"),
    dict(ref="Q1", entry="Q_PMOS", value="DMP3098L", fp="SOT23", x=60, y=35, block="PWR"),
    dict(ref="D1", entry="D_TVS", value="SMAJ15A", fp="SOD123", x=45, y=45, block="PWR"),
    dict(ref="C1", entry="C_POL", value="100uF", fp="CAP_D5", x=75, y=25, block="PWR"),
    dict(ref="C2", entry="C", value="0.1uF", fp="C_0603", x=85, y=25, block="PWR"),

    # --- DC-DC Power Conversion ---
    dict(ref="U1", entry="TPS54331", value="TPS54331DR", fp="SOIC8", x=110, y=35, block="DCDC"),
    dict(ref="L1", entry="L", value="10uH", fp="L_0805", x=125, y=25, block="DCDC"),
    dict(ref="C3", entry="C", value="22uF", fp="C_0805", x=100, y=25, block="DCDC"),
    dict(ref="C4", entry="C", value="22uF", fp="C_0805", x=135, y=25, block="DCDC"),
    dict(ref="U2", entry="TPS62203", value="TPS62203/AMS1117-3.3", fp="SOT23-5_4PIN", x=110, y=55, block="DCDC"),
    dict(ref="C5", entry="C", value="10uF", fp="C_0603", x=125, y=55, block="DCDC"),
    dict(ref="U3", entry="TPS7A02_STBY", value="TPS7A02 (standby, off BATT)", fp="SOT23", x=110, y=75, block="DCDC"),
    dict(ref="C6", entry="C", value="1uF", fp="C_0603", x=125, y=75, block="DCDC"),
    dict(ref="R4", entry="R", value="10k (FB top)", fp="R_0603", x=145, y=35, block="DCDC"),
    dict(ref="R5", entry="R", value="3.3k (FB bottom)", fp="R_0603", x=145, y=45, block="DCDC"),

    # --- Ignition Sense & Safe Shutdown ---
    dict(ref="U4", entry="TLV3201", value="TLV3201", fp="SOT23-5", x=110, y=105, block="IGN"),
    dict(ref="R1", entry="R", value="100k", fp="R_0603", x=90, y=100, block="IGN"),
    dict(ref="R2", entry="R", value="22k", fp="R_0603", x=90, y=112, block="IGN"),
    dict(ref="R3", entry="R", value="10k", fp="R_0603", x=125, y=100, block="IGN"),
    dict(ref="C7", entry="C", value="1uF", fp="C_0603", x=132, y=112, block="IGN"),
    dict(ref="U5", entry="AP2331", value="AP2331WG-7", fp="SOT23-5", x=110, y=130, block="IGN"),

    # --- Compute: SoM socket ---
    dict(ref="SOM1", entry="SOM_RK356X_SODIMM", value="Radxa CM3S (RK3566/68)", fp="SODIMM_200_SOCKET", x=210, y=90, block="SOM"),

    # --- Display Interface ---
    dict(ref="J2", entry="CONN_FPC40_DSI", value="FPC40_0.5mm", fp="FPC_40P_0.5MM", x=320, y=60, block="DISP"),
    dict(ref="U6", entry="TPS61165_BL", value="TPS61165", fp="SOT23-5", x=300, y=110, block="DISP"),
    dict(ref="L2", entry="L", value="4.7uH", fp="L_0805", x=315, y=100, block="DISP"),
    dict(ref="C8", entry="C", value="1uF", fp="C_0603", x=290, y=110, block="DISP"),

    # --- Audio Path ---
    dict(ref="U7", entry="WM8960_CODEC", value="WM8960", fp="QFN32", x=210, y=180, block="AUD"),
    dict(ref="T1", entry="AUDIO_XFMR_1_1", value="LM-1547 (L ch)", fp="XFMR_SMD6", x=250, y=170, block="AUD"),
    dict(ref="T2", entry="AUDIO_XFMR_1_1", value="LM-1547 (R ch)", fp="XFMR_SMD6", x=250, y=190, block="AUD"),
    dict(ref="J3", entry="CONN_TRS_3_5", value="AUX_OUT", fp="JACK_3.5MM", x=275, y=180, block="AUD"),
    dict(ref="J4", entry="CONN_TRS_3_5", value="MIC_IN", fp="JACK_3.5MM", x=190, y=205, block="AUD"),

    # --- FM Transmitter ---
    dict(ref="U8", entry="SI4713_FM", value="Si4713-B30-GM", fp="QFN20", x=320, y=180, block="FM"),
    dict(ref="Y1", entry="CRYSTAL", value="32.768kHz", fp="XTAL_2016", x=305, y=200, block="FM"),
    dict(ref="J5", entry="CONN_SMA_ANT", value="ANT_SMA", fp="SMA_EDGE", x=345, y=180, block="FM"),

    # --- USB & Debug ---
    dict(ref="J6", entry="CONN_USB_A", value="USB_A (mic/dongle)", fp="USB_A_TH", x=25, y=180, block="USB"),
    dict(ref="J7", entry="CONN_USB_A", value="USB_A (dongle)", fp="USB_A_TH", x=25, y=200, block="USB"),
    dict(ref="J8", entry="CONN_USB_C", value="USB_C (debug/flash)", fp="USB_C_TH", x=25, y=220, block="USB"),
    dict(ref="J9", entry="CONN_UART4", value="UART_DEBUG", fp="HDR_1X4", x=60, y=220, block="USB"),
    dict(ref="SD1", entry="CONN_MICROSD", value="microSD", fp="MICROSD_PUSH", x=60, y=180, block="USB"),
]

by_ref = {c["ref"]: c for c in components}

def pin_abs(ref, pinnum):
    c = by_ref[ref]
    sdef = symdefs[c["entry"]]
    pin = next(p for p in sdef.pins if p.number == str(pinnum))
    return (round(c["x"] + pin.position.X, 2), round(c["y"] + pin.position.Y, 2)), pin

# ---------------------------------------------------------------------------
# Nets: name -> list of (ref, pin_number)
# ---------------------------------------------------------------------------
nets = {
    "+12V_RAW":     [("J1", 1), ("F1", 1)],
    "+12V_PROT":    [("Q1", 2), ("D1", 2), ("C1", 1), ("C2", 1), ("C3", 1), ("U1", 1), ("U1", 2), ("U3", 1)],
    "+12V_FUSED":   [("F1", 2), ("Q1", 3)],
    "+12V_ACC":     [("J1", 2), ("R1", 1)],
    "GND":          [("J1", 3), ("D1", 1), ("C1", 2), ("C2", 2), ("U1", 3), ("C3", 2), ("C4", 2),
                      ("U2", 3), ("C5", 2), ("U3", 2), ("C6", 2), ("U4", 4), ("R2", 2), ("C7", 2), ("U5", 3),
                      ("SOM1", 2), ("SOM1", 3), ("SOM1", 39), ("SOM1", 40),
                      ("J2", 3), ("J2", 4), ("J2", 8), ("J2", 11), ("J2", 14), ("J2", 17), ("J2", 20), ("J2", 26), ("J2", 40),
                      ("U6", 3), ("C8", 2), ("U7", 3), ("J4", 3), ("T1", 2), ("T2", 2),
                      ("U8", 3), ("J5", 2), ("R5", 2), ("Y1", 2), ("Q1", 1), ("C3", 2),
                      ("J6", 4), ("J7", 4), ("J8", 4), ("J9", 1), ("SD1", 2)],
    "U1_SW_NODE":   [("U1", 4), ("L1", 1)],
    "+5V_OUT":      [("L1", 2), ("C4", 1), ("U2", 1), ("U2", 2), ("U5", 1), ("R4", 1)],
    "+5V_SWITCHED": [("U5", 4), ("SOM1", 1)],
    "FB_U1":        [("U1", 5), ("R4", 2), ("R5", 1)],
    "+3V3":         [("U2", 4), ("C5", 1), ("U4", 3), ("SOM1", 37), ("SOM1", 38), ("J2", 25), ("J2", 39), ("J2", 5),
                      ("U6", 1), ("C8", 1), ("U7", 1), ("U7", 2), ("U8", 1), ("U8", 2), ("J9", 4)],
    "+3V3_STBY":    [("U3", 3), ("C6", 1)],
    "IGN_SENSE_RAW":[("R1", 2), ("R2", 1), ("U4", 1)],
    "IGN_SENSE_REF":[("U4", 2)],  # 2.5V reference (bandgap/divider - simplified net, see notes)
    "GPIO_IGN_SENSE":[("U4", 5), ("R3", 1), ("SOM1", 19)],
    "IGN_DEBOUNCE": [("R3", 2), ("C7", 1)],
    "GPIO_PWR_CTRL":[("SOM1", 20), ("U5", 2)],
    "PWM_BL":       [("SOM1", 18), ("U6", 2)],
    "BL_SW":        [("U6", 4), ("L2", 1)],
    "VLED_A":       [("L2", 2), ("U6", 5), ("J2", 1), ("J2", 2)],
    "USB1_DP":      [("SOM1", 4), ("J6", 3)],
    "USB1_DM":      [("SOM1", 5), ("J6", 2)],
    "USB2_DP":      [("SOM1", 6), ("J7", 3)],
    "USB2_DM":      [("SOM1", 7), ("J7", 2)],
    "USB_OTG_DP":   [("SOM1", 8), ("J8", 3)],
    "USB_OTG_DM":   [("SOM1", 9), ("J8", 2)],
    "USB1_VBUS":    [("J6", 1)],
    "USB2_VBUS":    [("J7", 1)],
    "USB_OTG_VBUS": [("J8", 1)],
    "UART_TX":      [("SOM1", 10), ("J9", 3)],
    "UART_RX":      [("SOM1", 11), ("J9", 2)],
    "I2C0_SDA":     [("SOM1", 12), ("J2", 23), ("U8", 5)],
    "I2C0_SCL":     [("SOM1", 13), ("J2", 24), ("U8", 6)],
    "I2C1_SDA":     [("SOM1", 14), ("U7", 5)],
    "I2C1_SCL":     [("SOM1", 15), ("U7", 6)],
    "SDMMC1_D0":    [("SOM1", 16), ("SD1", 1)],
    "DSI_CLK_P":    [("SOM1", 21), ("J2", 6)],
    "DSI_CLK_N":    [("SOM1", 22), ("J2", 7)],
    "DSI_D0_P":     [("SOM1", 23), ("J2", 9)],
    "DSI_D0_N":     [("SOM1", 24), ("J2", 10)],
    "DSI_D1_P":     [("SOM1", 25), ("J2", 12)],
    "DSI_D1_N":     [("SOM1", 26), ("J2", 13)],
    "DSI_D2_P":     [("SOM1", 27), ("J2", 15)],
    "DSI_D2_N":     [("SOM1", 28), ("J2", 16)],
    "DSI_D3_P":     [("SOM1", 29), ("J2", 18)],
    "DSI_D3_N":     [("SOM1", 30), ("J2", 19)],
    "I2S_BCLK":     [("SOM1", 31), ("U7", 7)],
    "I2S_LRCLK":    [("SOM1", 32), ("U7", 8)],
    "I2S_DOUT_SOM": [("SOM1", 33), ("U7", 9)],
    "I2S_DIN_SOM":  [("SOM1", 34), ("U7", 10)],
    "TP_INT":       [("SOM1", 35), ("J2", 22)],
    "TP_RST":       [("SOM1", 36), ("J2", 21)],
    "CODEC_LOUT":   [("U7", 11), ("T1", 1), ("U8", 7)],
    "CODEC_ROUT":   [("U7", 12), ("T2", 1), ("U8", 8)],
    "AUX_L":        [("T1", 3), ("J3", 1)],
    "AUX_R":        [("T2", 3), ("J3", 2)],
    "AUX_GND_ISO":  [("T1", 4), ("T2", 4), ("J3", 3)],
    "MIC_IN":       [("U7", 4), ("J4", 1)],
    "FM_RSTB":      [("U8", 4), ("SOM1", 41)],
    "FM_XTAL":      [("U8", 10), ("Y1", 1)],
    "FM_ANT":       [("U8", 9), ("J5", 1)],
}

# ---------------------------------------------------------------------------
# Build schematic
# ---------------------------------------------------------------------------
sch = Schematic().create_new()
sch.paper.paperSize = "A2"
sch.uuid = u()

# Embed used symbol definitions into lib_symbols cache
used_entries = sorted(set(c["entry"] for c in components))
sch.libSymbols = [symdefs[e] for e in used_entries]

pin_uuid_cache = {}  # (ref,pinnum) -> uuid

# Place components
for c in components:
    ref, entry = c["ref"], c["entry"]
    sdef = symdefs[entry]
    inst = SchematicSymbol()
    inst.libraryNickname = LIB
    inst.entryName = entry
    inst.libName = f"{LIB}:{entry}"
    inst.position = Position(X=c["x"], Y=c["y"], angle=0)
    inst.unit = 1
    inst.inBom = True
    inst.onBoard = True
    inst.uuid = u()
    fp_field = f"{LIB}:{c['fp']}"
    inst.properties = [
        Property(key="Reference", value=ref, id=0,
                 position=Position(X=c["x"]+3, Y=c["y"]-6, angle=0),
                 effects=Effects(font=Font(height=1.27, width=1.27))),
        Property(key="Value", value=c["value"], id=1,
                 position=Position(X=c["x"]+3, Y=c["y"]+6, angle=0),
                 effects=Effects(font=Font(height=1.27, width=1.27))),
        Property(key="Footprint", value=fp_field, id=2,
                 position=Position(X=c["x"], Y=c["y"], angle=0),
                 effects=Effects(font=Font(height=1.27, width=1.27), hide=True)),
        Property(key="Datasheet", value="", id=3,
                 position=Position(X=c["x"], Y=c["y"], angle=0),
                 effects=Effects(font=Font(height=1.27, width=1.27), hide=True)),
    ]
    pins = {}
    for p in sdef.pins:
        pu = u()
        pins[p.number] = pu
        pin_uuid_cache[(ref, p.number)] = pu
    inst.pins = pins
    sch.schematicSymbols.append(inst)

# Block title texts
block_titles = {
    "PWR": (20, 15, "POWER INPUT & PROTECTION"),
    "DCDC": (100, 15, "DC-DC CONVERSION"),
    "IGN": (85, 90, "IGNITION SENSE / SAFE SHUTDOWN"),
    "SOM": (195, 45, "COMPUTE: RK3566/RK3568 SoM (SODIMM)"),
    "DISP": (280, 15, "DISPLAY: 10.1\" MIPI-DSI + TOUCH + BACKLIGHT"),
    "AUD": (190, 160, "AUDIO: CODEC + ISOLATION TRANSFORMER"),
    "FM": (300, 160, "FM TRANSMITTER (Si4713)"),
    "USB": (20, 165, "USB HOST / OTG / DEBUG"),
}
for key, (x, y, label) in block_titles.items():
    t = Text()
    t.text = label
    t.position = Position(X=x, Y=y, angle=0)
    t.effects = Effects(font=Font(height=2.0, width=2.0), justify=Justify(horizontally="left"))
    sch.texts.append(t)

# Global labels at every net member pin (exact-coincidence connection method)
for net_name, members in nets.items():
    for ref, pinnum in members:
        (x, y), pin = pin_abs(ref, pinnum)
        gl = GlobalLabel()
        gl.text = net_name
        gl.shape = "bidirectional"
        gl.position = Position(X=x, Y=y, angle=0)
        gl.effects = Effects(font=Font(height=1.0, width=1.0), justify=Justify(horizontally="left"))
        gl.uuid = u()
        gl.properties = [Property(key="Intersheetrefs", value="${INTERSHEET_REFS}", id=0,
                                   position=Position(X=x, Y=y, angle=0),
                                   effects=Effects(font=Font(height=1.0, width=1.0), hide=True))]
        sch.globalLabels.append(gl)

# Explicit no-connect flags for intentionally unused pins
no_connects = [("U5", 5), ("J4", 2), ("SOM1", 17)] + [("J2", n) for n in range(27, 39)]
for ref, pinnum in no_connects:
    (x, y), pin = pin_abs(ref, pinnum)
    nc = NoConnect()
    nc.position = Position(X=x, Y=y, angle=0)
    nc.uuid = u()
    sch.noConnects.append(nc)

# Sheet + symbol instances (required for a valid, ERC-clean single-sheet project)
sch.sheetInstances = [HierarchicalSheetInstance(instancePath="/", page="1")]
sch.symbolInstances = []
for c in components:
    inst = next(si for si in sch.schematicSymbols if si.properties[0].value == c["ref"])
    sch.symbolInstances.append(SymbolInstance(
        path=f"/{inst.uuid}",
        reference=c["ref"],
        unit=1,
        value=c["value"],
        footprint=f"{LIB}:{c['fp']}",
    ))

sch.filePath = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.kicad_sch"
sch.to_file()
print("wrote schematic:", len(components), "components,", len(nets), "nets,",
      sum(len(v) for v in nets.values()), "global labels")
