#!/bin/bash
# Generats btc addresses.
  # entropy source: gpg --gen-random
  # formats: public: uncompressed; compressed.
  #          privet: wif; wif-comppressed; hex.
  # QR png:       qrencode
  # QR text:      qrc
#------------------------

# BTC TOOLS
#************
if ((BASH_VERSINFO[0] < 4))
then
    echo "This script requires bash version 4 or above." >&2
    exit 1
fi

pack() {
    echo -n "$1" |
    xxd -r -p
}

unpack() {
    local line
    xxd -p |
    while read line; do echo -n ${line/\\/}; done
}

declare -a base58=(
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
)
unset dcr; for i in {0..57}; do dcr+="${i}s${base58[i]}"; done
declare ec_dc='
I16i7sb0sa[[_1*lm1-*lm%q]Std0>tlm%Lts#]s%[Smddl%x-lm/rl%xLms#]s~
483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
2 100^d14551231950B75FC4402DA1732FC9BEBF-so1000003D1-ddspsm*+sGi
[_1*l%x]s_[+l%x]s+[*l%x]s*[-l%x]s-[l%xsclmsd1su0sv0sr1st[q]SQ[lc
0=Qldlcl~xlcsdscsqlrlqlu*-ltlqlv*-lulvstsrsvsulXx]dSXxLXs#LQs#lr
l%x]sI[lpSm[+q]S0d0=0lpl~xsydsxd*3*lal+x2ly*lIx*l%xdsld*2lx*l-xd
lxrl-xlll*xlyl-xrlp*+Lms#L0s#]sD[lpSm[+q]S0[2;AlDxq]Sdd0=0rd0=0d
2:Alp~1:A0:Ad2:Blp~1:B0:B2;A2;B=d[0q]Sx2;A0;B1;Bl_xrlm*+=x0;A0;B
l-xlIxdsi1;A1;Bl-xl*xdsld*0;Al-x0;Bl-xd0;Arl-xlll*x1;Al-xrlp*+L0
s#Lds#Lxs#Lms#]sA[rs.0r[rl.lAxr]SP[q]sQ[d0!<Qd2%1=P2/l.lDxs.lLx]
dSLxs#LPs#LQs#]sM[lpd1+4/r|]sR
';

decodeBase58() {
    local line
    echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
    dc -e "$dcr 16o0$(sed 's/./ 58*l&+/g' <<<$1)p" |
    while read line; do echo -n ${line/\\/}; done
}
encodeBase58() {
    local n
    echo -n "$1" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'
    dc -e "16i ${1^^} [3A ~r d0<x]dsxx +f" |
    while read -r n; do echo -n "${base58[n]}"; done
}

checksum() {
    pack "$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    unpack |
    head -c 8
}

checkBitcoinAddress() {
    if [[ "$1" =~ ^[$(IFS= ; echo "${base58[*]}")]+$ ]]
    then
        local h="$(decodeBase58 "$1")"
        checksum "${h:0:-8}" | grep -qi "^${h:${#h}-8}$"
    else return 2
    fi
}

hash160() {
    openssl dgst -sha256 -binary |
    openssl dgst -rmd160 -binary |
    unpack
}

hexToAddress() {
    local x="$(printf "%2s%${3:-40}s" ${2:-00} $1 | sed 's/ /0/g')"
    encodeBase58 "$x$(checksum "$x")"
    echo
}

BTC-all-from-hex() {
    if [[ "$1" =~ ^[5KL] ]] && checkBitcoinAddress "$1"
    then
        local decoded="$(decodeBase58 "$1")"
        if [[ "$decoded" =~ ^80([0-9A-F]{64})(01)?[0-9A-F]{8}$ ]]
        then $FUNCNAME "0x${BASH_REMATCH[1]}"
        fi
    elif [[ "$1" =~ ^[0-9]+$ ]]
    then $FUNCNAME "0x$(dc -e "16o$1p")"
    elif [[ "${1^^}" =~ ^0X([0-9A-F]{1,64})$ ]]
    then
        local exponent="${BASH_REMATCH[1]}"
        local uncompressed_wif="$(hexToAddress "$exponent" 80 64)"
        local compressed_wif="$(hexToAddress "${exponent}01" 80 66)"
        dc -e "$ec_dc lG I16i${exponent^^}ri lMx 16olm~ n[ ]nn" |
        {
            read y x
            X="$(printf "%64s" $x| sed 's/ /0/g')"
            Y="$(printf "%64s" $y| sed 's/ /0/g')"
            if [[ "$y" =~ [02468ACE]$ ]]
            then y_parity="02"
            else y_parity="03"
            fi
            uncompressed_addr="$(hexToAddress "$(pack "04$X$Y" | hash160)")"
            compressed_addr="$(hexToAddress "$(pack "$y_parity$X" | hash160)")"
            echo "$exponent" > new-hex
            echo "$compressed_wif" > new-wif-c
            echo "$compressed_addr" > new-addr-c
            echo "$uncompressed_wif" > new-wif
            echo "$uncompressed_addr" > new-addr
        }
    elif test -z "$1"
    then $FUNCNAME "0x$(openssl rand -rand <(date +%s%N; ps -ef) -hex 32 2>&-)"
    else
        echo unknown key format "$1" >&2
        return 2
    fi
}

vanityAddressFromPublicPoint() {
    if [[ "$1" =~ ^04([0-9A-F]{64})([0-9A-F]{64})$ ]]
    then
        dc <<<"$ec_dc 16o
        0 ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} rlp*+
        [lGlAxdlm~rn[ ]nn[ ]nr1+prlLx]dsLx
        " |
        while read -r x y n
        do
            local public_key="$(printf "04%64s%64s" $x $y | sed 's/ /0/g')"
            local h="$(pack "$public_key" | hash160)"
            local addr="$(hexToAddress "$h")"
            if [[ "$addr" =~ "$2" ]]
            then
                echo "FOUND! $n: $addr"
                return
            else echo "$n: $addr"
            fi
        done
    else
        echo unexpected format for public point >&2
        return 1
    fi
}

# END OF BTC TOOLS
#*******************
# FUNCTIONS
#****************

# general functions:
#-------------------
sys-entropy () {
    echo ''
    echo "SYSTEM ENTROPY LEVEL: $( cat /proc/sys/kernel/random/entropy_avail )"
    echo ''
}

mkdir_check () {
    [ ! -d "$1" ] && mkdir $1
}

random-base64 () {                # getting random bites
    gpg --gen-random --armor 2 $1
}

# btc generator "russian doll" functions:
#----------------------------------------

mv-home () {                      # renaming and moving the generated files to the dedicated folder
    NAME_DIR=$OUT_DIR/$NAME
    mkdir_check $NAME_DIR

    mv new-hex $NAME_DIR/1.$NAME-hex
    mv new-wif $NAME_DIR/2.$NAME-wif
    mv new-wif-c $NAME_DIR/3.$NAME-wif-c
    mv new-addr $NAME_DIR/4.$NAME-addr
    mv new-addr-c $NAME_DIR/5.$NAME-addr-c
}

qr-gen () {
    # png image generation
    [[ $(command -v qrencode) ]] &&\
        for btcf in $NAME_DIR/*; do qrencode -s 9 -m 2 -l H -o $btcf-QR.png "$(cat $btcf)"; done ||\
            echo "Cant generate QR imagese, cant find qrencode."
        # text-art generation
    [[ $(command -v qrc.bin) ]] &&\
            # need to filter out png images
        for btcf in $NAME_DIR/*hex $NAME_DIR/*wif $NAME_DIR/*-c $NAME_DIR/*addr; do qrc.bin "$(cat $btcf)" > $btcf-textQR.txt; done ||\
            echo "Cant generate QR-text-art, cant find qrc.bin."
}

cp-pub () {                           # coppying public data to separate folder
    mkdir $OUT_DIR_PUB/${NAME}_pub
    for pubf in $OUT_DIR/$NAME/*-addr*
    do
        cp $pubf $OUT_DIR_PUB/${NAME}_pub/${pubf##*/}
    done
}

