#!/usr/bin/env bash

#######################################################################
# DISCLAIMER: I have no idea if this is detectable by the educational
# institution which is requiring the use of lockdown browser, so weigh
# the pros and cons of just using Windows on a burner laptop/dual boot,
# as they may try to claim that you are cheating by using it this way
#######################################################################

function show_help() {
    echo "Usage: ./$(basename $0) -l <lb_path> -w <wine_prefix>"
    echo "    -h: Show this message and exit"
    echo "    -l: Lockdown Browser installer path"
    echo "    -w: Wine Prefix of where to install lockdown browser"
    echo "    -m: either 32 or 64 for 32-bit or 64-bit mode. Default: 64-bit. You more than likely don't need to touch this flag"
    exit 0
}

function is_valid_dimension() {
    [[ $1 =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

function determine_scaled_dpi() {
    local desired_scale=1.0
    local dpi
    local scale
    local text_scale

    # 1. try Xresources DPI
    if command -v xrdb >/dev/null 2>&1; then
        dpi=$(xrdb -query | awk '/Xft.dpi:/ {print $2}')
        if [ -n "$dpi" ]; then
            desired_scale=$(awk "BEGIN {printf \"%.2f\", $dpi / 96}")
        fi
    fi

    # 2. try xrandr
    if [ "$desired_scale" = "1.0" ]; then
        if command -v xrandr >/dev/null 2>&1; then
            scale=$(xrandr --verbose | awk '/ connected /,0' | grep -oP 'Scale \K[0-9\.]+')
            if [ -n "$scale" ]; then
                desired_scale="$scale"
            fi
        fi
    fi

    # Try KDE screen doctor
    if [ "$desired_scale" = "1.0" ]; then
        if command -v kscreen-doctor >/dev/null 2>&1; then
            scale=$(kscreen-doctor -o | grep Scale | cut -d' ' -f2)
            if [ -n "$scale" ]; then
                desired_scale="$scale"
            fi
        fi
    fi

    # Try GNOME settings
    if [ "$desired_scale" = "1.0" ]; then
        if command -v gsettings >/dev/null 2>&1; then
            scale=$(gsettings get org.gnome.desktop.interface scaling-factor 2>/dev/null | tr -d "'")
            if [ "$scale" -gt 0 ] 2>/dev/null; then
                desired_scale="$scale"
            fi

            text_scale=$(gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null)
            awk "BEGIN {if ($text_scale > $desired_scale) print \"\"$text_scale\"\"}" | grep -q .
            if [ $? -eq 0 ]; then
                desired_scale="$text_scale"
            fi
        fi
    fi

    local new_dpi
    # +0.5 ensures proper rounding in awk
    new_dpi=$(awk "BEGIN {printf \"%d\", (96 * $desired_scale) + 0.5}")

    printf "0x%x" "$new_dpi"
}

CYAN="\e[36m"
RED="\e[31m"
GREEN="\e[32m"
RESET="\e[0m"

# support NO_COLOR
if [ ! -z ${NO_COLOR+x} ]; then
    # NO_COLOR is set
    CYAN=""
    RED=""
    GREEN=""
    RESET=""
fi

unset -v LB_PATH
unset -v WINE_PREFIX
WINEARCH=win64

while getopts l:w:m:h opt; do
    case $opt in
    l) LB_PATH=$OPTARG ;;
    w) WINE_PREFIX=$OPTARG ;;
    m)
        if [[ "$OPTARG" == "32" ]]; then
            WINEARCH="win32"
        elif [[ "$OPTARG" == "64" ]]; then
            WINEARCH="win64"
        else
            echo "Invalid value for -m. Please use 32 or 64."
            exit 1
        fi
        ;;
    h) show_help ;;
    *)
        echo -e "${RED}Error in command line parsing${RESET}" >&2
        exit 1
        ;;
    esac
done

shift "$((OPTIND - 1))"

# validate arguments
if [ -z "$LB_PATH" ]; then
    show_help
    exit 1
fi

if [ ! -f "$LB_PATH" ]; then
    echo -e "${RED}ERROR:${RESET} $LB_PATH is not a file" >&2
    exit 1
