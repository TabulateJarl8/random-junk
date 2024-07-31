#!/usr/bin/env bash

## Program to remap capslock light on the Framework 16 to act as a mute indicator
## Tested on Arch/Plasma/Wayland/Pipewire
## Capslock was remapped to shift using QMK so that it can't be toggled

# Initialize global capslock state variable by reading the current brightness of the capslock LED
capslock_state=$(cat /sys/class/leds/input16::capslock/brightness)

# Function to clean up and reset the capslock LED before exiting the script
cleanup() {
    rv=$? # Capture the exit status of the last command
    echo 0 | sudo /usr/bin/tee /sys/class/leds/input16::capslock/brightness # Turn off the capslock LED
    exit $rv # Exit with the original status code
}

# Function to get the current mute status of the default audio sink
get_mute_status() {
    pactl list sinks | awk -v sink_name="$(pactl get-default-sink)" '
        BEGIN { found_sink=0 }
        /Sink #/ { found_sink=0 }
        $1 == "Name:" && $2 == sink_name { found_sink=1 }
        found_sink && $1 == "Mute:" { print $2; exit }
    '
}

# Function to update the capslock LED based on the mute status
update_capslock_led() {
    local muted="$1" # Mute status (yes/no)
    local force_update="$3" # Flag to force LED update

    # Use sudo tee to change the brightness of the capslock LED, requires NOPASSWD entry in /etc/sudoers
    if [[ "$muted" == "yes" && ("$capslock_state" == "1" || "$force_update" == "1") ]]; then
        echo 0 | sudo /usr/bin/tee /sys/class/leds/input16::capslock/brightness &>/dev/null # Turn off LED if muted
        capslock_state=0 # Update capslock state
    elif [[ "$muted" == "no" && ("$capslock_state" == "0" || "$force_update" == "1") ]]; then
        echo 1 | sudo /usr/bin/tee /sys/class/leds/input16::capslock/brightness &>/dev/null # Turn on LED if unmuted
        capslock_state=1 # Update capslock state
    fi
}

# Main function to monitor mute status changes and update the capslock LED
main() {
    muted=$(get_mute_status) # Get the initial mute status

    # Perform initial LED state check and update
    update_capslock_led "$muted" "$capslock_state" "1"

    # subscribe to pulseaudio events and monitor for sink changes
    pactl subscribe | grep --line-buffered "sink" | while read -r UNUSED_LINE; do
        # get updated mute status
        muted=$(get_mute_status)
        # check and update the caps lock LED state
        update_capslock_led "$muted" "$capslock_state"
    done
}

# Set up trap to ensure cleanup function runs on script exit
trap "cleanup" EXIT

main
