"""Builds every EarnLens app icon from the supplied artwork.

Usage (from the project root):

    python tool/generate_app_icons.py "<path to Glossy Purple Growth Finance Icon.png>"

Steps:
1. Enhance the source into a 2048 px master (design/icon/earnlens_icon_master.png):
   - make the tile interior fully opaque;
   - smooth compression mottling in flat gradients (away from edges);
   - upscale 2x with Lanczos in premultiplied space;
   - sharpen luminance only, and only near edges, so colours don't fringe and
     smooth gradients stay clean;
   - add a small vibrance lift;
   - dither before 8-bit output, so gradients don't band.
2. Derive the Android (adaptive + legacy), iOS, web and in-app sizes from the master
   by area-averaged downscaling with a light post-sharpen at small sizes.

Requires Pillow, NumPy and OpenCV (opencv-python).
"""

import os
import sys

import cv2
import numpy as np
from PIL import Image

MASTER_SIZE = 2048
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def p(*parts):
    return os.path.join(ROOT, *parts)


# ---------------------------------------------------------------- enhance


def load_rgba(path):
    im = Image.open(path).convert('RGBA')
    a = np.asarray(im).astype(np.float32) / 255.0
    return a[..., :3], a[..., 3]


def enhance(rgb, alpha):
    # The tile body is drawn at ~99% opacity; make it solid so launchers and
    # dark backgrounds don't show through it. Soft rounded edges keep their
    # anti-aliasing.
    alpha = np.where(alpha > 0.94, 1.0, alpha)

    # 2x Lanczos upscale in premultiplied space (no dark fringes at edges).
    h, w = alpha.shape
    size = (w * 2, h * 2)
    pre = rgb * alpha[..., None]
    pre = cv2.resize(pre, size, interpolation=cv2.INTER_LANCZOS4)
    alpha = np.clip(cv2.resize(alpha, size, interpolation=cv2.INTER_LANCZOS4), 0, 1)
    rgb = np.where(alpha[..., None] > 1e-4, pre / np.maximum(alpha[..., None], 1e-4), 0)
    rgb = np.clip(rgb, 0, 1).astype(np.float32)

    # Where the artwork has real edges (bars, arrow, curves), from lightness.
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    L = lab[..., 0]
    smooth = cv2.GaussianBlur(L, (0, 0), 1.5)
    grad = np.hypot(cv2.Sobel(smooth, cv2.CV_32F, 1, 0), cv2.Sobel(smooth, cv2.CV_32F, 0, 1))
    lo, hi = np.percentile(grad, 75), np.percentile(grad, 97)
    edges = cv2.GaussianBlur(np.clip((grad - lo) / max(hi - lo, 1e-6), 0, 1), (0, 0), 2.0)

    # Clean the smooth gradients: blur only away from edges, which removes
    # compression mottling without the posterised patches a denoiser leaves.
    near = np.clip(cv2.GaussianBlur(edges, (0, 0), 6.0) * 3, 0, 1)[..., None]
    rgb = rgb * near + cv2.GaussianBlur(rgb, (0, 0), 3.0) * (1 - near)

    # Sharpen lightness only, and only at edges, so colours don't fringe.
    lab = cv2.cvtColor(np.clip(rgb, 0, 1).astype(np.float32), cv2.COLOR_RGB2LAB)
    L = lab[..., 0]
    detail = 0.7 * (L - cv2.GaussianBlur(L, (0, 0), 1.0)) + 0.25 * (L - cv2.GaussianBlur(L, (0, 0), 2.5))
    lab[..., 0] = np.clip(L + edges * detail, 0, 100)
    rgb = np.clip(cv2.cvtColor(lab, cv2.COLOR_LAB2RGB), 0, 1)

    # Gentle vibrance: boost low-saturation colours more than saturated ones.
    hsv = cv2.cvtColor(rgb.astype(np.float32), cv2.COLOR_RGB2HSV)
    s = hsv[..., 1]
    hsv[..., 1] = np.clip(s + 0.07 * s * (1 - s), 0, 1)
    rgb = np.clip(cv2.cvtColor(hsv, cv2.COLOR_HSV2RGB), 0, 1)

    # Crisper silhouette: tighten the anti-aliased band of the rounded tile.
    alpha = np.clip((alpha - 0.08) / 0.84, 0, 1)

    master = to_image(rgb, alpha, (MASTER_SIZE, MASTER_SIZE))
    return master