fi

if [ -z "$WINE_PREFIX" ]; then
    show_help
    exit 1
fi

if [ ! -d "$WINE_PREFIX" ]; then
    echo -e "${RED}ERROR:${RESET} $WINE_PREFIX is not a directory" >&2
    exit 1
fi

# check if wine is installed
if ! command -v wine 2>&1 >/dev/null; then
    echo -e "${RED}ERROR:${RESET} wine is not installed"
    exit 1
fi

# check if curl is installed
if ! command -v curl 2>&1 >/dev/null; then
    echo -e "${RED}ERROR:${RESET} curl is not installed"
    exit 1
fi

# check if cabextract is installed
if ! command -v cabextract 2>&1 >/dev/null; then
    echo -e "${RED}ERROR:${RESET} cabextract is not installed"
    exit 1
fi

# check for gnutls and gnutls 32 bit if on arch
if command -v pacman 2>&1 >/dev/null; then
    if ! pacman -Qi lib32-gnutls gnutls >/dev/null; then
        echo -e "${RED}ERROR:${RESET} gnutls or lib32-gnutls are not installed. Please install them with the following command:"
        echo
        echo -e "    ${CYAN}sudo pacman -Sy gnutls lib32-gnutls --needed${RESET}"
        exit 1
    fi
else
    # not using arch
    echo "Please ensure that gnutls and lib32-gnutls are installed for Lockdown Browser to function."
    read -p "Are these libraries installed? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# resolve full path of wine prefix and lockdown browser installer path
WINE_PREFIX="$(realpath $WINE_PREFIX)"
LB_PATH="$(realpath $LB_PATH)"

# set up winetricks temporary directory
TEMP_WORK_DIR=$(mktemp -d)
WINETRICKS_PATH="$TEMP_WORK_DIR/winetricks"

# download latest version of winetricks
response=$(curl --write-out '%{http_code}' -L --silent -o "$WINETRICKS_PATH" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks")
if [[ "$response" -ne 200 ]]; then
    echo -e "${RED}ERROR:${RESET} Status code ${response}"
    exit 1
fi
chmod +x "$WINETRICKS_PATH"

# export wine variables
export WINEPREFIX=$WINE_PREFIX
export WINEARCH=$WINEARCH

# install lockdown browser
echo -e "${CYAN}Please follow the lockdown browser installation wizard${RESET}"
wine $LB_PATH

echo -e "${CYAN}Installing required libraries...${RESET}"
$WINETRICKS_PATH msftedit allfonts vcrun2015 dxvk

echo -e "${CYAN}Enabling wine virtual desktop...${RESET}"
if ! command -v xrandr 2>&1 >/dev/null; then
    echo -e "${RED}ERROR:${RESET} Command xrandr not found. Please manually input screen resolution"

    # Prompt for screen width
    while true; do
        read -p "Enter screen width: " width
        if is_valid_dimension "$width"; then
            break
        else
            echo -e "${RED}ERROR:${RESET} Invalid width. Please enter a positive integer."
        fi
    done

    # Prompt for screen height
    while true; do
        read -p "Enter screen height: " height
        if is_valid_dimension "$height"; then
            break
        else
            echo -e "${RED}ERROR:${RESET} Invalid height. Please enter a positive integer."
        fi
    done

    resolution="${width}x${height}"
else
    resolution=$(xrandr --current | grep '*' | uniq | awk '{print $1}')
fi

$WINETRICKS_PATH vd=$resolution

echo -e "${CYAN}Attempting to set virtual desktop DPI to match scaling factor...${RESET}"
dpi_hex=$(determine_scaled_dpi)
echo -e "${CYAN}Detected a DPI of $dpi_hex...${RESET}"
wine reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d ${dpi_hex} /f

echo
echo -e "${GREEN}Success! ${CYAN}Lockdown Browser should be available in your desktop menu.${RESET}"

# make sure the temporary directory gets removed on script exit
trap "exit 1" HUP INT PIPE QUIT TERM
trap 'rm -rf "$TEMP_WORK_DIR"' EXIT
