import math, sys
# Geometry in the official SVG's rendered space (logo part ~880x880 px)
N = 880.0
R, S = 232.0, 55.0                 # ring outer radius, stroke width (as in the logo)
TL, BR = (235.0, 237.0), (650.0, 645.0)
X, Y = 442.0, 437.0                # centre cross (vertical x, horizontal y)
def on_ring(px, py, c, quarters_missing):
    dx, dy = px - c[0], py - c[1]
    d = math.hypot(dx, dy)
    if abs(d - (R - S / 2)) > S / 2: return False
    a = math.degrees(math.atan2(dy, dx)) % 360      # 0 = right, 90 = down
    return not any(lo <= a < hi for lo, hi in quarters_missing)
def line_v(px, py, x, y0, y1): return abs(px - x) <= S / 2 and y0 <= py <= y1
def line_h(px, py, y, x0, x1): return abs(py - y) <= S / 2 and x0 <= px <= x1
def logo(px, py, stroke_scale=1.0):
    global S
    s0 = S; S = s0 * stroke_scale
    hit = (on_ring(px, py, TL, [(0, 90)])          # top-left ring open towards the bottom-right
           or on_ring(px, py, BR, [(180, 270)])    # bottom-right ring open towards the top-left
           or line_v(px, py, X, TL[1], BR[1])      # the cross
           or line_h(px, py, Y, TL[0], BR[0])
           or line_v(px, py, 287, 30, 308) or line_h(px, py, 280, 30, 315)    # top-left bracket
           or line_v(px, py, 602, 570, 860) or line_h(px, py, 597, 575, 860)) # bottom-right bracket
    S = s0
    return hit
def inside_loop(px, py):
    return math.hypot(px - TL[0], py - TL[1]) <= R or math.hypot(px - BR[0], py - BR[1]) <= R or \
           (TL[0] <= px <= BR[0] and TL[1] <= py <= BR[1] and (px <= X + S/2 and py <= Y + S/2 or px >= X - S/2 and py >= Y - S/2))
def render(rows, mode, scale):
    cols = rows
    cell = N / rows
    out = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            px, py = (c + .5) * cell, (r + .5) * cell
            if mode == "line": v = logo(px, py, scale)
            else: v = inside_loop(px, py) and not logo(px, py, scale * 0.55) or on_ring(px, py, TL, [(0, 90)]) or on_ring(px, py, BR, [(180, 270)])
            line += "██" if v else "  "
        out.append(line.rstrip())
    return out
for rows, mode, scale in [(26, "line", 1.35), (26, "filled", 1.0), (20, "line", 1.45)]:
    print(f"--- {mode}, {rows} rows, stroke x{scale}")
    print("\n".join(render(rows, mode, scale)))

def bracket(px, py, w):
    return (abs(px - 287) <= w and 30 <= py <= 280 + w) or (abs(py - 280) <= w and 30 <= px <= 287 + w) or \
           (abs(px - 602) <= w and 597 - w <= py <= 860) or (abs(py - 597) <= w and 602 - w <= px <= 860)
def loop_shape(px, py):
    # the two discs plus the square between their centres (the hourglass waist)
    return math.hypot(px - TL[0], py - TL[1]) <= R or math.hypot(px - BR[0], py - BR[1]) <= R or \
           (TL[0] <= px <= X + S / 2 and TL[1] <= py <= Y + S / 2) or (X - S / 2 <= px <= BR[0] and Y - S / 2 <= py <= BR[1])
def render_filled(rows, gap):
    cell = N / rows
    return ["".join("██" if loop_shape((c+.5)*cell, (r+.5)*cell) and not bracket((c+.5)*cell, (r+.5)*cell, gap) else "  "
                    for c in range(rows)).rstrip() for r in range(rows)]
print("--- filled v2, 26 rows")
print("\n".join(render_filled(26, 17)))
