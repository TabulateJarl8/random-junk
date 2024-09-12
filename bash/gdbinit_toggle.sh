#!/usr/bin/env bash

# Toggle .gdbinit on and off
if [ -f ~/.gdbinit.save ]; then
    # dont overwrite existing gdbinit
    if [ -f ~/.gdbinit ]; then
        echo "Error: ~/.gdbinit found. Aborting..."
        exit 1
    fi

    # restore gdbinit
    mv ~/.gdbinit.save ~/.gdbinit
    echo "gdbinit ON"
elif [ -f ~/.gdbinit ]; then
    mv ~/.gdbinit ~/.gdbinit.save
    echo "gdbinit OFF"
fi
