#!/usr/bin/env python3
"""Regenerate the launcher icon: the B mark alone, no 'stat' wordmark.

The app is BullDozer everywhere — launcher label, both store listings — so the
icon was the last surface still saying "Stats". At the ~60pt a home screen
actually renders, that word was an unreadable smudge; Apple's icon guidance is
to keep text out for exactly that reason.

The letterform is not redrawn: it is lifted as a mask from the existing
artwork, so the B is glyph-for-glyph the one that shipped. Only the wordmark is
dropped and the letter re-centred and enlarged into the space it left.

The previous artwork, with the wordmark, is kept in assets/icon/_archive-with-stat/.

    python3 scripts/make_icon.py && dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image

ICONS = Path(__file__).resolve().parent.parent / 'assets' / 'icon'
SRC = ICONS / '_archive-with-stat'
N = 1024

# The wordmark starts around y=700 in the source; everything above it is the B.
B_CUTOFF = 690

# How tall the letter stands, as a fraction of the canvas.
#   iOS/master: the whole square is the icon, so the mark can be generous.
#   Android foreground: the launcher masks to a circle and only the inner ~66%
#   is guaranteed visible, so the letter has to stay well inside that.
HEIGHT_MASTER = 0.50
HEIGHT_ADAPTIVE = 0.44


def glyph_mask() -> Image.Image:
    """The B, cut out of the old foreground as an alpha mask."""
    src = Image.open(SRC / 'icon_foreground.png').convert('RGBA')
    r, g, b, a = src.split()
    # Dark ink on white: anything genuinely dark and opaque is the artwork.
    mask = Image.eval(r.point(lambda v: 255 if v < 120 else 0), lambda v: v)
    mask = Image.composite(mask, Image.new('L', src.size, 0), a.point(
        lambda v: 255 if v > 128 else 0))
    mask = mask.crop((0, 0, N, B_CUTOFF))
    box = mask.getbbox()
    if box is None:
        raise SystemExit('no glyph found in the source foreground')
    return mask.crop(box)


def sample_palette() -> tuple:
    """Amber, orange and ink, read off the shipped icon rather than guessed."""
    old = Image.open(SRC / 'icon.png').convert('RGB')
    amber = old.getpixel((40, 40))            # top-left field
    orange = old.getpixel((N - 40, 40))       # across the diagonal
    ink = old.getpixel((400, 450))            # inside the letter's stem
    return amber, orange, ink


def background(amber, orange, cut: float) -> Image.Image:
    """The two-tone field: a single diagonal, orange below and right of it.

    [cut] is where the anti-diagonal x + y crosses, in canvas units. The
    shipped icon ran it corner to corner at 0.92, which sliced the letter
    across the middle once the wordmark went and the B grew into the space.
    Now it is derived from the glyph's own corner, so the diagonal reads as a
    folded corner behind the mark rather than a line drawn through it.

    Drawn on a 4x grid and downsampled — a polygon edge at icon size aliases
    into a visible staircase on the diagonal, which is the one straight line in
    the whole mark.
    """
    s = N * 4
    bg = Image.new('RGB', (s, s), amber)
    from PIL import ImageDraw
    d = ImageDraw.Draw(bg)
    c = int(cut * 4)
    d.polygon([(c, 0), (s, 0), (s, s), (0, s), (0, c)], fill=orange)
    return bg.resize((N, N), Image.LANCZOS)


def layout(mask: Image.Image, height: float):
    """Scale the glyph to [height] of the canvas and centre it.

    Returns the resized mask and its top-left corner.
    """
    target_h = int(N * height)
    scale = target_h / mask.height
    m = mask.resize((max(1, round(mask.width * scale)), target_h),
                    Image.LANCZOS)
    x = (N - m.width) // 2
    # Optically centred: a capital reads low when its bbox is centred exactly,
    # so it sits a touch above the geometric middle.
    y = (N - m.height) // 2 - int(N * 0.015)
    return m, x, y


def main():
    amber, orange, ink = sample_palette()
    mask = glyph_mask()

    m, x, y = layout(mask, HEIGHT_MASTER)
    # Clear the letter's far corner by a hair over one icon-grid step, so the
    # fold touches the mark without cutting it.
    cut = (x + m.width) + (y + m.height) + int(N * 0.045)
    master = background(amber, orange, cut)
    master.paste(Image.new('RGB', m.size, ink), (x, y), m)
    master.save(ICONS / 'icon.png')

    # Android adaptive: flat amber plate, letter alone on transparent. The
    # launcher crops to its own shape, so the fold would be cropped at random —
    # the background layer stays a single flat colour.
    Image.new('RGB', (N, N), amber).save(ICONS / 'icon_background.png')
    m, x, y = layout(mask, HEIGHT_ADAPTIVE)
    fg = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    fg.paste(Image.new('RGBA', m.size, ink + (255,)), (x, y), m)
    fg.save(ICONS / 'icon_foreground.png')

    print(f'amber {amber}  orange {orange}  ink {ink}')
    print('wrote icon.png, icon_background.png, icon_foreground.png')


if __name__ == '__main__':
    main()
