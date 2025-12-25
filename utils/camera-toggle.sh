#!/bin/bash
#===============================================================================
# camera-toggle.sh - Camera Toggle with LED Indicator
# For ASUS Zenbook S 13 OLED (UM5302TA)
#===============================================================================

CAMERA_LED="/sys/class/leds/platform::camera"

if lsmod | grep -q uvcvideo; then
    # Disable camera
    sudo modprobe -r uvcvideo
    
    # LED on = camera disabled (privacy mode)
    if [ -w "$CAMERA_LED/brightness" ]; then
        echo 1 | sudo tee "$CAMERA_LED/brightness" > /dev/null
    fi
    
    notify-send -u low -i camera-off "Camera" "Disabled" \
        -h string:x-canonical-private-synchronous:camera
else
    # Enable camera
    sudo modprobe uvcvideo
    
    # LED off = camera enabled
    if [ -w "$CAMERA_LED/brightness" ]; then
        echo 0 | sudo tee "$CAMERA_LED/brightness" > /dev/null
    fi
    
    notify-send -u low -i camera-on "Camera" "Enabled" \
        -h string:x-canonical-private-synchronous:camera
fi
