#!/usr/bin/env python3
"""Apply one analog-film grade to a set of photos (Kodak Gold / 1970s European)."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


# Shared roll settings — identical on every frame (Kodak Gold / Cinecittà).
FADE = 0.14
WARMTH = np.array([1.16, 1.00, 0.74], dtype=np.float32)
SHADOW_TINT = np.array([1.02, 0.84, 0.62], dtype=np.float32)
HIGHLIGHT_TINT = np.array([1.10, 1.02, 0.78], dtype=np.float32)
SATURATION = 0.78
CONTRAST = 0.94
GRAIN = 0.062
VIGNETTE = 0.32
GLOW = 0.28
LEAK_STRENGTH = 0.26


def srgb_to_linear(x: np.ndarray) -> np.ndarray:
    return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(x: np.ndarray) -> np.ndarray:
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * np.power(np.clip(x, 0, None), 1 / 2.4) - 0.055)


def luminance(rgb: np.ndarray) -> np.ndarray:
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722


def apply_grade(rgb: np.ndarray) -> np.ndarray:
    lin = srgb_to_linear(np.clip(rgb, 0, 1))
    lin *= WARMTH

    luma = luminance(lin)[..., None]
    shadows = 1.0 - np.clip(luma * 2.2, 0, 1)
    highlights = np.clip((luma - 0.42) * 2.0, 0, 1)
    lin = lin * (1 - shadows) + lin * SHADOW_TINT * shadows
    lin = lin * (1 - highlights) + lin * HIGHLIGHT_TINT * highlights

    # Lifted blacks / cream print fade
    lin = lin * (1.0 - FADE) + FADE * np.array([0.34, 0.28, 0.16], dtype=np.float32)

    # Soft S-curve with compressed highlights
    lin = np.clip(lin, 0, 1)
    lin = lin * lin * (3 - 2 * lin)
    lin = np.clip(lin * 0.98 + 0.04, 0, 1)

    out = linear_to_srgb(lin)
    gray = luminance(out)[..., None]
    out = gray + (out - gray) * SATURATION
    return np.clip(out, 0, 1)


def film_grain(shape: tuple[int, ...], rng: np.random.Generator) -> np.ndarray:
    h, w = shape[:2]
    base = rng.normal(0, 1, (h, w)).astype(np.float32)
    chroma = rng.normal(0, 1, (h, w, 3)).astype(np.float32)
    # Slightly coarser grain via 2x downsample
    small = Image.fromarray(((base + 3) * 40).clip(0, 255).astype(np.uint8), "L")
    small = small.resize((max(1, w // 2), max(1, h // 2)), Image.Resampling.BILINEAR)
    coarse = np.asarray(small.resize((w, h), Image.Resampling.BILINEAR), dtype=np.float32) / 40.0 - 3
    grain = coarse[..., None] * 0.78 + chroma * 0.22
    return grain * GRAIN


def vignette_map(h: int, w: int) -> np.ndarray:
    y, x = np.ogrid[:h, :w]
    cy, cx = (h - 1) / 2, (w - 1) / 2
    dist = np.sqrt(((y - cy) / cy) ** 2 + ((x - cx) / cx) ** 2)
    return np.clip(1.0 - VIGNETTE * np.clip((dist - 0.35) / 0.95, 0, 1) ** 1.6, 0.45, 1.0)


def light_leak(h: int, w: int) -> np.ndarray:
    y, x = np.ogrid[:h, :w]
    # Same leak geometry on every frame — one roll, one camera.
    leak_a = np.exp(-(((x / w) - 0.06) ** 2 * 14 + ((y / h) - 0.04) ** 2 * 8))
    leak_b = np.exp(-(((x / w) - 0.94) ** 2 * 22 + ((y / h) - 0.12) ** 2 * 18)) * 0.55
    strength = (leak_a + leak_b)[..., None] * LEAK_STRENGTH
    color = np.array([1.0, 0.62, 0.24], dtype=np.float32)
    return strength * color


def glow_layer(rgb: np.ndarray) -> np.ndarray:
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB")
    blur = img.filter(ImageFilter.GaussianBlur(radius=max(8, img.width // 90)))
    blurred = np.asarray(blur, dtype=np.float32) / 255.0
    mask = np.clip((luminance(rgb) - 0.55) * 2.4, 0, 1)[..., None]
    return rgb * (1 - mask * GLOW) + np.maximum(rgb, blurred) * (mask * GLOW)


def analog_border(img: Image.Image, cream: tuple[int, int, int] = (236, 220, 188)) -> Image.Image:
    w, h = img.size
    pad = max(18, int(min(w, h) * 0.028))
    canvas = Image.new("RGB", (w + pad * 2, h + pad * 2), cream)
    canvas.paste(img, (pad, pad))
    draw = ImageDraw.Draw(canvas)
    # Hairline inner rebate like a film scan
    draw.rectangle(
        [pad - 2, pad - 2, w + pad + 1, h + pad + 1],
        outline=(210, 190, 155),
        width=1,
    )
    return canvas


def process(path: Path, dest: Path, seed: int = 1978) -> Path:
    src = Image.open(path).convert("RGB")
    rgb = np.asarray(src, dtype=np.float32) / 255.0
    rgb = apply_grade(rgb)
    rgb = glow_layer(rgb)

    rng = np.random.default_rng(seed)
    rgb = np.clip(rgb + film_grain(rgb.shape, rng), 0, 1)
    rgb *= vignette_map(*rgb.shape[:2])[..., None]
    leak = light_leak(*rgb.shape[:2])
    rgb = np.clip(rgb + leak * (1.0 - rgb), 0, 1)

    out = Image.fromarray((rgb * 255).astype(np.uint8), "RGB")
    out = ImageEnhance.Contrast(out).enhance(CONTRAST)
    out = ImageEnhance.Color(out).enhance(0.96)
    out = out.filter(ImageFilter.UnsharpMask(radius=0.8, percent=40, threshold=4))
    out = analog_border(out)

    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest, quality=94, optimize=True, progressive=True)
    return dest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("-o", "--output-dir", type=Path, required=True)
    args = parser.parse_args()

    for i, src in enumerate(args.inputs, start=1):
        dest = args.output_dir / f"retro-{i:02d}.jpg"
        process(src, dest, seed=1978 + i)
        print(dest)


if __name__ == "__main__":
    main()
