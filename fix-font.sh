#!/bin/bash

nc="$(tput sgr0)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"

pacman -Sy --noconfirm terminus-font

FSIZE=24
while [[ ! $REPLY =~ ^[Yy]$ ]]
    do
        clear
        echo -n "Trying to set $yellow${FSIZE}$nc fontsize..."
        setfont ter-v${FSIZE}b > /dev/null 2>&1 && echo "$green Done.$nc" || echo "$red Fail.$nc"
        echo 
        echo "The size does not matter, as long as it is this size."
        read -p "Right? [y|k|j] - " -n 1 -r
        [[ $REPLY =~ ^[Kk]$ ]] && FSIZE=$(($FSIZE+2))
        [[ $REPLY =~ ^[Jj]$ ]] && FSIZE=$(($FSIZE-2))
    done

