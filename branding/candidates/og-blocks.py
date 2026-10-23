def render(letters, gap=1):
    rows = len(letters[0])
    out = []
    for r in range(rows):
        line = (" " * 4 * gap).join("".join("████" if ch == "#" else "    " for ch in L[r]) for L in letters).rstrip()
        out += [line, line]
    return out
O = [  # Omarchy maze, 7x7: frame, inner ring open top-right, connectors, left stub, bottom gap
 "#######",
 "#..#..#",
 "#.##..#",
 "###.#.#",
 "#.###.#",
 "#..#..#",
 "####.##",
]
G1 = [  # plain block G
 "#######",
 "#......",
 "#......",
 "#..####",
 "#.....#",
 "#.....#",
 "#######",
]
G2 = [  # G with Omarchy's double line: inner stroke parallel to the outer one
 "#######",
 "#......",
 "#.#####",
 "#.#.###",
 "#.#...#",
 "#.....#",
 "#######",
]
for name, g in (("OG, plain G", G1), ("OG, double-line G", G2)):
    print(f"--- {name}")
    print("\n".join(render([O, g])))

# Exact half-scale Omarchy logo: every 2nd row, every 2nd character
src = open("/home/nunix/.config/omarchy/branding/about.txt").read().splitlines()
half = [row[::2] for row in src[::2]]
w = max(len(r) for r in half)
half = [r.ljust(w) for r in half]
def blocks(rows, cw=2):   # '#' grid -> block characters, cw chars per cell, 1 row per cell
    return ["".join("█" * cw if ch == "#" else " " * cw for ch in r) for r in rows]
G_thin = blocks([          # 13 rows, cells of 2 chars x 1 row (same stroke as the half-scale O)
 "#############",
 "#############",
 "##...........",
 "##...........",
 "##...........",
 "##.....######",
 "##.....######",
 "##.........##",
 "##.........##",
 "##.........##",
 "##.........##",
 "#############",
 "#############",
], 1)
G_bold = blocks([          # 13 rows, 4-char x 2-row strokes like Omarchy's full-size logo
 "############",
 "############",
 "####........",
 "####........",
 "####........",
 "####...#####",
 "####...#####",
 "####......##",
 "####......##",
 "####......##",
 "############",
 "############",
 "############",
], 2)
for name, g in (("half-scale Omarchy O + G", G_thin), ("half-scale Omarchy O + bold G", G_bold)):
    print(f"--- {name}")
    for o_row, g_row in zip(half, g):
        print((o_row + "    " + g_row).rstrip())
