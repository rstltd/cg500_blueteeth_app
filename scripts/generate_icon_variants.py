"""Generate 6 app icon variants for CG500 BLE GPS tool."""

from PIL import Image, ImageDraw, ImageFont
import math, os

SIZE = 512
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon_drafts')
os.makedirs(OUT_DIR, exist_ok=True)

# Colors
BLUE_TOP = (66, 165, 245)
BLUE_BOT = (21, 101, 192)
DARK_BLUE = (13, 71, 161)
TEAL = (0, 150, 136)
WHITE = (255, 255, 255)
LIGHT_BLUE = (144, 202, 249)

def make_bg(size, c1, c2, radius=110):
    """Create a rounded-rect gradient background."""
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


def variant_1():
    """Concept 1: GPS pin with signal waves — location + wireless."""
    img = make_bg(SIZE, BLUE_TOP, BLUE_BOT)
    d = ImageDraw.Draw(img)
    cx = SIZE // 2

    # Location pin body (teardrop shape using circle + triangle)
    pin_top = 100
    pin_r = 95
    pin_cy = pin_top + pin_r
    d.ellipse([cx - pin_r, pin_top, cx + pin_r, pin_top + 2 * pin_r], fill=WHITE)
    # Triangle bottom of pin
    d.polygon([(cx - 60, pin_cy + 50), (cx + 60, pin_cy + 50), (cx, pin_cy + 160)], fill=WHITE)
    # Inner circle (hollow center)
    inner_r = 45
    d.ellipse([cx - inner_r, pin_cy - inner_r, cx + inner_r, pin_cy + inner_r], fill=BLUE_BOT)

    # Signal arcs below the pin
    arc_cy = 400
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i, (r, alpha) in enumerate([(50, 255), (90, 180), (130, 120)]):
        od.arc([cx - r, arc_cy - r // 2, cx + r, arc_cy + r // 2], 200, 340, fill=(255, 255, 255, alpha), width=12)
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '1_gps_pin_signal.png'))
    print("1: GPS pin + signal waves")


