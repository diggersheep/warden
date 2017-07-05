#!/bin/bash

echo "uninstallation:"

# remove warden directory
if [[ -d /usr/share/warden ]] ; then
    rm -r /usr/share/warden/ 2> /dev/null
    echo "  - deletion of the directory /usr/share/warden/"
fi

# remove binary
if [[ -f /usr/bin/warden ]] ; then
    rm /usr/bin/warden 2> /dev/null
    echo "  - deletion of the binary /usr/bin/warden"
fi

echo "Unistallation finished"
