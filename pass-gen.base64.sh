#!/bin/bash 
if [[ -z $1 ]]
then
    echo "Entropy available: $(cat /proc/sys/kernel/random/entropy_avail)"
    read -p "The length of the new base-64 password (more than 22 is a paranoia case.)? : " -r
    LGTH=$REPLY
    REPLY='y'
    while [[ $REPLY =~ ^[Yy]$ ]]
        do
            echo ''
            gpg --gen-random --armor 2 $(echo "3*($LGTH/4+1)" | bc) | head -c $LGTH
            echo ""
            echo ""
            echo "Entropy available: $(cat /proc/sys/kernel/random/entropy_avail)"
            read -p "Again? y/any - " -n 1 -r
            echo ''
    done
else
    gpg --gen-random --armor 2 $(echo "3*($1/4+1)" | bc) | head -c $1
    echo ''
fi
