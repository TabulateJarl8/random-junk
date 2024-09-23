#!/usr/bin/env bash

show_help() {
    echo "Usage: ./$(basename $0) -l <lb_path> -w <wine_prefix>"
    echo "    -h: Show this message and exit"
    echo "    -l: Lockdown Browser installer path"
    echo "    -w: Wine Prefix of where to install lockdown browser"
    exit 0
}

unset -v LB_PATH
unset -v WINE_PREFIX

while getopts l:w:h opt; do
    case $opt in
        l) LB_PATH=$OPTARG ;;
        w) WINE_PREFIX=$OPTARG ;;
        h) show_help ;;
        *)
            echo "Error in command line parsing" >&2
            exit 1
    esac
done

shift "$(( OPTIND - 1 ))"

# validate arguments
if [ -z "$LB_PATH" ]; then
    show_help
    exit 1
fi

if [ ! -f "$LB_PATH" ]; then
    echo "$LB_PATH is not a file" >&2
    exit 1
fi

if [ -z "$WINE_PREFIX" ]; then
    show_help
    exit 1
fi

if [ ! -d "$WINE_PREFIX" ]; then
    echo "$WINE_PREFIX is not a directory" >&2
    exit 1
fi

# check if wine is installed
if ! command -v wine 2>&1 >/dev/null; then
    echo "wine is not installed"
    exit 1
fi

# check if curl is installed
if ! command -v curl 2>&1 >/dev/null; then
    echo "curl is not installed"
    exit 1
fi

# check for gnutls and gnutls 32 bit if on arch
if command -v pacman 2>&1 >/dev/null; then
    if ! pacman -Qi lib32-gnutls gnutls > /dev/null; then
        echo "gnutls or lib32-gnutls are not installed. Please install them with the following command:"
        echo
        echo "    sudo pacman -Sy gnutls lib32-gnutls --needed"
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
    echo "Status code ${response}"
    exit 1
fi
chmod +x "$WINETRICKS_PATH"

# export wine variables
export WINEPREFIX=$WINE_PREFIX
export WINEARCH=win32

# install lockdown browser
echo "Please follow the lockdown browser installation wizard"
wine $LB_PATH

echo "Installing required libraries..."
$WINETRICKS_PATH msftedit allfonts vcrun2015 dxvk

echo
echo "Success! Lockdown Browser should be available in your desktop menu."
echo -e "\e[31mNOTICE:\e[0m"
echo "Run the follow command, then navigate to 'Graphics' and check 'Emulate a virtual desktop'. Then, input your screen resolution:"
echo "WINEPREFIX=\"$WINE_PREFIX\" winecfg"

# make sure the temporary directory gets removed on script exit
trap "exit 1" HUP INT PIPE QUIT TERM
trap 'rm -rf "$TEMP_WORK_DIR"' EXIT
