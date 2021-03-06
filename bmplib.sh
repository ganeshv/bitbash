#!/usr/bin/env bash

## bmplib.sh v1.0
#
# Make your own BMP from scratch, no external dependencies.
# Useful in BitBar plugins.
#
# pixels=()             # set pixels to empty or with background of same size
#                       # as will be declared in init_bmp
# curcol=(bb 66 44 aa)  # set current color, BGRA, hex (%02x)
# init_bmp 1 25 16      # initialize BMP, version 1 width 25 height 16
#                       # if pixels not valid, initialize to $curcol
# curcol=(00 00 00 ff)  # set current color to fully opaque black
# point $x $y           # set ($x, $y) to $curcol. (0, 0) is bottom left
# line $x1 $y1 $x2 $y2  # draw horizontal or vertical line
# rect $x $y $w $h      # draw rectangle. ($x, $y) is bottom left
# fill $x $y $w $h      # draw filled rectangle. ($x, $y) is bottom left
# output_bmp            # output BMP to stdout

bmp_ver=5               # set to 1 if you want most compatible BMP. no alpha.
width=25                # width of image
height=16               # height of image
curcol=(00 00 00 00)    # current color

# No user-servicable parts below
# We avoid subshells for performance reasons

bpp=4
rowbytes=$((width * bpp))
pixbytes=$((width * height * bpp))

OLDIFS=$IFS
bmp_header=()
pixels=()

# Takes number, prints hex bytes in little endian
# e.g. hexle32 3142 will output 46 0c 00 00
hexle32() {
    local num
    printf -v num "%08x" "$1"
    retval="${num:6:2} ${num:4:2} ${num:2:2} ${num:0:2}"
}

errmsg() {
    >&2 echo "$@"
}

# make_bmp_header
# version can be 1 or 5
# v1 is the most compatible, but the graph will be opaque - no alpha support.
# v5 supports alpha channel.
make_bmp_header() {
    local headerbytes comp pixoffset filebytes _filebytes _pixoffset
    local _headerbytes _width _height _pixbytes
    bmp_header=()
    headerbytes=40
    comp="00"
    if [ "$bmp_ver" -eq 5 ]; then
        headerbytes=124
        comp="03"
    fi
    pixoffset=$((headerbytes + 14))
    filebytes=$((pixbytes + pixoffset))

    hexle32 $filebytes
    _filebytes=$retval
    hexle32 $pixoffset
    _pixoffset=$retval
    hexle32 $headerbytes
    _headerbytes=$retval
    hexle32 $width
    _width=$retval
    hexle32 $height
    _height=$retval
    hexle32 $pixbytes
    _pixbytes=$retval

    # Common bits for version 1 and 5
    bmp_header+=(
        42 4d                   # "BM" magic
        $_filebytes             # size of file
        00 00                   # reserved
        00 00                   # reserved
        $_pixoffset             # offset of pixel data
        $_headerbytes           # remaining bytes in header
        $_width                 # width
        $_height                # height
        01 00                   # 1 color plane
        20 00                   # 32 bits per pixel
        $comp 00 00 00          # compression
        $_pixbytes              # size of pixel data
        13 0b 00 00             # ~72 dpi horizontal
        13 0b 00 00             # ~72 dpi vertical
        00 00 00 00             # colors in palette
        00 00 00 00             # all colors are important
    )
    if [ "$bmp_ver" -eq 5 ]; then
        bmp_header+=(
            00 00 ff 00             # red channel mask (BGRA)
            00 ff 00 00             # green channel mask
            ff 00 00 00             # blue channel mask
            00 00 00 ff             # alpha channel mask
            42 47 52 73             # sRGB
            00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            00 00 00 00             # red gamma
            00 00 00 00             # green gamma
            00 00 00 00             # blue gamma
            00 00 00 00             # intent
            00 00 00 00             # profile data
            00 00 00 00             # profile size
            00 00 00 00             # reserved
        )
    fi
}

# point x y
point() {
    local off
    off=$(($2 * rowbytes + $1 * bpp))
    pixels[$off]=${curcol[0]}
    pixels[$((off + 1))]=${curcol[1]}
    pixels[$((off + 2))]=${curcol[2]}
    pixels[$((off + 3))]=${curcol[3]}
}

# line x1 y1 x2 y2
line() {
    local x1 y1 x2 y2 x y
    if [ "$1" -eq "$3" ]; then
        if [ "$2" -gt "$4" ]; then y1=$4; y2=$2; else y1=$2; y2=$4; fi
        for ((y = y1; y <= y2; y++)); do
            point "$1" $y
        done
    elif [ "$2" -eq "$4" ]; then
        if [ "$1" -gt "$3" ]; then x1=$3; x2=$1; else x1=$1; x2=$3; fi
        for ((x = x1; x <= x2; x++)); do
            point $x "$2"
        done
    else
        errmsg "Only vertical and horizontal lines supported" "$@"
    fi
}

# fill x y w h
function fill() {
    local x2 y2 y
    x2=$(($1 + $3 - 1))
    y2=$(($2 + $4 - 1))
    for ((y = $2; y <= y2; y++)); do
        line "$1" $y $x2 $y
    done
}

# rect x y w h
function rect() {
    local x2 y2
    x2=$(($1 + $3 - 1))
    y2=$(($2 + $4 - 1))
    line "$1" "$2" $x2 "$2"
    line "$1" $y2 $x2 $y2
    line "$1" "$2" "$1" $y2
    line $x2 "$2" $x2 $y2
}

output_bmp() {
    local _bmp=(${bmp_header[@]/#/'\x'})
    _bmp+=(${pixels[@]/#/'\x'})

    local IFS=''
    #echo -ne "${_bmp[*]}" >/tmp/mtop.bmp
    echo -ne "${_bmp[*]}"
    IFS=$OLDIFS
}

# init_bmp bmp_ver width height
init_bmp() {
    local i
    bmp_ver=${1:-$bmp_ver}
    width=${2:-$width}
    height=${3:-$height}

    rowbytes=$((width * bpp))
    pixbytes=$((width * height * bpp))

    make_bmp_header
    if [ ${#pixels[@]} -ne $pixbytes ]; then
        pixels=()
        for ((i = 0; i < width * height; i++)); do
            pixels+=(${curcol[@]});
        done
    fi
}

## End of bmplib.sh
