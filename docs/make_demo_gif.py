# Regenerate: uv run --with pillow python docs/make_demo_gif.py docs/demo.gif
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1]
S = 2  # render at 2x, downscale for smooth edges
W, H = 960, 460
FONT = "/System/Library/Fonts/SFNS.ttf"


def font(size, weight="Regular"):
    f = ImageFont.truetype(FONT, size * S)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


F_TEXT = font(17)
F_DRAFT = font(22)
F_BOLD = font(17, "Bold")
F_SMALL = font(13)
F_SIDEBAR = font(16)
F_SIDEBAR_BOLD = font(18, "Bold")
F_HEADER = font(18, "Bold")
F_MENU = font(13, "Semibold")
F_HUD_KEY = font(46, "Semibold")
F_HUD_LABEL = font(17, "Semibold")
F_HUD_SWAP = font(16, "Medium")

INK = (29, 28, 29)
MUTED = (97, 96, 97)
LINE = (221, 221, 221)
SIDEBAR = (63, 14, 64)
SIDEBAR_ACTIVE = (17, 100, 163)
SIDEBAR_TEXT = (207, 195, 207)
RED = (224, 30, 90)
UA_BLUE, UA_YELLOW = (0, 87, 183), (255, 215, 0)

SIDEBAR_W = 220
MENU_H = 28
COMPOSER_Y = 350
PREFIX, WRONG, RIGHT = "надрукувати ", "ЗВА", "PDF"


def s(v):
    return int(v * S)


def flag(d, x, y, layout):
    if layout == "UA":
        d.rectangle([s(x), s(y), s(x + 18), s(y + 6)], fill=UA_BLUE)
        d.rectangle([s(x), s(y + 6), s(x + 18), s(y + 12)], fill=UA_YELLOW)
    else:
        for i in range(6):
            d.rectangle([s(x), s(y + i * 2), s(x + 18), s(y + i * 2 + 1)], fill=(178, 34, 52))
        d.rectangle([s(x), s(y), s(x + 8), s(y + 6)], fill=(60, 59, 110))


def message(d, y, initials, color, name, time, text):
    x = SIDEBAR_W + 20
    d.rounded_rectangle([s(x), s(y), s(x + 36), s(y + 36)], s(6), fill=color)
    d.text((s(x + 18), s(y + 18)), initials, font=F_BOLD, fill=(255, 255, 255), anchor="mm")
    d.text((s(x + 48), s(y + 14)), name, font=F_BOLD, fill=INK, anchor="ls")
    name_w = d.textlength(name, font=F_BOLD) / S
    d.text((s(x + 56 + name_w), s(y + 14)), time, font=F_SMALL, fill=MUTED, anchor="ls")
    d.text((s(x + 48), s(y + 36)), text, font=F_TEXT, fill=INK, anchor="ls")


