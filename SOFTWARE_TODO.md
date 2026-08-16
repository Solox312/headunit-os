# Software TODO — Carrier Board Rev B (USB-C PD power revision)

Tracked from the Rev B hardware revision (2026-08-14): power input changed from a 3-pin
automotive harness to USB-C Power Delivery, VBUS-loss replaces ACC-line ignition sensing.
See `docs/pcb_carrier_board_design.md` §2.3/§3 and `docs/pcb_carrier_board_bom.xlsx` for the
hardware side. Nothing in this list has been implemented yet — `scripts/shutdown_listener.py`
is unchanged and still Raspberry-Pi-specific.

## Safe-shutdown daemon

- [x] **(Critical) Shorten the shutdown hold-off for the carrier board.** `shutdown_listener.py`
      currently uses `gpiozero.Button(..., hold_time=3)` — a 3-second continuous-signal
      requirement before calling `shutdown -h now`, tuned to ride out engine-cranking voltage
      sag on the RPi/HAT track. On the carrier board, the only energy reserve after USB-C VBUS
      disappears is the bulk cap (bumped to 470µF this revision) — back-of-envelope holdup at
      ~1A load is on the order of milliseconds, not seconds. **If the 3s hold-off carries over
      unchanged, the board will lose power mid-countdown on a real unplug, before
      `shutdown -h now` ever runs** — the safe-shutdown feature wouldn't actually trigger.
      The carrier-board version needs a much shorter hold-off (sub-second range), since the
      failure mode it's guarding against is a brief USB-C connector bounce, not multi-second
      engine-cranking sag — that's already handled by the hardware RC debounce
      (R3 10k / C7 10µF, ~100ms-class).
- [x] Write a carrier-board-specific version of the shutdown daemon. The current script is
      Raspberry-Pi-only: `gpiozero`, BCM pin numbering, hardcoded `IGNITION_PIN = 26`. The
      RK3566/RK3568 SoM needs a different GPIO access method (e.g. `libgpiod`/`gpiod` Python
      bindings) and a different pin identifier — Rockchip GPIOs are addressed by
      bank/port/pin (e.g. `GPIO0_A3`), not BCM numbers.
- [ ] Confirm the actual SoC-side GPIO for `GPIO_PWR_SENSE` (schematic net, SOM1 pin 19) once
      the real Radxa CM3S pinout/datasheet is in hand — not guessed here, since it depends on
      the specific SoM's pin mapping.
- [ ] `car-shutdown.service` hardcodes `ExecStart=/usr/bin/python3 /home/pi/rpi_headunit/scripts/shutdown_listener.py`
      — needs a carrier-board-appropriate unit (different path/user, since it won't run under
      Raspberry Pi OS's `pi` user).
- [ ] Once real hardware exists: bench-verify the actual VBUS-loss-to-brownout holdup time and
      set the software hold-off to match with margin — the 470µF bump in this revision is a
      starting estimate, not a measured value (see the BOM/design-doc notes).
- [x] Consider renaming ignition-specific language in the new script/logs ("ignition loss",
      `IGNITION_PIN`) to power-loss language, since there's no ignition switch in this signal
      path anymore — purely cosmetic/clarity, not functional. Leave the existing RPi-track
      script's ignition language alone; it's still accurate for that build.

## Reference

- Hardware side of this revision: `docs/pcb_carrier_board_design.md` §2.1/§2.3, §3 (open items)
- BOM: `docs/pcb_carrier_board_bom.xlsx`
- Full handoff record: `docs/headunit_os_handoff.docx` §4.4, §5

---

## Radxa CM3S (Rockchip RK3566) Production Board Integration

Tracked for the Radxa CM3S Compute Module production carrier boards:

- [ ] **Hostapd 5 GHz Wi-Fi Lockdown (`/etc/hostapd/hostapd.conf`)**:
      Configure the AP6256 / CYW43455 Wi-Fi driver strictly in 5.0 GHz mode (`hw_mode=a`, `channel=36`, `ieee80211ac=1`). Prevent 2.4 GHz co-channel congestion and packet collision between high-bandwidth Wireless Android Auto video/audio and concurrent Bluetooth A2DP speaker streaming.
- [ ] **PipeWire / WirePlumber Audio Sink Auto-Routing**:
      Verify WirePlumber policy on Rockchip Linux so that upon Bluetooth speaker connection, default audio sink automatically switches to `bluez_output.*.a2dp-sink` without interrupting Android Auto projection.
- [ ] **KT0803K Device Tree & GPIO Power Enable**:
      Confirm the carrier board GPIO mapped to the KT0803K transmitter enable/reset line (`PWR_EN` / `RST_N`). Ensure the Device Tree Overlay (`.dts`) configures this pin as active-high output on boot prior to I2C register configuration.
- [ ] **Multi-Bus I2C Hardware Probe Verification**:
      Bench-verify dynamic scanning across all RK3566 I2C buses (`/dev/i2c-2`, `/dev/i2c-3`, `/dev/i2c-4`) on production PCB hardware and validate address `0x3E` ACK.
- [ ] **U.FL Dual-Band Antenna Routing**:
      Ensure production harness connects external dual-band antennas to the CM3S U.FL connector for robust in-dash Wi-Fi Direct and Bluetooth 5.0 range.

