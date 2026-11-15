# -*- coding: utf-8 -*-
"""Images for the App Store in-app event "Economy this week" (1.39.0).

  python3 store/event/make_images.py

Writes card-1920x1080.png (event card, 16:9) and details-1080x1920.png (event
details page, 9:16). The App Store lays the event name and description over
the lower part of both, so the images carry no text: the Economy this week
table in front, the Biz tab with its headline card behind, on the app's dark
field with an amber glow. Source shots come from the 1.39.0 (82) web build
(scratch shot.mjs, 440x956 at 3x). Phone frame: Ativa flyer helper.
"""
import os, importlib.util
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('fan', os.path.expanduser('~/Projects/ativa/tool/fan.py'))
fan = importlib.util.module_from_spec(spec); spec.loader.exec_module(fan)

DEEP = (12, 13, 16); GLOW = (92, 62, 8); AMBER = (255, 176, 0)


def field(W, H, cx, cy):
    im = Image.new('RGB', (W, H)); px = im.load()
    for y in range(H):
        for x in range(W):
            dx = (x - cx) / W * 1.4; dy = (y - cy) / H
            k = max(0.0, 1 - (dx * dx + dy * dy) ** 0.5 * 1.5)
            px[x, y] = tuple(int(DEEP[i] + (GLOW[i] - DEEP[i]) * k) for i in range(3))
    return im


def phone(name, w, angle):
    shot = Image.open(os.path.join(HERE, name)).convert('RGB')
    return fan.phone(shot, w).rotate(angle, expand=True, resample=Image.BICUBIC)


def put(bg, card, cx, cy):
    x, y = cx - card.width // 2, cy - card.height // 2
    bg.alpha_composite(fan.shadow(card, blur=30, alpha=160), (x - 44, y - 44 + 20))
    bg.alpha_composite(card, (x, y))


def compose(W, H, glow, back, front, out):
    bg = field(W, H, *glow).convert('RGBA')
    put(bg, phone('src-biz.png', back[2], back[3]), back[0], back[1])
    put(bg, phone('src-economy.png', front[2], front[3]), front[0], front[1])
    s = int(H * 0.012)  # amber stripe along the foot, as on the flyer
    ImageDraw.Draw(bg).rectangle((0, H - s, W, H), fill=AMBER)
    bg.convert('RGB').save(os.path.join(HERE, out))
    print(out)


# Card: two phones to the right, the table in front; the left half stays dark for the title.
compose(1920, 1080, (1400, 600), (1180, 700, 470, 6), (1560, 760, 520, -6), 'card-1920x1080.png')
# Details page: the table phone in the upper part, Biz peeking behind; the foot stays free.
compose(1080, 1920, (540, 760), (300, 700, 470, 7), (640, 820, 560, -4), 'details-1080x1920.png')