def edge_colour(rgb, alpha):
    """Average colour of the tile just inside its outer edge."""
    h, w = alpha.shape
    ring = np.zeros_like(alpha, dtype=bool)
    m = int(w * 0.03)
    ring[m:m + 6, w // 4:3 * w // 4] = True
    ring[h - m - 6:h - m, w // 4:3 * w // 4] = True
    ring[h // 4:3 * h // 4, m:m + 6] = True
    ring[h // 4:3 * h // 4, w - m - 6:w - m] = True
    ring &= alpha > 0.9
    return rgb[ring].mean(axis=0)


def to_image(rgb, alpha, size):
    """Premultiplied area downscale to [size], dithered 8-bit RGBA."""
    pre = rgb * alpha[..., None]
    if pre.shape[1] != size[0]:
        interp = cv2.INTER_AREA if pre.shape[1] > size[0] else cv2.INTER_LANCZOS4
        pre = cv2.resize(pre, size, interpolation=interp)
        alpha = np.clip(cv2.resize(alpha, size, interpolation=interp), 0, 1)
    rgb = np.where(alpha[..., None] > 1e-4, pre / np.maximum(alpha[..., None], 1e-4), 0)
    rng = np.random.default_rng(7)
    noise = (rng.random(rgb.shape, dtype=np.float32) - 0.5) / 255.0
    out = np.dstack([np.clip(rgb + noise, 0, 1), alpha])
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8))


# ---------------------------------------------------------------- derive


def scaled(master, size, sharpen=True):
    """[master] at [size] px, with a light unsharp mask for small icons."""
    arr = np.asarray(master).astype(np.float32) / 255.0
    rgb, alpha = arr[..., :3], arr[..., 3]
    im = to_image(rgb, alpha, (size, size))
    if sharpen and size <= 256:
        a = np.asarray(im).astype(np.float32) / 255.0
        rgb, alpha = a[..., :3], a[..., 3]
        amount = 0.35 if size <= 96 else 0.25
        rgb = np.clip(rgb + amount * (rgb - cv2.GaussianBlur(rgb, (0, 0), 0.7)), 0, 1)
        im = Image.fromarray((np.dstack([rgb, alpha]) * 255 + 0.5).astype(np.uint8))
    return im


def placed(master, canvas, scale, background=None, sharpen=True):
    """[master] scaled to [scale] of a [canvas] px square, centred."""
    inner = scaled(master, round(canvas * scale), sharpen)
    out = Image.new('RGBA', (canvas, canvas), background or (0, 0, 0, 0))
    off = (canvas - inner.width) // 2
    out.alpha_composite(inner, (off, off))
    return out


def opaque(master, size, background):
    im = Image.new('RGBA', (size, size), background)
    im.alpha_composite(scaled(master, size))
    return im.convert('RGB')


def main(source):
    rgb, alpha = load_rgba(source)
    tile = tuple(int(c * 255 + 0.5) for c in edge_colour(rgb, alpha)) + (255,)
    master = enhance(rgb, alpha)
    os.makedirs(p('design', 'icon'), exist_ok=True)
    master.save(p('design', 'icon', 'earnlens_icon_master.png'), optimize=True)

    # In-app artwork.
    scaled(master, 1024, sharpen=False).save(p('assets', 'images', 'earnlens_app_icon.png'), optimize=True)
    scaled(master, 512, sharpen=False).save(p('assets', 'images', 'earnlens_mark.png'), optimize=True)

    # Android. Adaptive foreground: the 108 dp layer with the tile filling the
    # 72 dp visible area (the artwork stays inside the 66 dp safe zone); the
    # background colour matches the tile's edge so any mask shape is seamless.
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in densities.items():
        res = p('android', 'app', 'src', 'main', 'res', f'mipmap-{name}')
        placed(master, round(108 * f), 72 / 108).save(os.path.join(res, 'ic_launcher_foreground.png'), optimize=True)
        placed(master, round(48 * f), 46 / 48).save(os.path.join(res, 'ic_launcher.png'), optimize=True)
    colors = p('android', 'app', 'src', 'main', 'res', 'values', 'colors.xml')
    with open(colors, encoding='utf-8') as fh:
        xml = fh.read()
    import re
    xml = re.sub(r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}(</color>)',
                 r'\g<1>#%02X%02X%02X\g<2>' % tile[:3], xml)
    with open(colors, 'w', encoding='utf-8', newline='') as fh:
        fh.write(xml)

    # iOS: opaque squares (the system applies its own corner mask).
    ios = p('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    for f in os.listdir(ios):
        if f.startswith('Icon-App-') and f.endswith('.png'):
            size = Image.open(os.path.join(ios, f)).size[0]
            opaque(master, size, tile).save(os.path.join(ios, f), optimize=True)

    # Web.
    web = p('web')
    scaled(master, 192).save(os.path.join(web, 'icons', 'Icon-192.png'), optimize=True)
    scaled(master, 512, sharpen=False).save(os.path.join(web, 'icons', 'Icon-512.png'), optimize=True)
    # Maskable: everything inside the 80% safe circle, on the tile colour.
    placed(master, 192, 0.8, tile).save(os.path.join(web, 'icons', 'Icon-maskable-192.png'), optimize=True)
    placed(master, 512, 0.8, tile, sharpen=False).save(os.path.join(web, 'icons', 'Icon-maskable-512.png'),
                                                       optimize=True)
    scaled(master, 64).save(os.path.join(web, 'favicon.png'), optimize=True)
    print('tile colour #%02X%02X%02X' % tile[:3])


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
