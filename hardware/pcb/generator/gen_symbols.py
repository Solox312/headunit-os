"""
Generates headunit_carrier.kicad_sym: a self-contained project-local symbol
library. All symbols are authored here (rather than depending on the user's
installed KiCad stock libraries) so the project opens identically on any
machine with KiCad 6/7/8 installed.
"""
from kiutils.symbol import SymbolLib, Symbol, SymbolPin
from kiutils.items.syitems import SyRect
from kiutils.items.common import Position, Effects, Font, Property

LIB = "headunit_carrier"

def prop(name, value, pid, x, y, hide=False, size=1.27):
    return Property(key=name, value=value, id=pid, position=Position(X=x, Y=y, angle=0),
                     effects=Effects(font=Font(height=size, width=size), hide=hide))

def make_symbol(entry, ref_prefix, value, pins, w=None, h=None, footprint="", datasheet=""):
    """
    pins: list of dicts: {num, name, side ('L'/'R'/'T'/'B'), idx, etype}
    Body is an auto-sized rectangle; pins are placed on a 2.54mm grid on the
    given side, in the given index order (0-based from one end).
    """
    left = [p for p in pins if p['side'] == 'L']
    right = [p for p in pins if p['side'] == 'R']
    top = [p for p in pins if p['side'] == 'T']
    bottom = [p for p in pins if p['side'] == 'B']

    grid = 2.54
    n_lr = max(len(left), len(right), 1)
    n_tb = max(len(top), len(bottom), 1)

    if h is None:
        h = grid * (n_lr + 1)
    if w is None:
        w = grid * (n_tb + 1.5) if (top or bottom) else grid * 8

    half_w = w / 2
    half_h = h / 2

    sym = Symbol.create_new(f"{LIB}:{entry}", ref_prefix, value, footprint=footprint, datasheet=datasheet)
    sym.pinNames = True
    sym.pinNamesOffset = 0.508
    sym.graphicItems = [
        SyRect(start=Position(X=-half_w, Y=half_h), end=Position(X=half_w, Y=-half_h))
    ]

    symbol_pins = []

    def place(plist, side):
        count = len(plist)
        if count == 0:
            return
        for i, p in enumerate(plist):
            if side == 'L':
                y = half_h - grid * (i + 1)
                x = -half_w - 2.54
                angle = 0  # pin points right, into body
            elif side == 'R':
                y = half_h - grid * (i + 1)
                x = half_w + 2.54
                angle = 180
            elif side == 'T':
                x = -half_w + grid * (i + 1) if (i+1)*grid < w else -half_w + w/2
                x = -half_w + grid * (i + 1)
                y = half_h + 2.54
                angle = 270
            else:  # bottom
                x = -half_w + grid * (i + 1)
                y = -half_h - 2.54
                angle = 90
            symbol_pins.append(SymbolPin(
                electricalType=p.get('etype', 'passive'),
                graphicalStyle='line',
                position=Position(X=round(x,2), Y=round(y,2), angle=angle),
                length=2.54,
                name=p['name'],
                number=str(p['num']),
            ))

    place(left, 'L')
    place(right, 'R')
    place(top, 'T')
    place(bottom, 'B')

    sym.pins = symbol_pins
    return sym


def two_pin_symbol(entry, ref_prefix, value, pin1_name="1", pin2_name="2", etype="passive", footprint="", datasheet=""):
    """Small vertical 2-pin symbol (R/C/L/D/Fuse style), pin 1 top, pin 2 bottom."""
    sym = Symbol.create_new(f"{LIB}:{entry}", ref_prefix, value, footprint=footprint, datasheet=datasheet)
    sym.pinNames = True
    sym.graphicItems = [
        SyRect(start=Position(X=-1.27, Y=2.54), end=Position(X=1.27, Y=-2.54))
    ]
    sym.pins = [
        SymbolPin(electricalType=etype, graphicalStyle='line',
                  position=Position(X=0, Y=5.08, angle=270), length=2.54,
                  name=pin1_name, number="1"),
        SymbolPin(electricalType=etype, graphicalStyle='line',
                  position=Position(X=0, Y=-5.08, angle=90), length=2.54,
                  name=pin2_name, number="2"),
    ]
    return sym


