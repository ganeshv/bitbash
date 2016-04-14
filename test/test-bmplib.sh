#!/usr/bin/env bash

. testlib.sh
. ../bmplib.sh

btest() {
    outfile="$1".bmp
    output_bmp >$RESDIR/$outfile
    cmp $RESDIR/$outfile $REFDIR/$outfile
        if [ $? != 0 ]; then
            printf "%-20s %s\n" "$1" "fail"
            return 1
        fi
        printf "%-20s %s\n" "$1" "pass"
}

echo "bmplib tests started on" $(date)
echo

# common_tests version bgcol fgcol

common_tests() {
    tag=$1
    version=$2
    bgcol=$3
    fgcol=$4

    # basic init test
    curcol=(00 00 00 00)
    pixels=()
    init_bmp $version 32 20
    btest init.$tag

    # baseline mtop image
    curcol=($bgcol)
    pixels=()
    init_bmp $version 32 20
    curcol=($fgcol)
    fill 0 0 $width 2
    line 0 $((height - 1)) $((width - 1)) $((height - 1))
    btest mtop1.$tag

    # mtop with graph
    curcol=($bgcol)
    pixels=()
    init_bmp $version 25 16
    curcol=($fgcol)
    fill 0 0 $width 2
    line 0 $((height - 1)) $((width - 1)) $((height - 1))
    heights=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 12 11 8 4 0 0)
    y1=1
    for ((i = 0; i < ${#heights[@]}; i++)); do
        line $i $y1 $i $((y1 + ${heights[$i]}))
    done
    btest mtop2.$tag

    # common drawing operations
    curcol=($bgcol)
    pixels=()
    init_bmp $version 25 16
    curcol=(00 00 ff ff)
    rect 0 0 $width $height
    curcol=(00 ff 00 ff)
    fill 5 10 5 5
    curcol=(ff 00 00 ff)
    fill 15 10 5 5
    curcol=(00 00 00 7f)
    line 9 5 15 5
    curcol=(00 00 ff ff)
    point 10 12
    point 14 12
    btest draw.$tag

    # swiss flag
    pixels=()
    curcol=(00 00 ff ff)
    init_bmp $version 32 32
    fill 0 0 $width $height
    curcol=(ff ff ff ff)
    fill 13 6 6 20
    fill 6 13 20 6
    btest swiss.$tag
}

common_tests v5 5 "00 00 00 00" "00 00 00 ff"
common_tests v1 1 "d0 d0 d0 7f" "00 00 00 ff"
