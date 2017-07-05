#!/bin/bash

# create new directory
[ -d /usr/share/warden/ ] || mkdir /usr/share/warden/  --verbose

echo "installation:"

# fill RELEASE for ... release :P
echo "RELEASE" > ./RELEASE

# build the release
echo "  - building a release of Warden"
crystal build ./src/warden.cr -o ./bin/warden --release

# move config file
cp ./config.yml /usr/share/warden/config.yml
if [[ -f /usr/share/warden/config.yml ]] ; then
    echo "  - config.yml ----------> /usr/share/warden/config.yml"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

# move uninstallation file
cp ./uninstall/linux.sh /usr/share/warden/uninstall.sh
if [[ -f /usr/share/warden/uninstall.sh ]] ; then
    echo "  - uninstall/linux.sh --> /usr/share/warden/uninstall.sh"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

# move binary
cp ./bin/warden /usr/bin/warden
if [[ -f /usr/bin/warden ]] ; then
    echo "  - bin/warden ----------> /usr/bin/warden"
else
    echo
    echo "Installation failed!"
    . uninstall/linux.sh
    exit 1
fi

# empty RELEASE
echo > ./RELEASE


# show a super message!
echo "Installation finished"