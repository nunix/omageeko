# omageeko branding

| Asset | File | Where it shows |
|---|---|---|
| OG wordmark (Omarchy's logo at half scale as the O, a bold G; "omageeko" and "OG") | `packages/omageeko/overlay/share/branding/about.txt` (= `candidates/8b-og-bold.txt`) | fastfetch, About |
| Icon: Omarchy's logo with a G as the inner square | `packages/omageeko/overlay/share/branding/omageeko-icon.txt` → `omageeko.ttf` (U+E900) by `packages/omageeko/make-icon-font.py` at build time | bar menu button, Update › Omageeko |
| Wordmark text (Omarchy block font) | `packages/omageeko/overlay/share/branding/logo.txt` | screensaver |

Colour: fastfetch draws the logo in green (`/etc/fastfetch/config.jsonc`, `"color": {"1": "green"}`); the bar icon follows the theme's foreground.

`candidates/` keeps the explored designs and the scripts that draw them (`og-half.py`, `og-blocks.py`, `tumbleweed.py`, `omageeko-maze.py`).
