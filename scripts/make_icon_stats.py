#!/usr/bin/env python3
"""Regenerate the launcher icon as the B mark over the word "stats".

The product is called BullDozer Stats on the App Store, so the mark carries the
word too and the surfaces agree with each other.

Nothing here is redrawn. The B and the letters are lifted as alpha masks from
the shipped artwork in assets/icon/_archive-with-stat/, which spells "stat" —
the closing s is the same glyph as the opening one, copied and set at the
spacing already used between the other letters, so the wordmark stays in its
original typeface down to the curve.

    python3 scripts/make_icon_stats.py && dart run flutter_launcher_icons

The B-only variant lives in make_icon.py; both read the same source, so either
can be regenerated at any time.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ICONS = Path(__file__).resolve().parent.parent / 'assets' / 'icon'
SRC = ICONS / '_archive-with-stat'
N = 1024

# The wordmark sits below this line; everything above it is the letter B.
WORD_TOP = 690
# The shipped diagonal runs corner to corner: orange where x + y exceeds this.
DIAGONAL = 1024


def ink_mask(img: Image.Image) -> Image.Image:
    """Everything genuinely dark and opaque in the source, as an alpha mask."""
    r, _, _, a = img.split()
    dark = r.point(lambda v: 255 if v < 120 else 0)
    return Image.composite(dark, Image.new('L', img.size, 0),
                           a.point(lambda v: 255 if v > 128 else 0))


def letters(mask: Image.Image):
    """The wordmark split into its glyphs, left to right, with their spacing.

    Letters are separated by finding the columns with no ink at all — the face
    is spaced widely enough that no two glyphs share a column.
    """
    word = mask.crop((0, WORD_TOP, N, N))
    cols = [any(word.getpixel((x, y)) for y in range(word.height)) for x in range(N)]
    runs, start = [], None
    for x, inked in enumerate(cols + [False]):
        if inked and start is None:
            start = x
        elif not inked and start is not None:
            runs.append((start, x - 1))
            start = None
    if len(runs) < 2:
        raise SystemExit(f'expected several letters in the wordmark, found {len(runs)}')
    gap = min(runs[i + 1][0] - runs[i][1] - 1 for i in range(len(runs) - 1))
    rows = [y for y in range(word.height)
            if any(word.getpixel((x, y)) for x in range(N))]
    top, bottom = min(rows), max(rows)
    glyphs = [word.crop((a, top, b + 1, bottom + 1)) for a, b in runs]
    return glyphs, gap, WORD_TOP + top


def compose_word(glyphs, gap: int) -> Image.Image:
    """s t a t + a second s, at the spacing the original already uses."""
    order = glyphs + [glyphs[0]]
    width = sum(g.width for g in order) + gap * (len(order) - 1)
    strip = Image.new('L', (width, max(g.height for g in order)), 0)
    x = 0
    for g in order:
        strip.paste(g, (x, 0))
        x += g.width + gap
    return strip


def background() -> Image.Image:
    """The two-tone field, drawn oversized and downsampled so the diagonal
    does not staircase — it is the one straight line in the whole mark."""
    s = N * 4
    bg = Image.new('RGB', (s, s), AMBER)
    d = ImageDraw.Draw(bg)
    c = DIAGONAL * 4
    d.polygon([(c, 0), (s, 0), (s, s), (0, s), (0, c)], fill=ORANGE)
    return bg.resize((N, N), Image.LANCZOS)


src_fg = Image.open(SRC / 'icon_foreground.png').convert('RGBA')
src_master = Image.open(SRC / 'icon.png').convert('RGB')
AMBER = src_master.getpixel((40, 40))
ORANGE = src_master.getpixel((N - 40, 40))
INK = src_master.getpixel((400, 450))


def main():
    mask = ink_mask(src_fg)
    b_mark = mask.crop((0, 0, N, WORD_TOP))
    glyphs, gap, word_top = letters(mask)
    word = compose_word(glyphs, gap)
    word_x = (N - word.width) // 2          # re-centred: it grew by one letter

    def stamp(canvas, ink_rgba):
        canvas.paste(Image.new(canvas.mode, (N, WORD_TOP), ink_rgba), (0, 0), b_mark)
        canvas.paste(Image.new(canvas.mode, word.size, ink_rgba), (word_x, word_top), word)
        return canvas

    stamp(background(), INK).save(ICONS / 'icon.png')

    # Android adaptive: flat plate behind, letters alone on transparent, because
    # the launcher crops the pair to its own shape and would cut the diagonal
    # at an arbitrary angle.
    Image.new('RGB', (N, N), AMBER).save(ICONS / 'icon_background.png')
    stamp(Image.new('RGBA', (N, N), (0, 0, 0, 0)), INK + (255,)).save(ICONS / 'icon_foreground.png')

    print(f'letters {len(glyphs)} + 1 repeat, gap {gap}px, word {word.width}px wide')
    print('wrote icon.png, icon_background.png, icon_foreground.png')


if __name__ == '__main__':
    main()
