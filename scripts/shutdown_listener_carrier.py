#!/usr/bin/env python3
"""
Automotive Safe Shutdown Listener Daemon for Carrier Board (Rev B)
Listens on a Rockchip GPIO for VBUS power loss signal.
Debounces voltage dips for 0.1 continuous seconds before executing graceful Linux shutdown.
"""

import os
import sys
import time

try:
    import gpiod # type: ignore
except ImportError:
    gpiod = None  # type: ignore

# TODO: Confirm actual SoC-side GPIO from Radxa CM3S pinout
CHIP_NAME = 'gpiochip0'
LINE_OFFSET = 3 # Placeholder offset

HOLD_TIME = 0.1

def trigger_shutdown():
    print(f"Power loss detected ({HOLD_TIME}s hold). Halting system safely...")
    os.system("sudo shutdown -h now")

if __name__ == '__main__':
    if gpiod is None:
        print("Error: 'gpiod' module is not installed.")
        print("Install via: sudo apt install python3-libgpiod")
        sys.exit(1)

    try:
        chip = gpiod.Chip(CHIP_NAME)
        line = chip.get_line(LINE_OFFSET)
        
        # Request line for input with both edge detection
        line.request(consumer="shutdown_listener_carrier", type=gpiod.LINE_REQ_DIR_IN, flags=gpiod.LINE_REQ_FLAG_ACTIVE_LOW)
    except Exception as e:
        print(f"Failed to initialize GPIO: {e}")
        sys.exit(1)

    print(f"Monitoring {CHIP_NAME} line {LINE_OFFSET} for power status...")
    
    try:
        power_loss_start = None
        while True:
            # Simple polling/debouncing logic to replace gpiozero's hold_time
            val = line.get_value()
            if val == 1: # Assuming active low means 1 when power is lost
                if power_loss_start is None:
                    power_loss_start = time.time()
                elif (time.time() - power_loss_start) >= HOLD_TIME:
                    trigger_shutdown()
                    break
            else:
                power_loss_start = None
                
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\nExiting power monitor.")
    finally:
        line.release()
        chip.close()
