#!/usr/bin/env python3

# Generate PNG texture from TTF font

import argparse
import os
from PIL import Image, ImageFont, ImageDraw
import math

def must_be_ttf_or_otf(filename):
    ext = os.path.splitext(filename)[1][1:]
    if ext not in ["ttf", "otf"]:
       parser.error("file doesn't end with .ttf or .otf")
    if not os.path.isfile(filename):
       parser.error("file \"%s\" doesn't exist" % filename)
    return filename

parser = argparse.ArgumentParser()
parser.add_argument("filename", type=must_be_ttf_or_otf, help="path to TTF or OTF font to convert")
parser.add_argument("fontsize", type=int, help="font size to export")
args = parser.parse_args()

CHARS = [
    " ☺☻♥♦♣♠●◘  ♂♀ ♪♫",
    "►◄↕‼¶§‗↨↑↓→←⌞↔▲▼",
    " !\"#$%&'()*+,-./",
    "0123456789:;<=>?",
    "@ABCDEFGHIJKLMNO",
    "PQRSTUVWXYZ[\]^_",
    "`abcdefghijklmno",
    "pqrstuvwxyz{|}~ ",
    "                ",
    "                ",
    " ¡¢£¤¥¦§¨©ª«¬－®¯",
    "°±²³´µ¶·¸¹º»¼½¾¿",
    "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ",
    "ÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß",
    "àáâãäåæçèéêëìíîï",
    "ðñòóôõö÷øùúûüýþÿ",
]

font = ImageFont.truetype(args.filename, args.fontsize)

# Get char stats
minY = math.inf
maxY = -math.inf
maxWidth = 0
for row in CHARS:
    for char in row:
        left, top, right, bottom = font.getbbox(char)
        minY = min(minY, top)
        maxY = max(maxY, bottom)
        maxWidth = max(maxWidth, right - left)

print("Min Y:", minY)
print("Max Y:", maxY)
print("Max width:", maxWidth)
charHeight = maxY - minY

# Generate texture
image = Image.new("1", (maxWidth * 16 , charHeight * 16), 0)
draw = ImageDraw.Draw(image)
for y, row in enumerate(CHARS):
    for x, char in enumerate(row):
        left, top, right, bottom = font.getbbox(char)
        dx = -left + math.floor((maxWidth - (right - left)) / 2)
        draw.text((x * maxWidth + dx, y * charHeight - minY), CHARS[y][x], 1, font=font)

# Export image
export_filename = args.filename[:-3] + "png"
image.save(export_filename, "PNG")
print("Exported font to %s!" % export_filename)
