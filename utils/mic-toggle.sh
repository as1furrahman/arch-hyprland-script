#!/bin/bash
#===============================================================================
# mic-toggle.sh - Microphone Toggle with LED Indicator
# For ASUS Zenbook S 13 OLED (UM5302TA)
#===============================================================================

# Toggle mute
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Get mute status
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
    MUTED=true
else
    MUTED=false
fi

# Update LED indicator
if [ -w "/sys/class/leds/platform::micmute/brightness" ]; then
    if $MUTED; then
        echo 1 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
    else
        echo 0 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
    fi
fi

# Send notification
if $MUTED; then
    notify-send -u low -i microphone-sensitivity-muted "Microphone" "Muted" \
        -h string:x-canonical-private-synchronous:mic
else
    notify-send -u low -i microphone-sensitivity-high "Microphone" "Unmuted" \
        -h string:x-canonical-private-synchronous:mic
fi