def frame(draft, *, layout="UA", wrong_mark=False, sent=False, hud=0.0):
    img = Image.new("RGB", (W * S, H * S), (255, 255, 255))
    d = ImageDraw.Draw(img)

    # macOS menu bar with the input-source indicator
    d.rectangle([0, 0, s(W), s(MENU_H)], fill=(236, 236, 238))
    flag(d, W - 120, 8, layout)
    d.text((s(W - 96), s(MENU_H / 2)), layout, font=F_MENU, fill=INK, anchor="lm")
    d.text((s(W - 16), s(MENU_H / 2)), "13:24", font=F_MENU, fill=INK, anchor="rm")

    # sidebar
    d.rectangle([0, s(MENU_H), s(SIDEBAR_W), s(H)], fill=SIDEBAR)
    d.text((s(18), s(MENU_H + 30)), "Team", font=F_SIDEBAR_BOLD, fill=(255, 255, 255), anchor="lm")
    for i, channel in enumerate(["general", "design", "random"]):
        y = MENU_H + 70 + i * 32
        if i == 0:
            d.rounded_rectangle([s(10), s(y - 13), s(SIDEBAR_W - 10), s(y + 13)], s(6), fill=SIDEBAR_ACTIVE)
        d.text((s(22), s(y)), f"#  {channel}", font=F_SIDEBAR, fill=(255, 255, 255) if i == 0 else SIDEBAR_TEXT, anchor="lm")

    # channel header
    d.text((s(SIDEBAR_W + 20), s(MENU_H + 30)), "# general", font=F_HEADER, fill=INK, anchor="lm")
    d.line([s(SIDEBAR_W), s(MENU_H + 58), s(W), s(MENU_H + 58)], fill=LINE, width=S)

    # messages
    message(d, 120, "O", (46, 182, 125), "Olena", "13:22", "Привіт! Що ще треба зробити по договору?")
    if sent:
        message(d, 190, "T", (236, 178, 46), "Taras", "13:24", PREFIX + RIGHT)

    # composer
    x0, x1 = SIDEBAR_W + 20, W - 20
    d.rounded_rectangle([s(x0), s(COMPOSER_Y), s(x1), s(COMPOSER_Y + 84)], s(8), outline=(134, 134, 134), width=S)
    tx, ty = x0 + 14, COMPOSER_Y + 32
    if draft:
        d.text((s(tx), s(ty)), draft, font=F_DRAFT, fill=INK, anchor="ls")
    else:
        d.text((s(tx + 4), s(ty)), "Message #general", font=F_DRAFT, fill=(150, 150, 150), anchor="ls")
    cursor_x = tx + d.textlength(draft, font=F_DRAFT) / S + 2 if draft else tx
    d.rectangle([s(cursor_x), s(ty - 20), s(cursor_x + 1.5), s(ty + 5)], fill=INK)
    if wrong_mark:  # red squiggle, like a spellcheck underline
        wx = tx + d.textlength(PREFIX, font=F_DRAFT) / S
        ww = d.textlength(WRONG, font=F_DRAFT) / S
        pts = [(s(wx + i), s(ty + 5 + (1.5 if (i // 3) % 2 else 0))) for i in range(int(ww) + 1)]
        d.line(pts, fill=RED, width=S * 2)
    send_x = x1 - 22
    d.rounded_rectangle([s(send_x - 16), s(COMPOSER_Y + 52), s(send_x + 12), s(COMPOSER_Y + 76)], s(4),
                        fill=(0, 122, 90) if draft else (221, 221, 221))
    d.polygon([(s(send_x - 7), s(COMPOSER_Y + 58)), (s(send_x + 5), s(COMPOSER_Y + 64)), (s(send_x - 7), s(COMPOSER_Y + 70))],
              fill=(255, 255, 255))

    # temporary "Option tapped" popup, macOS HUD style
    if hud > 0:
        overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
        o = ImageDraw.Draw(overlay)
        cx, cy, hw, hh = SIDEBAR_W + (W - SIDEBAR_W) / 2, 258, 230, 140
        o.rounded_rectangle([s(cx - hw / 2), s(cy - hh / 2), s(cx + hw / 2), s(cy + hh / 2)], s(18),
                            fill=(30, 30, 32, int(225 * hud)))
        white = (255, 255, 255, int(255 * hud))
        o.text((s(cx), s(cy - 30)), "⌥", font=F_HUD_KEY, fill=white, anchor="mm")
        o.text((s(cx), s(cy + 16)), "Option", font=F_HUD_LABEL, fill=white, anchor="mm")
        o.text((s(cx), s(cy + 46)), f"{WRONG}  →  {RIGHT}", font=F_HUD_SWAP, fill=(180, 180, 185, int(255 * hud)), anchor="mm")
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

    return img.resize((W, H), Image.LANCZOS)


frames, durations = [], []


def add(img, ms):
    frames.append(img)
    durations.append(ms)


add(frame(""), 900)
for i in range(1, len(PREFIX) + 1):
    add(frame(PREFIX[:i]), 80)
for i in range(1, len(WRONG) + 1):
    add(frame(PREFIX + WRONG[:i]), 150)
add(frame(PREFIX + WRONG, wrong_mark=True), 1100)

# Option tapped: popup fades in, the word is replaced, layout flips to EN
add(frame(PREFIX + WRONG, wrong_mark=True, hud=0.5), 40)
add(frame(PREFIX + WRONG, wrong_mark=True, hud=1), 250)
for i in range(1, len(WRONG) + 1):
    add(frame(PREFIX + WRONG[:-i], hud=1), 50)
for i in range(1, len(RIGHT) + 1):
    add(frame(PREFIX + RIGHT[:i], layout="EN", hud=1), 50)
add(frame(PREFIX + RIGHT, layout="EN", hud=1), 900)
for alpha in (0.66, 0.33):
    add(frame(PREFIX + RIGHT, layout="EN", hud=alpha), 50)
add(frame(PREFIX + RIGHT, layout="EN"), 900)

# Enter: sent
add(frame("", layout="EN", sent=True), 2500)

montage = Image.new("RGB", (W, H * len(frames)))
for i, f in enumerate(frames):
    montage.paste(f, (0, H * i))
palette = montage.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
paletted = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
paletted[0].save(OUT, save_all=True, append_images=paletted[1:], duration=durations, loop=0, optimize=True)
print("frames:", len(frames), "seconds:", sum(durations) / 1000)
