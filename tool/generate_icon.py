#!/usr/bin/env python3
"""Generates DARAM's source icon and adaptive-icon layers.

The mark mirrors `lib/app/branding/daram_logo.dart`: a geometric D whose bowl
opens around a mint node. Rendered at 4x and downsampled for clean edges.

After running this script, generate the platform assets with:
    dart run flutter_launcher_icons

That command produces the Android launcher/adaptive/monochrome icons, the iOS
AppIcon set, and the web/PWA icons from the generated source images.
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images"

SCALE = 4
SIZE = 1024


def bezier(p0, p1, p2, p3, steps=120):
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]
        points.append((x, y))
    return points


def draw_mark(image: Image.Image, size: int, left: float, top: float, side: float, stroke_color=(255, 255, 255), node=(46, 211, 163)):
    """Draws the D mark into `image` using normalized coordinates inside a box."""
    draw = ImageDraw.Draw(image)
    s = side
    x0, y0 = left, top

    def p(nx, ny):
        return (x0 + nx * s, y0 + ny * s)

    width = int(0.072 * s)
    radius = width // 2

    def thick_polyline(points):
        for a, b in zip(points, points[1:]):
            draw.line([a, b], fill=stroke_color, width=width)
        for point in points:
            draw.ellipse(
                [point[0] - radius, point[1] - radius, point[0] + radius, point[1] + radius],
                fill=stroke_color,
            )

    # Stem
    thick_polyline([p(0.33, 0.275), p(0.33, 0.725)])

    # Bowl: two smooth cubics meeting at the node on the right shoulder.
    thick_polyline(bezier(p(0.33, 0.275), p(0.68, 0.275), p(0.80, 0.37), p(0.80, 0.5)))
    thick_polyline(bezier(p(0.80, 0.5), p(0.80, 0.63), p(0.68, 0.725), p(0.33, 0.725)))

    # Node
    node_radius = 0.055 * s
    center = p(0.80, 0.5)
    draw.ellipse(
        [center[0] - node_radius, center[1] - node_radius, center[0] + node_radius, center[1] + node_radius],
        fill=node,
    )
    glint = 0.018 * s
    glint_center = p(0.786, 0.482)
    draw.ellipse(
        [glint_center[0] - glint, glint_center[1] - glint, glint_center[0] + glint, glint_center[1] + glint],
        fill=(255, 255, 255, 180),
    )


def gradient_background(size: int) -> Image.Image:
    stops = [
        (0.0, np.array([109, 106, 246], dtype=float)),
        (0.55, np.array([139, 92, 246], dtype=float)),
        (1.0, np.array([91, 87, 232], dtype=float)),
    ]
    yy, xx = np.mgrid[0:size, 0:size]
    t = (xx + yy) / (2 * (size - 1))
    rgb = np.zeros((size, size, 3), dtype=float)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        mask = (t >= t0) & (t <= t1)
        local = np.zeros_like(t)
        local[mask] = (t[mask] - t0) / (t1 - t0)
        for channel in range(3):
            rgb[:, :, channel] = np.where(mask, c0[channel] + (c1[channel] - c0[channel]) * local, rgb[:, :, channel])
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def rounded_mask(size: int, radius_ratio: float = 0.24) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * radius_ratio), fill=255)
    return mask


def full_icon() -> Image.Image:
    s = SIZE * SCALE
    background = gradient_background(s).convert("RGBA")

    # Soft top highlight
    highlight = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    for i in range(120):
        alpha = int(26 * (1 - i / 120))
        hd.rectangle([0, i * s // 480, s, (i + 1) * s // 480], fill=(255, 255, 255, alpha))
    background = Image.alpha_composite(background, highlight)

    draw_mark(background, s, 0, 0, s)
    background.putalpha(rounded_mask(s))
    return background.resize((SIZE, SIZE), Image.LANCZOS)


def foreground() -> Image.Image:
    s = SIZE * SCALE
    image = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    # Adaptive icons crop roughly 25% on each side; keep the mark inside the
    # central 60% safe zone.
    side = s * 0.58
    left = (s - side) / 2
    top = (s - side) / 2
    draw_mark(image, s, left, top, side, stroke_color=(255, 255, 255, 255), node=(46, 211, 163, 255))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def monochrome() -> Image.Image:
    s = SIZE * SCALE
    image = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    side = s * 0.58
    left = (s - side) / 2
    top = (s - side) / 2
    draw_mark(image, s, left, top, side, stroke_color=(255, 255, 255, 255), node=(255, 255, 255, 255))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon = full_icon()
    icon.save(OUT / "app_icon_1024.png", optimize=True)
    icon.resize((512, 512), Image.LANCZOS).save(OUT / "app_icon_512.png", optimize=True)
    foreground().save(OUT / "app_icon_foreground.png", optimize=True)
    monochrome().save(OUT / "app_icon_monochrome.png", optimize=True)
    print(f"wrote source icons to {OUT}; now run: dart run flutter_launcher_icons")


if __name__ == "__main__":
    main()
