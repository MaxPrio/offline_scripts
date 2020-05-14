#!/bin/bash

# Checking
for CMND in gpg zip qrencode ranger
    do
        if [[ $( command -v $CMND ) ]]
        then
            [[ -z $IN_HERE ]] && IN_HERE=$CMND || IN_HERE="$IN_HERE $CMND"
        else
            [[ -z $NOT_INSTLD ]] && NOT_INSTLD=$CMND || NOT_INSTLD="$NOT_INSTLD $CMND"
        fi
    done

# Some commands are installed with packages of different name, so:
# gpg - gnupg
NOT_INSTLD=$(echo "$NOT_INSTLD" | sed '{s/^gpg\ /gnupg\ /;s/\ gpg\ /\ gnupg\ /;s/\ gpg$/\ gnupg/}')

# Installing

[[ ! -z $NOT_INSTLD ]] && pacman -Sy

for PCKG in $(echo "$NOT_INSTLD" | tr " " "\n" )
do
    pacman -S --noconfirm "$PCKG" && INSTLD="$INSTLD$PCKG " || FAILD="$FAILD$PCKG "
done

# qrc.bin binary file
if [[ $( command -v qrc.bin ) ]]
then
    IN_HERE="$IN_HERE qrc.bin"
else
    if [[ -f qrc.bin ]]
        then
            chmod +x qrc.bin
            cp qrc.bin /usr/bin/
            IN_HERE="$IN_HERE qrc.bin "
        else
            FAILD="$FAILD qrc.bin "
            echo "There is no qrc.bin"
    fi
fi

cat << EOF

NESESSARY SOFT:
GnuPh     - for srandard symmetric encryption and password generation.
Zip       - for standard archiving.
qrencode  - for QR-code png images generation.
qrc.bin   - for QR-code text generation (a binary file).
ranger    - a file manager, for convenience.

installed:     $INSTLD

AVAILABLE:     $IN_HERE $INSTLD
NOT AVAILABLE: $FAILD

EOF
