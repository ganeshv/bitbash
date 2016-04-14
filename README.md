# bitbash

Create BMP files from scratch using pure bash. No external dependencies.

Currently used in [BitBar](https://github.com/matryer/bitbar) plugins like [mtop](https://github.com/ganeshv/mtop)
to draw small graphs to display on the Mac OS menubar.

## Usage

`bitbash` supports two versions of BMP files.

  * Version 1 corresponds to BITMAPINFOHEADER as described [on Wikipedia](https://en.wikipedia.org/wiki/BMP_file_format). This is the most compatible version of BMP, but most viewers don't honour the alpha channel.
  * Version 5 corresponds to BITMAPV5HEADER, which officially supports alpha.

Note that `file` doesn't recognize the v5 files we make, or that ImageMagick
makes, but Preview et al do.

Drawing primitives set the current color. No alpha blending is done.


    pixels=()             # set pixels to empty or with background of same size
    curcol=(bb 66 44 aa)  # set current color, BGRA, hex (%02x)
    init_bmp 1 25 16      # initialize BMP, version 1 width 25 height 16
                          # if pixels not valid, initialize to $curcol
    curcol=(bb 66 44 aa)  # set current color, BGRA, hex (%02x)
    point $x $y           # set ($x, $y) to $curcol. (0, 0) is bottom left
    line $x1 $y1 $x2 $y2  # draw horizontal or vertical line
    rect $x $y $w $h      # draw rectangle
    fill $x $y $w $h      # draw filled rectangle
    output_bmp            # output BMP to stdout

## Examples

### Swiss flag

    pixels=()
    curcol=(00 00 ff ff)
    init_bmp 1 32 32
    fill 0 0 $width $height
    curcol=(ff ff ff ff)
    fill 13 6 6 20
    fill 6 13 20 6
    output_bmp >/tmp/flag.bmp

produces this 32x32 BMP: ![swiss flag](https://raw.github.com/ganeshv/bitbash/master/test/ref/swiss.v1.bmp)

### Bar graph

    pixels=()
    curcol=(00 00 00 00)
    init_bmp 5 25 16
    curcol=(00 00 00 ff)
    fill 0 0 $width 2
    line 0 $((height - 1)) $((width - 1)) $((height - 1))
    heights=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 12 11 8 4 0 0)
    for ((i = 0; i < ${#heights[@]}; i++)); do
        line $i 1 $i $((1 + ${heights[$i]}))
    done
    output_bmp >/tmp/graph.bmp

produces the following 25x16 BMP: ![bar graph](https://raw.github.com/ganeshv/bitbash/master/test/ref/mtop2.v5.bmp)