a-new-btc-addr () {

    NAME=$1

    sys-entropy
    # getting hex, and using it to compute all the other formats
    BTC-all-from-hex $(echo -n  "0x$(echo $( random-base64 $SEEDSIZE ) | sha256sum  | tr -d \ - )")
    mv-home  # renaming and moving the generated files to the dedicated folder
    qr-gen
    cp-pub   # coppying public data to separate folder
}

multi-new-btc-addrss () {

    PRFX=$1
    START_INDX=$2
    END_INDX=$3

    INDX=$((START_INDX-1))
    while [[ $INDX -lt $END_INDX ]]
        do
            ((INDX++))
            a-new-btc-addr ${PRFX}.$INDX
        done
}

ask-and-gen () {
    read -p "Genetate many (Common-name.index) ? y/any - " -n 1 -r
    echo ''
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        read -p "Prefix(name): " -r
        PREFIX=$REPLY
        read -p "Start index: " -r
        START_INDEX=$REPLY
        read -p "End index: " -r
        END_INDEX=$REPLY

        multi-new-btc-addrss $PREFIX $START_INDEX $END_INDEX
    else
        read -p "Generate one? y/any - " -n 1 -r
        echo ''
        if [[ $REPLY =~ ^[Yy]$ ]]
            then
                read -p "Name: " -r
                echo ''
                a-new-btc-addr $REPLY
        fi
    fi
}

gen-cycle () {
    REPLY='y'
    while [[ $REPLY =~ ^[Yy]$ ]]
    do
        ask-and-gen
        echo ''
        read -p "Continue generating? y/any - " -n 1 -r
        echo ''
    done
}

# END OF FUNCTIONS
#***********************
# ACTION
#**************************

echo '    BITCOIN ADDRESS GENERATOR'
echo '    -------------------------'
echo ''
read -p "Output directoty name: " -r
OUT_DIR="$REPLY"
OUT_DIR_PUB="${OUT_DIR}_pub"
SEEDSIZE=128 # number of random bites to hash down for the new hexes.

mkdir_check $OUT_DIR
mkdir_check $OUT_DIR_PUB

gen-cycle

echo ''
sys-entropy
echo '    -----------------------------'
echo '    DONE GENERATING BTC ADDRESSES.'
echo ''

# END OF ACTION
#**************************
