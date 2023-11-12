#!/usr/bin/env python3

# Convert PNG texture to font data usable by morefonts

import argparse
import json
import os
from PIL import Image 

def must_be_png(filename):
    ext = os.path.splitext(filename)[1][1:]
    if ext != "png":
       parser.error("file doesn't end with .png")
    if not os.path.isfile(filename):
       parser.error("file doesn't exist")
    return filename

parser = argparse.ArgumentParser()
parser.add_argument("filenames", type=must_be_png, nargs='+', help="one or more paths to PNG textures to convert")
args = parser.parse_args()

DATA_START = 0x20 # We add 0x20 to ensure printable characters
MAX_PIXELS_PER_CHAR = 6 # We encode max 6 pixels into a single char (to ensure printable characters)

for pngFile in args.filenames:
    image = Image.open(pngFile)
    WIDTH, HEIGHT = image.size 

    print("Texture size:\t %dx%d" % (WIDTH, HEIGHT))
    if WIDTH % 16 != 0 or HEIGHT % 16 != 0:
        print("Unexpected image texture size! Width and height must be a multiple of 16!")
        exit()

    CHAR_WIDTH = WIDTH // 16
    CHAR_HEIGHT = HEIGHT // 16
    print("Character size:\t %dx%d" % (CHAR_WIDTH, CHAR_HEIGHT))

    # Generate font data
    fontData = ""
    startX = ""
    lengthX = ""
    for charY in range(16):
        for charX in range(16):
            charData = ""
            minX = CHAR_WIDTH+1  # 1 indexed
            maxX = 0             # 1 indexed
            for y in range(CHAR_HEIGHT):
                rowData = 0
                for x in range(CHAR_WIDTH):
                    if x> 0 and x % MAX_PIXELS_PER_CHAR == 0:
                        # Split row over multiple characters if too many pixels wide
                        charData += chr(rowData + DATA_START)
                        rowData = 0
                    b = image.getpixel((charX * CHAR_WIDTH + x, charY * CHAR_HEIGHT + y))
                    if type(b) is tuple:  # if r,g,b colors instead of binary color mode
                        b = 1 if b[0] > 127 else 0
                    b = min(b, 1)
                    rowData += b << (x % MAX_PIXELS_PER_CHAR)
                    if b == 1:
                        minX = min(minX, x+1)  # 1 indexed
                        maxX = max(maxX, x+1)  # 1 indexed
                charData += chr(rowData + DATA_START)
            fontData += charData
            startX += chr(min(minX + DATA_START, 255))
            lengthX += chr(min(max(maxX - minX + 1, 0) + DATA_START, 255))
    print("Data length:\t %d" % len(fontData))

    # Load meta data
    metadataPath = os.path.join(os.path.dirname(pngFile), "metadata.json")
    metadata = {}
    if os.path.isfile(metadataPath):
        with open(metadataPath, "r") as metadataFile:
            metadata = json.load(metadataFile)

    def toLongBracketString(text):
        longBracketLevel = 0
        while ("]" + longBracketLevel * "=" + "]") in text:
            longBracketLevel += 1
        return "[%s[%s]%s]" % (longBracketLevel * "=", text, longBracketLevel * "=")

    # Export font to serialized lua table file (no file extension)
    export_filename = os.path.basename(pngFile)[:-4]
    with open(export_filename, "w", encoding="utf-8") as file:
        file.write("{\n")
        for k,v in metadata.items():
            file.write("\t%s = %s,\n" % (k, json.dumps(v, ensure_ascii=False)))
        file.write("\tdata = %s,\n" % toLongBracketString(fontData))
        file.write("\tstartX = %s,\n" % toLongBracketString(startX))
        file.write("\tlengthX = %s,\n" % toLongBracketString(lengthX))
        file.write("\tcharW = %d,\n" % CHAR_WIDTH)
        file.write("\tcharH = %d\n" % CHAR_HEIGHT)
        file.write("}")

    print("Exported %s to %s!" % (pngFile, export_filename))
