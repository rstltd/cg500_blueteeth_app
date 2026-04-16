"""Generate the CG500 BLE app icon as a 1024x1024 PNG.

Design: rounded blue gradient background with a white antenna symbol
radiating BLE signal arcs. Original artwork, no trademark concerns.
"""

from PIL import Image, ImageDraw
import math, os

SIZE = 1024
RADIUS = 220  # corner radius for the background
PAD = 0  # no padding, fill entire canvas

# Colors
BG_TOP = (66, 165, 245)      # #42A5F5 — Material Blue 400
BG_BOTTOM = (21, 101, 192)   # #1565C0 — Material Blue 800
WHITE = (255, 255, 255)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    # Corners
    draw.pieslice([x0, y0, x0 + 2*radius, y0 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2*radius, y0, x1, y0 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2*radius, x0 + 2*radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2*radius, y1 - 2*radius, x1, y1], 0, 90, fill=fill)
    # Rectangles filling the gaps
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# --- Background gradient (vertical) ---
bg = Image.new('RGB', (SIZE, SIZE))
bg_draw = ImageDraw.Draw(bg)
for y in range(SIZE):
    t = y / SIZE
    color = lerp_color(BG_TOP, BG_BOTTOM, t)
    bg_draw.line([(0, y), (SIZE, y)], fill=color)

# Apply rounded mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
draw_rounded_rect(mask_draw, (0, 0, SIZE, SIZE), RADIUS, fill=255)
img.paste(bg, mask=mask)
draw = ImageDraw.Draw(img)

# --- Antenna (vertical line + circle base + ground plate) ---
cx, cy = SIZE // 2, SIZE // 2
line_w = 28
# Vertical antenna pole
draw.line([(cx, 160), (cx, 540)], fill=WHITE, width=line_w)
# Antenna tip (circle at top)
tip_r = 22
draw.ellipse([cx - tip_r, 138, cx + tip_r, 138 + 2*tip_r], fill=WHITE)
# Base circle
base_r = 28
draw.ellipse([cx - base_r, 540, cx + base_r, 540 + 2*base_r], fill=WHITE)
# Ground plate
draw.line([(cx - 100, 610), (cx + 100, 610)], fill=WHITE, width=22)

# --- Signal arcs (using arc drawing) ---
def draw_arc(draw, cx, cy, radius, start_angle, end_angle, width, alpha=255):
    """Draw an arc centered at (cx, cy)."""
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    color = WHITE + (alpha,)
    # Pillow's arc uses degrees, 0=3 o'clock, going clockwise
    draw.arc(bbox, start_angle, end_angle, fill=color, width=width)

# Use RGBA for transparency
overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
overlay_draw = ImageDraw.Draw(overlay)

arc_center_y = 380  # center of signal arcs (middle of antenna)

# Inner arcs (closest to antenna)
r1 = 90
overlay_draw.arc([cx - r1, arc_center_y - r1, cx + r1, arc_center_y + r1], 210, 330, fill=(255, 255, 255, 255), width=22)

# Middle arcs
r2 = 150
overlay_draw.arc([cx - r2, arc_center_y - r2, cx + r2, arc_center_y + r2], 215, 325, fill=(255, 255, 255, 200), width=20)

# Outer arcs
r3 = 210
overlay_draw.arc([cx - r3, arc_center_y - r3, cx + r3, arc_center_y + r3], 220, 320, fill=(255, 255, 255, 140), width=18)

img = Image.alpha_composite(img, overlay)

# Save
out_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'app_icon.png')
img.save(out_path, 'PNG')
print(f'Generated {out_path} ({SIZE}x{SIZE})')
