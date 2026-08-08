#!/usr/bin/env python3
"""
Automotive Safe Shutdown Listener Daemon for HeadUnit OS
Listens on GPIO pin 26 for ignition power loss signal from Car Power HAT.
Debounces voltage dips for 3 continuous seconds before executing graceful Linux shutdown.
"""

import os
import sys
import time

try:
    from gpiozero import Button
except ImportError:
    Button = None  # type: ignore

# The BCM GPIO pin your specific power HAT uses to signal the Pi
# (Check your HAT's manual - 26 is a common default)
IGNITION_PIN = 26 

def trigger_shutdown():
    print("Ignition loss detected (3s hold). Halting system safely...")
    os.system("sudo shutdown -h now")

if __name__ == '__main__':
    if Button is None:
        print("Error: 'gpiozero' module is not installed on this environment.")
        print("To install on Raspberry Pi OS run: sudo apt install python3-gpiozero")
        sys.exit(1)

    # Initialize the GPIO pin. 
    # hold_time=3 requires the car to be off for 3 continuous seconds 
    # before triggering (prevents accidental shutdowns during engine cranking).
    ignition_signal = Button(IGNITION_PIN, pull_up=True, hold_time=3)
    
    # Link the hold event directly to the shutdown function
    ignition_signal.when_held = trigger_shutdown
    
    print(f"Monitoring GPIO {IGNITION_PIN} for ignition status...")
    
    # Keep the background daemon alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting ignition monitor.")
