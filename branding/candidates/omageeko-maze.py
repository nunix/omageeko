import math, sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
import importlib.util
spec = importlib.util.spec_from_file_location("tw2", __file__.rsplit("/", 1)[0] + "/tumbleweed.py")
src = open(spec.origin).read().split("for rows, mode, scale in")[0]
exec(src)
exec(open(spec.origin).read().split("def bracket")[1].join(["def bracket", ""]) if False else "")
exec("def bracket" + open(spec.origin).read().split("def bracket")[1].split("def render_filled")[0])

def maze_cells(size):
    """Omarchy's inner maze, scaled: inner ring (size x size, opening top-right)
    plus connectors up, left and down to the surrounding ring. Offsets from centre."""
    h = size // 2
    cells = set()
    for d in range(-h, h + 1):
        cells |= {(d, h), (-h, d), (h, d)}            # bottom, left, right sides
        if d != h - 1: cells.add((d, -h))             # top side, opening next to the top-right corner
    for k in range(h + 1, h + 6):
        cells |= {(0, -k), (-k, 0), (0, k)}           # connectors (clipped by the ring)
    return cells

def render(rows, ring_scale, maze_size):
    cell = N / rows
    ccol, crow = round(TL[0] / cell - .5), round(TL[1] / cell - .5)
    inner = R - S * ring_scale                        # free radius inside the top ring
    maze = maze_cells(maze_size)
    out = []
    for r in range(rows):
        line = ""
        for c in range(rows):
            px, py = (c + .5) * cell, (r + .5) * cell
            top_ring = on_ring_scaled(px, py, ring_scale)
            in_top = math.hypot(px - TL[0], py - TL[1]) < inner
            bottom = (math.hypot(px - BR[0], py - BR[1]) <= R or (X - S/2 <= px <= BR[0] and Y - S/2 <= py <= BR[1])) \
                     and not bracket(px, py, 17) and not (px < X - S/2 or py < Y - S/2) or \
                     math.hypot(px - BR[0], py - BR[1]) <= R and not bracket(px, py, 17)
            cross = line_v(px, py, X, TL[1], Y) or line_h(px, py, Y, TL[0], X)
            v = top_ring or bottom or (cross and not in_top) or (in_top and (c - ccol, r - crow) in maze)
            line += "██" if v else "  "
        out.append(line.rstrip())
    return out

def on_ring_scaled(px, py, k):
    global S
    s0 = S; S = s0 * k
    v = on_ring(px, py, TL, [(0, 90)]); S = s0
    return v

for rows, k, m in [(26, 1.3, 5), (32, 1.3, 7)]:
    print(f"--- {rows} rows, maze {m}x{m}")
    print("\n".join(render(rows, k, m)))
