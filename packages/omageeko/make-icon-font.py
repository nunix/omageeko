#!/usr/bin/python3
"""omageeko: build the one-glyph "omageeko" icon font from a block-art grid.

  make-icon-font.py <grid.txt> <out.ttf>

The grid is Omarchy-logo-style block art: "█" filled, space empty, one text row
per line (a cell is one character wide and one row tall, i.e. 1:2). The glyph
goes to U+E900 in a 1024-unit em square with no descent: the same code point and
metrics as Omarchy's own icon font, so the bar's menu button keeps its size and
position when it switches fontFamily from "omarchy" to "omageeko".
"""
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM = 1024
CODEPOINT = 0xE900

grid_path, out_path = sys.argv[1], sys.argv[2]
rows = [line.rstrip("\n") for line in open(grid_path, encoding="utf-8")]
while rows and not rows[-1].strip():
    rows.pop()
width = max(len(r) for r in rows)
sx, sy = UPM / width, UPM / len(rows)

pen = TTGlyphPen(None)
for r, line in enumerate(rows):
    top = UPM - r * sy
    bottom = top - sy
    x = 0
    while x < width:
        if x < len(line) and line[x] == "█":
            start = x
            while x < len(line) and line[x] == "█":
                x += 1
            # one rectangle per horizontal run, clockwise (TrueType outer contour)
            x0, x1 = round(start * sx), round(x * sx)
            y0, y1 = round(bottom), round(top)
            pen.moveTo((x0, y0))
            pen.lineTo((x0, y1))
            pen.lineTo((x1, y1))
            pen.lineTo((x1, y0))
            pen.closePath()
        else:
            x += 1

empty = TTGlyphPen(None).glyph()
fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder([".notdef", "omageeko"])
fb.setupCharacterMap({CODEPOINT: "omageeko"})
fb.setupGlyf({".notdef": empty, "omageeko": pen.glyph()})
fb.setupHorizontalMetrics({".notdef": (UPM, 0), "omageeko": (UPM, 0)})
fb.setupHorizontalHeader(ascent=UPM, descent=0)
fb.setupNameTable({"familyName": "omageeko", "styleName": "Regular"})
fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=1116, usWinDescent=0)
fb.setupPost()
fb.save(out_path)
