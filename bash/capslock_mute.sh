#!/usr/bin/env bash

## Program to remap capslock light on the Framework 16 to act as a mute indicator
## Tested on Arch/Plasma/Wayland/Pipewire
## Capslock was remapped to shift using QMK so that it can't be toggled

# global capslock state variable
capslock_state=$(cat /sys/class/leds/input26::capslock/brightness)

cleanup() {
    rv=$?
    echo 0 | sudo /usr/bin/tee /sys/class/leds/input26::capslock/brightness
    exit $rv
}

get_mute_status() {
    pactl list sinks | awk -v sink_name="$(pactl get-default-sink)" '
        BEGIN { found_sink=0 }
        /Sink #/ { found_sink=0 }
        $1 == "Name:" && $2 == sink_name { found_sink=1 }
        found_sink && $1 == "Mute:" { print $2; exit }
    '
}

update_capslock_led() {
    local muted="$1"
    local force_update="$3"

    # these tee commands only with with a special /etc/sudoers entry allowing for NOPASSWD
    if [[ "$muted" == "no" && ("$capslock_state" == "1" || "$force_update" == "1") ]]; then
        echo 0 | sudo /usr/bin/tee /sys/class/leds/input26::capslock/brightness &>/dev/null
       capslock_state=0
    elif [[ "$muted" == "yes" && ("$capslock_state" == "0" || "$force_update" == "1") ]]; then
        echo 1 | sudo /usr/bin/tee /sys/class/leds/input26::capslock/brightness &>/dev/null
        capslock_state=1
    fi
}

main() {
    muted=$(get_mute_status)

    # perform initial check
    update_capslock_led "$muted" "$capslock_state" "1"

    # subscribe to pulseaudio events and monitor for sink changes
    pactl subscribe | grep --line-buffered "sink" | while read -r UNUSED_LINE; do
        # get updates mute status
        muted=$(get_mute_status)
        # check and update the caps lock LED state
        update_capslock_led "$muted" "$capslock_state"
    done
}

trap "cleanup" EXIT
main
