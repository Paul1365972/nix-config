#!/bin/bash
#
# Bluetooth Keyboard Setup for Darkness
#

set -e

KEYBOARD_MAC="FF:FF:11:AE:C0:AC"

echo "Pairing Bluetooth Keyboard ($KEYBOARD_MAC)..."

# Pair and connect
bluetoothctl power on
bluetoothctl agent on
bluetoothctl default-agent
bluetoothctl pair "$KEYBOARD_MAC"
bluetoothctl trust "$KEYBOARD_MAC"
bluetoothctl connect "$KEYBOARD_MAC" || true

echo ""
echo "Done! Keyboard connected."
echo ""
echo "Manual pairing: bluetoothctl -> 'power on', 'agent on', 'scan on', 'scan off', 'pair $KEYBOARD_MAC', 'trust $KEYBOARD_MAC'"
echo ""