def variant_2():
    """Concept 2: Gear with wireless — device configuration tool."""
    img = make_bg(SIZE, BLUE_TOP, DARK_BLUE)
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2 + 10

    # Simplified gear (circle with rectangular teeth)
    gear_r = 130
    d.ellipse([cx - gear_r, cy - gear_r, cx + gear_r, cy + gear_r], fill=WHITE)
    # Inner circle
    inner_r = 75
    d.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=DARK_BLUE)

    # Gear teeth (8 rectangles around the circle)
    tooth_w, tooth_h = 36, 40
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        tx = cx + (gear_r + tooth_h // 2 - 10) * math.cos(rad) - tooth_w // 2
        ty = cy + (gear_r + tooth_h // 2 - 10) * math.sin(rad) - tooth_h // 2
        # Simple rectangles (not rotated, approximation)
        points = []
        for dx, dy in [(-tooth_w//2, -tooth_h//2), (tooth_w//2, -tooth_h//2),
                       (tooth_w//2, tooth_h//2), (-tooth_w//2, tooth_h//2)]:
            rx = dx * math.cos(rad) - dy * math.sin(rad)
            ry = dx * math.sin(rad) + dy * math.cos(rad)
            px = cx + (gear_r + 5) * math.cos(rad) + rx
            py = cy + (gear_r + 5) * math.sin(rad) + ry
            points.append((px, py))
        d.polygon(points, fill=WHITE)

    # WiFi-like signal icon inside the gear
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for r, alpha in [(30, 255), (55, 200), (80, 150)]:
        od.arc([cx - r, cy - r - 10, cx + r, cy + r - 10], 220, 320, fill=(255, 255, 255, alpha), width=10)
    od.ellipse([cx - 8, cy + 15, cx + 8, cy + 31], fill=(255, 255, 255, 255))
    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '2_gear_wireless.png'))
    print("2: Gear + wireless signal")


def variant_3():
    """Concept 3: Two connected nodes — phone ↔ device BLE link."""
    img = make_bg(SIZE, (33, 150, 243), DARK_BLUE)
    d = ImageDraw.Draw(img)

    # Left node (phone icon - rounded rect)
    d.rounded_rectangle([80, 170, 180, 340], radius=15, fill=WHITE)
    d.rounded_rectangle([92, 185, 168, 310], radius=5, fill=(33, 150, 243))
    d.ellipse([120, 315, 140, 335], fill=(33, 150, 243))

    # Right node (device/tracker - square with rounded corners)
    d.rounded_rectangle([332, 180, 432, 330], radius=20, fill=WHITE)
    d.ellipse([362, 225, 402, 265], fill=(33, 150, 243))  # lens/sensor
    d.rounded_rectangle([355, 285, 409, 300], radius=3, fill=(33, 150, 243))  # label

    # Connection line with dots (BLE link)
    d.line([(180, 255), (332, 255)], fill=WHITE, width=6)
    for x in [210, 240, 270, 300]:
        d.ellipse([x - 5, 250, x + 5, 260], fill=LIGHT_BLUE)

    # BLE text/label at bottom
    d.rounded_rectangle([170, 370, 342, 410], radius=15, fill=WHITE)
    # Small "BLE" dots inside
    for x in [220, 256, 292]:
        d.ellipse([x - 8, 382, x + 8, 398], fill=(33, 150, 243))

    img.save(os.path.join(OUT_DIR, '3_connected_nodes.png'))
    print("3: Phone-device connection")


def variant_4():
    """Concept 4: Satellite dish — GPS data relay."""
    img = make_bg(SIZE, BLUE_TOP, BLUE_BOT)
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2 + 20

    # Dish (arc)
    dish_r = 150
    d.arc([cx - dish_r, cy - dish_r + 40, cx + dish_r, cy + dish_r + 40], 200, 340, fill=WHITE, width=24)

    # Support arm (diagonal line from dish center to base)
    d.line([(cx, cy + 30), (cx - 80, cy + 150)], fill=WHITE, width=16)
    d.line([(cx, cy + 30), (cx + 80, cy + 150)], fill=WHITE, width=16)

    # Base
    d.line([(cx - 110, cy + 150), (cx + 110, cy + 150)], fill=WHITE, width=16)

    # Signal dot at focus point
    d.ellipse([cx - 16, cy - 10, cx + 16, cy + 22], fill=WHITE)

    # Signal waves going up-right
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i, (r, alpha) in enumerate([(40, 255), (70, 180), (100, 120)]):
        offset_x = cx + 30
        offset_y = cy - 50
        od.arc([offset_x - r, offset_y - r, offset_x + r, offset_y + r], 250, 340, fill=(255, 255, 255, alpha), width=12)

    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '4_satellite_dish.png'))
    print("4: Satellite dish")


def variant_5():
    """Concept 5: Simplified 'B' letter + waves — Bluetooth inspired (not trademarked)."""
    img = make_bg(SIZE, (25, 118, 210), DARK_BLUE)
    d = ImageDraw.Draw(img)
    cx = SIZE // 2

    # Stylized B shape (two bumps on the right, straight left)
    # Using rounded rectangles and circles
    d.rounded_rectangle([180, 110, 220, 400], radius=10, fill=WHITE)  # vertical bar

    # Top bump
    d.pieslice([200, 110, 340, 260], 270, 90, fill=WHITE)
    d.pieslice([210, 125, 320, 245], 270, 90, fill=(25, 118, 210))

    # Bottom bump (slightly larger)
    d.pieslice([200, 240, 350, 400], 270, 90, fill=WHITE)
    d.pieslice([210, 255, 330, 385], 270, 90, fill=(25, 118, 210))

    # Signal arcs on the right
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    arc_cx = 340
    arc_cy = 255
    for r, alpha in [(40, 255), (70, 180), (100, 120)]:
        od.arc([arc_cx - r, arc_cy - r, arc_cx + r, arc_cy + r], 300, 60, fill=(255, 255, 255, alpha), width=12)

    img = Image.alpha_composite(img, overlay)
    img.save(os.path.join(OUT_DIR, '5_stylized_b_waves.png'))
    print("5: Stylized B + waves")


def variant_6():
    """Concept 6: Hexagonal chip with signal — IoT/tech feel."""
    img = make_bg(SIZE, (30, 136, 229), DARK_BLUE)
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2

    # Hexagon
    hex_r = 140
    points = []
    for i in range(6):
        angle = math.radians(60 * i - 90)
        points.append((cx + hex_r * math.cos(angle), cy + hex_r * math.sin(angle)))
    d.polygon(points, fill=WHITE)

    # Inner hexagon (hollow)
    hex_r2 = 105
    points2 = []
    for i in range(6):
        angle = math.radians(60 * i - 90)
        points2.append((cx + hex_r2 * math.cos(angle), cy + hex_r2 * math.sin(angle)))
    d.polygon(points2, fill=(30, 136, 229))

    # Circuit traces from hexagon vertices
    for i in range(6):
        angle = math.radians(60 * i - 90)
        x1 = cx + hex_r * math.cos(angle)
        y1 = cy + hex_r * math.sin(angle)
        x2 = cx + (hex_r + 35) * math.cos(angle)
        y2 = cy + (hex_r + 35) * math.sin(angle)
        d.line([(x1, y1), (x2, y2)], fill=WHITE, width=8)
        d.ellipse([x2 - 8, y2 - 8, x2 + 8, y2 + 8], fill=WHITE)

    # Signal icon inside hexagon
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for r, alpha in [(25, 255), (50, 200), (75, 140)]:
        od.arc([cx - r, cy - r - 15, cx + r, cy + r - 15], 220, 320, fill=(255, 255, 255, alpha), width=10)
    od.ellipse([cx - 8, cy + 10, cx + 8, cy + 26], fill=(255, 255, 255, 255))
    img = Image.alpha_composite(img, overlay)

    img.save(os.path.join(OUT_DIR, '6_hex_chip_signal.png'))
    print("6: Hexagonal chip + signal")


if __name__ == '__main__':
    variant_1()
    variant_2()
    variant_3()
    variant_4()
    variant_5()
    variant_6()
    print(f"\nAll variants saved to {OUT_DIR}")
