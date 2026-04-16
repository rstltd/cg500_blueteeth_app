"""Generate refined icon variants based on concepts #1 (GPS pin + signal)
and #3 (phone-device connection). 3 variations each = 6 total."""

from PIL import Image, ImageDraw
import math, os

SIZE = 512
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon_drafts_v2')
os.makedirs(OUT_DIR, exist_ok=True)

BLUE_TOP = (66, 165, 245)
BLUE_BOT = (21, 101, 192)
DARK_BLUE = (13, 71, 161)
WHITE = (255, 255, 255)
LIGHT_BLUE = (144, 202, 249)


def make_bg(size, c1, c2, radius=110):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg = Image.new('RGB', (size, size))
    d = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / size
        color = tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))
        d.line([(0, y), (size, y)], fill=color)
    mask = Image.new('L', (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
    img.paste(bg, mask=mask)
    return img


# ===== CONCEPT 1 VARIATIONS: GPS Pin + Signal =====

def pin_1a():
    """1A: Larger pin centered, signal arcs wrap around the pin bottom."""
    img = make_bg(SIZE, BLUE_TOP, BLUE_BOT)
    d = ImageDraw.Draw(img)
    cx = SIZE // 2

    # Pin body
    pin_r = 105
    pin_cy = 180
    d.ellipse([cx - pin_r, pin_cy - pin_r, cx + pin_r, pin_cy + pin_r], fill=WHITE)
    d.polygon([(cx - 65, pin_cy + 65), (cx + 65, pin_cy + 65), (cx, pin_cy + 185)], fill=WHITE)
    inner_r = 50
    d.ellipse([cx - inner_r, pin_cy - inner_r, cx + inner_r, pin_cy + inner_r], fill=BLUE_BOT)

    # Small dot in center of pin
    dot_r = 15
    d.ellipse([cx - dot_r, pin_cy - dot_r, cx + dot_r, pin_cy + dot_r], fill=WHITE)

    # Signal arcs radiating below pin
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    arc_cy = 410
    for r, w, alpha in [(55, 14, 255), (95, 13, 190), (135, 12, 130)]:
        od.arc([cx - r, arc_cy - r // 2, cx + r, arc_cy + r // 2],
               195, 345, fill=(255, 255, 255, alpha), width=w)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '1a_pin_centered.png'))


def pin_1b():
    """1B: Pin with circular ripple rings (like a radar ping)."""
    img = make_bg(SIZE, (33, 150, 243), DARK_BLUE)
    d = ImageDraw.Draw(img)
    cx = SIZE // 2

    # Pin
    pin_r = 90
    pin_cy = 165
    d.ellipse([cx - pin_r, pin_cy - pin_r, cx + pin_r, pin_cy + pin_r], fill=WHITE)
    d.polygon([(cx - 55, pin_cy + 55), (cx + 55, pin_cy + 55), (cx, pin_cy + 155)], fill=WHITE)
    inner_r = 42
    d.ellipse([cx - inner_r, pin_cy - inner_r, cx + inner_r, pin_cy + inner_r], fill=(33, 150, 243))

    # Concentric circular ripples below (like dropping into water)
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    ripple_cy = 390
    for r, alpha in [(40, 220), (80, 160), (120, 100), (160, 60)]:
        od.ellipse([cx - r, ripple_cy - r // 3, cx + r, ripple_cy + r // 3],
                   outline=(255, 255, 255, alpha), width=8)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '1b_pin_ripples.png'))


def pin_1c():
    """1C: Minimal pin outline with bold signal arcs on both sides."""
    img = make_bg(SIZE, BLUE_TOP, (21, 101, 192))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2 - 10

    # Pin outline only (not filled)
    pin_r = 85
    pin_cy = cy - 20
    d.ellipse([cx - pin_r, pin_cy - pin_r, cx + pin_r, pin_cy + pin_r],
              outline=WHITE, width=16)
    d.polygon([(cx - 45, pin_cy + 60), (cx + 45, pin_cy + 60), (cx, pin_cy + 145)],
              outline=WHITE, fill=None)
    # Fill triangle manually with lines
    for y_off in range(60, 145):
        ratio = (y_off - 60) / 85.0
        half_w = int(45 * (1 - ratio))
        if half_w > 0:
            d.line([(cx - half_w, pin_cy + y_off), (cx + half_w, pin_cy + y_off)],
                   fill=WHITE, width=1)
    # Outline triangle border
    d.line([(cx - 45, pin_cy + 60), (cx, pin_cy + 145)], fill=WHITE, width=16)
    d.line([(cx + 45, pin_cy + 60), (cx, pin_cy + 145)], fill=WHITE, width=16)

    # Center dot
    dot_r = 22
    d.ellipse([cx - dot_r, pin_cy - dot_r, cx + dot_r, pin_cy + dot_r], fill=WHITE)

    # Bold signal arcs on both sides
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    # Left arcs
    for r, alpha in [(110, 230), (150, 160), (190, 90)]:
        od.arc([cx - r - 40, cy - r, cx - 40 + r, cy + r],
               150, 210, fill=(255, 255, 255, alpha), width=14)
    # Right arcs
    for r, alpha in [(110, 230), (150, 160), (190, 90)]:
        od.arc([cx + 40 - r, cy - r, cx + 40 + r, cy + r],
               330, 30, fill=(255, 255, 255, alpha), width=14)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '1c_pin_outline_bilateral.png'))


