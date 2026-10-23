import math, sys
W, H = 27, 26
def canvas(): return [[0]*W for _ in range(H)]
def ell(c, cx, cy, rx, ry, v=1):
    for y in range(H):
        for x in range(W):
            if ((x+.5-cx)/rx)**2 + ((y+.5-cy)/ry)**2 <= 1: c[y][x] = v
def rect(c, x0, y0, x1, y1, v=1):
    for y in range(max(0,y0), min(H,y1)):
        for x in range(max(0,x0), min(W,x1)): c[y][x] = v
def outline(c, t=1):
    o = canvas()
    for y in range(H):
        for x in range(W):
            if not c[y][x]: continue
            edge = any(not (0 <= y+dy < H and 0 <= x+dx < W and c[y+dy][x+dx])
                       for dy in range(-t, t+1) for dx in range(-t, t+1))
            o[y][x] = 1 if edge else 0
    return o
def show(c, title):
    print(f"--- {title}")
    for row in c: print("".join("██" if v else "  " for v in row).rstrip())

def clean(c):
    for _ in range(2):
        for y in range(H):
            for x in range(W):
                if c[y][x] and sum(c[y+dy][x+dx] for dy in (-1,0,1) for dx in (-1,0,1)
                                   if (dy or dx) and 0 <= y+dy < H and 0 <= x+dx < W) <= 1:
                    c[y][x] = 0
    return c
def head(eye_bump=True):
    h = canvas()
    ell(h, 11, 15, 10.5, 9.5); ell(h, 18, 15.5, 8.5, 7)
    if eye_bump: ell(h, 18.5, 8, 5.8, 5.8)
    return h