def build():
    lib = SymbolLib()
    lib.generator = "headunit_gen"
    syms = []

    # ---- Generic passives ----
    syms.append(two_pin_symbol("R", "R", "R", "1", "2", etype="passive"))
    syms.append(two_pin_symbol("C", "C", "C", "1", "2", etype="passive"))
    syms.append(two_pin_symbol("C_POL", "C", "C_POL", "+", "-", etype="passive"))
    syms.append(two_pin_symbol("L", "L", "L", "1", "2", etype="passive"))
    syms.append(two_pin_symbol("D_TVS", "D", "D_TVS", "K", "A", etype="passive"))
    syms.append(two_pin_symbol("FUSE", "F", "FUSE", "1", "2", etype="passive"))
    syms.append(two_pin_symbol("CRYSTAL", "Y", "XTAL", "1", "2", etype="passive"))

    # PMOS (3-pin: G, D, S)
    syms.append(make_symbol("Q_PMOS", "Q", "Q_PMOS", [
        {"num": 1, "name": "G", "side": "L", "etype": "input"},
        {"num": 2, "name": "D", "side": "R", "etype": "passive"},
        {"num": 3, "name": "S", "side": "R", "etype": "passive"},
    ]))

    # ---- Generic connectors ----
    def conn(entry, n, names=None):
        names = names or [str(i+1) for i in range(n)]
        pins = [{"num": i+1, "name": names[i], "side": "L", "etype": "passive"} for i in range(n)]
        syms.append(make_symbol(entry, "J", entry, pins))

    conn("CONN_3W", 3, ["BATT_12V", "ACC_12V", "GND"])
    conn("CONN_USB_A", 4, ["VBUS", "D-", "D+", "GND"])
    conn("CONN_USB_C", 4, ["VBUS", "D-", "D+", "GND"])
    conn("CONN_SMA_ANT", 2, ["ANT", "GND"])
    conn("CONN_UART4", 4, ["GND", "TX", "RX", "3V3"])
    conn("CONN_MICROSD", 2, ["SD_IO", "GND"])  # simplified
    conn("CONN_TRS_3_5", 3, ["TIP_L", "RING_R", "SLEEVE_GND"])

    # FPC 40-pin display connector (key nets only, remainder tied NC for clarity)
    fpc_pins = [
        "VLED_A", "VLED_A", "GND", "GND", "BL_EN",
        "DSI_CLK_P", "DSI_CLK_N", "GND", "DSI_D0_P", "DSI_D0_N",
        "GND", "DSI_D1_P", "DSI_D1_N", "GND", "DSI_D2_P",
        "DSI_D2_N", "GND", "DSI_D3_P", "DSI_D3_N", "GND",
        "TP_RST", "TP_INT", "TP_SDA", "TP_SCL", "TP_3V3",
        "TP_GND", "NC", "NC", "NC", "NC",
        "NC", "NC", "NC", "NC", "NC",
        "NC", "NC", "NC", "3V3_PANEL", "GND",
    ]
    pins = [{"num": i+1, "name": fpc_pins[i], "side": "L", "etype": "passive"} for i in range(40)]
    syms.append(make_symbol("CONN_FPC40_DSI", "J", "CONN_FPC40_DSI", pins, h=2.54*22))

    # ---- SoM socket (SODIMM, key signals only - representative subset) ----
    som_pins_l = [
        (1, "VIN_5V", "power_in"), (2, "GND", "power_in"), (3, "GND", "power_in"),
        (4, "USB1_DP", "bidirectional"), (5, "USB1_DM", "bidirectional"),
        (6, "USB2_DP", "bidirectional"), (7, "USB2_DM", "bidirectional"),
        (8, "USB_OTG_DP", "bidirectional"), (9, "USB_OTG_DM", "bidirectional"),
        (10, "UART2_TX", "output"), (11, "UART2_RX", "input"),
        (12, "I2C0_SDA", "bidirectional"), (13, "I2C0_SCL", "bidirectional"),
        (14, "I2C1_SDA", "bidirectional"), (15, "I2C1_SCL", "bidirectional"),
        (16, "SDMMC1_D0", "bidirectional"), (17, "SDMMC1_CLK", "output"),
        (18, "PWM_BL", "output"), (19, "GPIO_IGN_SENSE", "input"),
        (20, "GPIO_PWR_CTRL", "output"),
    ]
    som_pins_r = [
        (21, "DSI_CLK_P", "output"), (22, "DSI_CLK_N", "output"),
        (23, "DSI_D0_P", "output"), (24, "DSI_D0_N", "output"),
        (25, "DSI_D1_P", "output"), (26, "DSI_D1_N", "output"),
        (27, "DSI_D2_P", "output"), (28, "DSI_D2_N", "output"),
        (29, "DSI_D3_P", "output"), (30, "DSI_D3_N", "output"),
        (31, "I2S_BCLK", "output"), (32, "I2S_LRCLK", "output"),
        (33, "I2S_DOUT", "output"), (34, "I2S_DIN", "input"),
        (35, "TP_INT", "input"), (36, "TP_RST", "output"),
        (37, "3V3", "power_in"), (38, "3V3", "power_in"),
        (39, "GND", "power_in"), (40, "GND", "power_in"),
        (41, "GPIO_FM_RST", "output"),
    ]
    pins = [{"num": n, "name": nm, "side": "L", "etype": et} for n, nm, et in som_pins_l]
    pins += [{"num": n, "name": nm, "side": "R", "etype": et} for n, nm, et in som_pins_r]
    syms.append(make_symbol("SOM_RK356X_SODIMM", "SOM", "RK3566/RK3568_SOM", pins, h=2.54*23,
                             datasheet="https://dl.radxa.com/cm3/docs/radxa_cm3_datasheet.pdf"))

    # ---- Regulators / analog ICs ----
    syms.append(make_symbol("TPS54331", "U", "TPS54331", [
        {"num": 1, "name": "VIN", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "EN", "side": "L", "etype": "input"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "SW", "side": "R", "etype": "output"},
        {"num": 5, "name": "FB", "side": "R", "etype": "input"},
    ], datasheet="https://www.ti.com/lit/ds/symlink/tps54331.pdf"))

    syms.append(make_symbol("TPS62203", "U", "TPS62203", [
        {"num": 1, "name": "VIN", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "EN", "side": "L", "etype": "input"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "VOUT", "side": "R", "etype": "output"},
    ]))

    syms.append(make_symbol("TPS7A02_STBY", "U", "TPS7A02", [
        {"num": 1, "name": "VIN", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 3, "name": "VOUT", "side": "R", "etype": "output"},
    ]))

    syms.append(make_symbol("TLV3201", "U", "TLV3201", [
        {"num": 1, "name": "IN+", "side": "L", "etype": "input"},
        {"num": 2, "name": "IN-", "side": "L", "etype": "input"},
        {"num": 3, "name": "VCC", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 5, "name": "OUT", "side": "R", "etype": "output"},
    ]))

    syms.append(make_symbol("AP2331", "U", "AP2331", [
        {"num": 1, "name": "IN", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "ON", "side": "L", "etype": "input"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "OUT", "side": "R", "etype": "output"},
        {"num": 5, "name": "FLAG", "side": "R", "etype": "output"},
    ]))

    syms.append(make_symbol("TPS61165_BL", "U", "TPS61165", [
        {"num": 1, "name": "VIN", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "PWM", "side": "L", "etype": "input"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "SW", "side": "R", "etype": "output"},
        {"num": 5, "name": "LED+", "side": "R", "etype": "output"},
    ]))

    # Audio codec
    syms.append(make_symbol("WM8960_CODEC", "U", "WM8960", [
        {"num": 1, "name": "AVDD", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "DVDD", "side": "L", "etype": "power_in"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "MIC_IN", "side": "L", "etype": "input"},
        {"num": 5, "name": "I2C_SDA", "side": "L", "etype": "bidirectional"},
        {"num": 6, "name": "I2C_SCL", "side": "L", "etype": "input"},
        {"num": 7, "name": "I2S_BCLK", "side": "R", "etype": "input"},
        {"num": 8, "name": "I2S_LRCLK", "side": "R", "etype": "input"},
        {"num": 9, "name": "I2S_DIN", "side": "R", "etype": "output"},
        {"num": 10, "name": "I2S_DOUT", "side": "R", "etype": "input"},
        {"num": 11, "name": "LOUT", "side": "R", "etype": "output"},
        {"num": 12, "name": "ROUT", "side": "R", "etype": "output"},
    ]))

    # Audio isolation transformer (dual, 4 pins per side simplified to 1 stereo pair shown; second instance = other channel)
    syms.append(make_symbol("AUDIO_XFMR_1_1", "T", "AUDIO_XFMR", [
        {"num": 1, "name": "PRI_IN", "side": "L", "etype": "passive"},
        {"num": 2, "name": "PRI_GND", "side": "L", "etype": "passive"},
        {"num": 3, "name": "SEC_OUT", "side": "R", "etype": "passive"},
        {"num": 4, "name": "SEC_GND", "side": "R", "etype": "passive"},
    ]))

    # Si4713 FM transmitter
    syms.append(make_symbol("SI4713_FM", "U", "SI4713-B30-GM", [
        {"num": 1, "name": "VIO", "side": "L", "etype": "power_in"},
        {"num": 2, "name": "VA", "side": "L", "etype": "power_in"},
        {"num": 3, "name": "GND", "side": "L", "etype": "power_in"},
        {"num": 4, "name": "RSTB", "side": "L", "etype": "input"},
        {"num": 5, "name": "SDA", "side": "L", "etype": "bidirectional"},
        {"num": 6, "name": "SCL", "side": "L", "etype": "input"},
        {"num": 7, "name": "LIN", "side": "R", "etype": "input"},
        {"num": 8, "name": "RIN", "side": "R", "etype": "input"},
        {"num": 9, "name": "RFO", "side": "R", "etype": "output"},
        {"num": 10, "name": "XTAL1", "side": "R", "etype": "passive"},
    ], datasheet="https://www.silabs.com/documents/public/data-sheets/Si4712-13-B30.pdf"))

    lib.symbols = syms
    lib.filePath = "/sessions/quirky-sleepy-goodall/mnt/outputs/kicad_gen/headunit_carrier.kicad_sym"
    lib.to_file()
    print("wrote", len(syms), "symbols")

if __name__ == "__main__":
    build()
