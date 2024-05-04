# MORE FONTS for ComputerCraft
A library to print large text using teletext pixels with various fonts, sizes, and text wrapping options!

![mf-header](https://github.com/MichielP1807/more-fonts/assets/16452219/bc8cd6c6-432b-45ac-8707-3392eb57ecc1)

## Basic usage
Use the `print` function to print some text at the current cursor location:
```lua
local mf = require("morefonts")

term.clear()
term.setCursorPos(2, 2)
term.setTextColor(colors.yellow)
term.setBackgroundColor(colors.gray)

mf.print("Hey!")
```
If you don't want it to end on a new line, use `write` instead of `print`:
```lua
mf.write("Hi!")
```

If you want to print on a terminal at a specified location (`x`, `y`) without it scrolling when it gets to the bottom of the screen, use `writeOn` instead:
```lua
mf.writeOn(term, "Hey!", 3, 7)
```

Leaving the `x` and/or `y` as `nil` will automatically center it on the terminal:
```lua
mf.writeOn(term, "Wow!", nil, 2) -- horizontally centered
```

## Font options
These three functions all have an additional optional parameter for *font options*, with which you can specify e.g. which font to use, which size to use, and which alignment options to use:
```lua
mf.writeOn(term, "MORE FONTS can do text wrapping!", nil, nil, {
    font = "fonts/PublicPixel",
    dx = 0,
    dy = 0,
    scale = 1,
    wrapWidth = 80,
    condense = true,
    sepWidth = 1,
    spaceWidth = 5,
    lineSepHeight = 5,
    textAlign = "left",
    anchorHor = "center",
    anchorVer = "center",
})
```
![mf-font-options](https://github.com/MichielP1807/more-fonts/assets/16452219/fc7faccb-e982-477e-8a3b-a6cdd9522267)

All values in the font options are optional, so you do not have to specify all of them.
All numerical values in the font options except for `scale` are in *teletext pixels* (which are different from the *terminal character pixels* which are used for the (`x`, `y`) position for the `writeTo` function, every terminal character pixel consists of 2x3 teletext pixels).

### Default font options
After setting your own default values for any font options, these values will automatically be applied to any text (unless they are overwritten):
```lua
mf.setDefaultFontOptions({
    condense = true,
    font = "fonts/PublicPixel",
})

mf.print("hi")                            -- uses previously set default font
mf.print("hi", {font = "fonts/3x3-Mono"}) -- uses 3x3 Mono instead of default font (but is still condensed)
```
Any font option that you do not include in your own default font options will use the library's default value by default.

### Fonts & font sizes
Fonts size is dependent on the font that is used. Fonts that have higher resolution characters, will appear larger than fonts with lower resolution characters.
You can set the `scale` option to make text even larger, e.g. setting the scale to 3 will triple size of the displayed text:
```lua
mf.print("HUGE", {scale = 3}) -- same size as Bigfont's Huge (with default CC font)
```

<!-- Scale 1 = BigFont's size 1 (big) -->
<!-- Scale 3 = BigFont's size 2 (huge) -->
<!-- Scale 9 = BigFont's size 3 -->
<!-- And so on.... -->

### Text wrapping
This library respects new line characters (`"\n"`) by default, but additional automatic text wrapping can be enabled by configuring the `wrapWidth`, which configures the number maximum number of teletext pixels after which the text should wrap to a new line:
```lua
local TERM_WIDTH, TERM_HEIGHT = term.getSize()
mf.print(long_text, {wrapWidth = 2 * TERM_WIDTH})
```
Remember that one terminal character pixel horizontally consists of 2 teletext pixels, so to get the full width we multiply the `TERM_WIDTH` by 2.

### Text spacing
By default, all fonts are monospace, meaning that every character takes up the same width.
Setting `condense` to `true` will condense the empty space horizontally between characters, which often looks nicer.
When condensed, `sepWidth` determines the space between characters, and `spaceWidth` determines the width of space characters (`" "`).

You can configure additional vertical spacing between lines by setting `lineSepHeight` (this also works when not condensed).

The default values of `sepWidth`, `spaceWidth`, and `lineSepHeight` can be included with the fonts themselves, but setting your own (default) values will override the font's defaults.

### Alignment & positioning
Text can be aligned left (default), centered, or right using the `textAlign` option:
```lua
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = -18, textAlign = "left"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = 0, textAlign = "center"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = 18, textAlign = "right"})
```
![mf-text-align](https://github.com/MichielP1807/more-fonts/assets/16452219/644e5055-7d83-4c17-8312-68c46bfb34b3)

Setting the text alignment will also change the default horizontal anchor position accordingly.
You can manually change the horizontal anchor position using `anchorHor`:
```lua
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = -18, textAlign = "left", anchorHor = "center"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = 0, textAlign = "center", anchorHor = "center"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dy = 18, textAlign = "right", anchorHor = "center"})
```
![mf-anchor-hor](https://github.com/MichielP1807/more-fonts/assets/16452219/06876522-d6c5-4e92-b327-d7aec7db7d0a)

The vertical anchor position can be set using `anchorVer`:
```lua
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dx = -32, anchorVer = "top"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dx = 0, anchorVer = "center"})
mf.writeOn(term, "MORE\nFONTS", nil, nil, {dx = 32, anchorVer = "bottom"})
```
![mf-anchor-ver](https://github.com/MichielP1807/more-fonts/assets/16452219/95141bef-6af3-4751-bfa4-6951913453e5)

As seen in these previous examples, you can also move the text using the `dx` and `dy` options. These `dx` and `dy` values are in *teletext pixels* (unlike the standard `x` and `y` of the `writeOn` function), so this is useful for precise positioning, or if you want to shift the text a bit from the center as in the examples above.


## Font browser
Use the font browser to preview all available fonts from GitHub. Navigate left or right to switch between fonts.
![mf-font-browser](https://github.com/MichielP1807/more-fonts/assets/16452219/e5584c98-ad0e-42e1-b2c9-d5f5206c4056)


## Adding more custom fonts
### Create font from image texture
To create your own fonts that you can use with this library, you must first create a PNG image texture of the font. The width and height of this image must be multiples of 16, and every character must be put in its correct place based on the default ComputerCraft font (which is basically ASCII order with some additional characters).

Once you have your image texture, you can convert it with the `0_texture2lua.py` Python script:
```
./0_texture2lua.py ./my-fonts/PixelPlace.png
```
If you want to include `sepWidth`, `spaceWidth`, or `lineSepHeight` parameters with your font, or you want to include other metadata like the author name or font license, I recommend creating a `metadata.json` file in the same directory as the image texture. All properties in the `metadata.json` will automatically be included in the exported font file.

In the [my-fonts](https://github.com/MichielP1807/more-fonts/tree/main/fonts/my-fonts) folder you can see the files I used to generate my PixelPlace font as an example.

### Convert TTF/OTF to image texture
Instead of creating your own image textures, you can also convert TTF or OTF fonts to image textures automatically, just give it the path to the TTF or OTF font and the font size to use:
```
./0_font2texture.py GGBotNet-Public-Pixel/PublicPixel.ttf 8
```
If you convert someone else's font, please make sure to include the author's name, the font name, the source where you got the font from, and license & copyright information in the metadata of the font! Fonts licensed as Creative Commons or SIL Open Font License generally allow you to use and redistribute the fonts as you wish, but this often does require the appropriate attribution. Always check the license to be sure!
