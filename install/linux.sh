#!/bin/bash



home=$(echo $HOME)
name="/root"

if ( $home !== $name ) ; then
    echo "this script must be"
    exit 1
fi

[ -d /usr/share/warden/ ] || mkdir /usr/share/warden/  --verbose

echo "installation:"

echo "RELEASE" > ./RELEASE

cp ./config.yml /usr/share/warden/config.yml
if [[ -f /usr/share/warden/config.yml ]] ; then
    echo "  - config.yml ----------> /usr/share/warden/config.yml"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

cp ./uninstall/linux.sh /usr/share/warden/uninstall.sh
if [[ -f /usr/share/warden/uninstall.sh ]] ; then
    echo "  - uninstall/linux.sh --> /usr/share/warden/uninstall.sh"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

cp ./bin/warden /usr/bin/warden
if [[ -f /usr/bin/warden ]] ; then
    echo "  - bin/warden ----------> /usr/bin/warden"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

rm ./RELEASE

echo "Installation finished"