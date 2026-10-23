import sys; sys.path.insert(0, __file__.rsplit("/", 1)[0]); from lib import *
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
# Filled
f = head(); ell(f, 18.5, 8, 3.5, 3.5, 0); ell(f, 19, 8, 1.7, 1.7); rect(f, 15, 18, 27, 19, 0)
show(clean(f), "1: Geeko, filled")
# Line art: 2-px head outline, eye ring + pupil on top, mouth as a stroke
l = outline(head(), 2)
ell(l, 18.5, 8, 5.8, 5.8); ell(l, 18.5, 8, 3.5, 3.5, 0); ell(l, 19, 8, 1.7, 1.7)
rect(l, 15, 17, 26, 19)           # mouth stroke (2 px, like Omarchy's lines)
show(clean(l), "2: Geeko, line art + filled eye")
