#!/usr/bin/python3

from datetime import datetime
from time import sleep
import sys
from types import SimpleNamespace as _

import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify
Notify.init("Swaybar")

class BatteryState:
    def __init__(self, threshold, label, icon):
        self.threshold = threshold
        self.label = label
        self.icon = icon

battery_states = [
    BatteryState(100, "",         ''),
    BatteryState(40,  "Low",      'battery-caution'),
    BatteryState(20,  "Very Low", 'battery-caution'),
    BatteryState(10,  "Critical", 'battery-low'),
    BatteryState(7,   "Terminal", 'battery-low'),
]
battery_states.reverse()
battery_state = len(battery_states)-1

def status():
    global battery_state

    energy_now = open('/sys/class/power_supply/BAT0/energy_now', 'r').read()
    energy_full = open('/sys/class/power_supply/BAT0/energy_full', 'r').read()
    energy_pct = 100 * float(energy_now) / float(energy_full)
    energy_state = open('/sys/class/power_supply/BAT0/status', 'r').read().lower().strip()
    energy_icon = {
        "charging": '🔌',
        "discharging": '🔋'
    }.get(energy_state, '⚡')

    bs = len(battery_states)-1
    while bs > 0 and energy_pct <= battery_states[bs-1].threshold:
        bs -= 1

    if energy_state == 'discharging' and bs < battery_state:
        Notify.Notification.new("{} Battery".format(battery_states[bs].label),
                                              f"Battery is down to {energy_pct:2.0f}%.",
                                              battery_states[bs].icon).show()

    energy_warning = ''
    if battery_states[bs].label:
        energy_warning = '**BATTERY {}**'.format(battery_states[bs].label.upper())

    battery_state = bs

    energy = "{warning} {state:>11s} {pct:2.0f}% {icon}".format(state=energy_state,
                                                                pct=energy_pct,
                                                                icon=energy_icon,
                                                                warning=energy_warning)

    time_now = datetime.now()
    time = time_now.strftime('%Y-%m-%d  %H:%M:%S')

    print("{energy}    {time}".format(energy=energy, time=time))
    sys.stdout.flush()

while True:
    status()
    sleep(1)