# ===== CONCEPT 3 VARIATIONS: Phone-Device Connection =====

def conn_3a():
    """3A: Simplified phone + device with BLE arc between them."""
    img = make_bg(SIZE, (33, 150, 243), DARK_BLUE)
    d = ImageDraw.Draw(img)
    cy = SIZE // 2

    # Phone (left) - tall rounded rect
    d.rounded_rectangle([70, 150, 190, 362], radius=18, fill=WHITE)
    d.rounded_rectangle([84, 168, 176, 330], radius=6, fill=(33, 150, 243))
    d.ellipse([118, 338, 142, 355], fill=(33, 150, 243))  # home button

    # Device (right) - square rounded rect with antenna nub
    d.rounded_rectangle([322, 175, 442, 337], radius=22, fill=WHITE)
    # Screen area
    d.rounded_rectangle([338, 195, 426, 295], radius=8, fill=(33, 150, 243))
    # LED indicator
    d.ellipse([370, 305, 394, 322], fill=(76, 175, 80))  # green LED
    # Small antenna on top
    d.line([(382, 175), (382, 148)], fill=WHITE, width=8)
    d.ellipse([375, 138, 389, 152], fill=WHITE)

    # BLE connection arc between devices
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    arc_cx = SIZE // 2
    for r, alpha in [(60, 240), (90, 170), (120, 100)]:
        od.arc([arc_cx - r, cy - r - 20, arc_cx + r, cy + r - 20],
               240, 300, fill=(255, 255, 255, alpha), width=10)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '3a_phone_device_arc.png'))


def conn_3b():
    """3B: Abstract two circles connected by dashed line with signal."""
    img = make_bg(SIZE, BLUE_TOP, BLUE_BOT)
    d = ImageDraw.Draw(img)
    cy = SIZE // 2

    # Left circle (phone abstraction)
    left_cx = 150
    cr = 65
    d.ellipse([left_cx - cr, cy - cr, left_cx + cr, cy + cr], fill=WHITE)
    # Phone icon inside
    d.rounded_rectangle([left_cx - 20, cy - 35, left_cx + 20, cy + 35],
                        radius=6, fill=BLUE_BOT)

    # Right circle (device abstraction)
    right_cx = 362
    d.ellipse([right_cx - cr, cy - cr, right_cx + cr, cy + cr], fill=WHITE)
    # GPS/satellite icon inside
    d.ellipse([right_cx - 18, cy - 18, right_cx + 18, cy + 18], fill=BLUE_BOT)
    d.ellipse([right_cx - 8, cy - 8, right_cx + 8, cy + 8], fill=WHITE)

    # Connection line
    d.line([(left_cx + cr, cy), (right_cx - cr, cy)], fill=WHITE, width=6)

    # Signal dots on connection line
    for x in range(left_cx + cr + 20, right_cx - cr - 10, 25):
        d.ellipse([x - 5, cy - 5, x + 5, cy + 5], fill=LIGHT_BLUE)

    # Signal arcs above the connection
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    arc_cx = SIZE // 2
    for r, alpha in [(35, 255), (60, 180), (85, 110)]:
        od.arc([arc_cx - r, cy - 100 - r, arc_cx + r, cy - 100 + r],
               210, 330, fill=(255, 255, 255, alpha), width=10)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '3b_abstract_circles.png'))


def conn_3c():
    """3C: Phone silhouette sending signal to a small device chip."""
    img = make_bg(SIZE, (25, 118, 210), DARK_BLUE)
    d = ImageDraw.Draw(img)

    # Phone silhouette (left, large, partial - like extending from the edge)
    d.rounded_rectangle([40, 120, 210, 392], radius=22, fill=WHITE)
    d.rounded_rectangle([56, 142, 194, 355], radius=8, fill=(25, 118, 210))
    # Status bar dots on phone
    for y in [160, 180, 200, 220]:
        d.rounded_rectangle([72, y, 178, y + 12], radius=3, fill=(66, 165, 245))

    # Small device (right, compact)
    d.rounded_rectangle([340, 195, 440, 310], radius=16, fill=WHITE)
    d.rounded_rectangle([352, 210, 428, 275], radius=6, fill=(25, 118, 210))
    # Blinking indicator
    d.ellipse([378, 282, 400, 300], fill=(76, 175, 80))

    # Wireless signal arcs from phone to device
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    sig_cx = 275
    sig_cy = SIZE // 2
    for r, alpha in [(30, 255), (55, 200), (80, 145), (105, 90)]:
        od.arc([sig_cx - r, sig_cy - r, sig_cx + r, sig_cy + r],
               300, 60, fill=(255, 255, 255, alpha), width=10)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '3c_phone_to_device.png'))


if __name__ == '__main__':
    pin_1a()
    pin_1b()
    pin_1c()
    conn_3a()
    conn_3b()
    conn_3c()
    print("All 6 refined variants generated.")
