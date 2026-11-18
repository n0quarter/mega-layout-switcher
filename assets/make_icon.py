# Regenerate: uv run --with pillow python assets/make_icon.py assets/AppIcon.png
# Writes the PNG and, next to it, AppIcon.icns (via the built-in sips + iconutil).
import subprocess
import sys
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1]
N = 1024
S = 2  # render at 2x, downscale for smooth edges
FONT = "/System/Library/Fonts/SFNSRounded.ttf"

BLUE, YELLOW = (0, 87, 183), (255, 213, 0)
DEEP_BLUE = (0, 56, 128)


def font(size, weight="Bold"):
    f = ImageFont.truetype(FONT, size * S)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def s(v):
    return int(v * S)


# a bit larger than the 824px macOS grid, so it reads well at small sizes
x0, y0, x1, y1, radius = 60, 60, 964, 964, 205

# split background: blue top-left, yellow bottom-right
split = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
d = ImageDraw.Draw(split)
d.polygon([(s(x0), s(y0)), (s(x1), s(y0)), (s(x0), s(y1))], fill=BLUE)
d.polygon([(s(x1), s(y0)), (s(x1), s(y1)), (s(x0), s(y1))], fill=YELLOW)

mask = Image.new("L", split.size, 0)
ImageDraw.Draw(mask).rounded_rectangle([s(x0), s(y0), s(x1), s(y1)], s(radius), fill=255)

icon = Image.new("RGBA", split.size, (0, 0, 0, 0))
# soft drop shadow
shadow = Image.new("RGBA", split.size, (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle([s(x0), s(y0 + 12), s(x1), s(y1 + 12)], s(radius), fill=(0, 0, 0, 70))
icon.alpha_composite(shadow)
icon.paste(split, (0, 0), mask)

# keycap rim: a slightly darker inner edge at the bottom
d = ImageDraw.Draw(icon)
d.rounded_rectangle([s(x0), s(y0), s(x1), s(y1)], s(radius), outline=(0, 0, 0, 40), width=s(6))

# letters
d.text((s(320), s(330)), "A", font=font(470, "Heavy"), fill=(255, 255, 255), anchor="mm")
d.text((s(710), s(690)), "Ї", font=font(470, "Heavy"), fill=DEEP_BLUE, anchor="mm")

icon.resize((N, N), Image.LANCZOS).save(OUT)

with tempfile.TemporaryDirectory() as tmp:
    iconset = Path(tmp) / "AppIcon.iconset"
    iconset.mkdir()
    for size in [16, 32, 128, 256, 512]:
        for scale in [1, 2]:
            name = f"icon_{size}x{size}{'@2x' if scale == 2 else ''}.png"
            px = str(size * scale)
            subprocess.run(["sips", "-z", px, px, OUT, "--out", str(iconset / name)], check=True, capture_output=True)
    icns = Path(OUT).with_suffix(".icns")
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns)], check=True)

print("saved", OUT, "and", icns)
