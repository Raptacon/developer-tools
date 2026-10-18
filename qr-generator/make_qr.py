#!/usr/bin/env python3
"""
Raptacon 3200 — Branded QR Code Generator

Generates a QR code with the Raptacon logo embedded in the center,
black modules on a white background, high error correction (so the
logo doesn't break scannability), and an optional caption printed
below for printed materials (flyers, classroom posters, etc.).

USAGE (interactive):
    python make_qr.py

USAGE (non-interactive, e.g. for scripting multiple QRs at once):
    python make_qr.py --url "https://forms.gle/..." --caption "Check In / Out" --output checkin_qr.png

REQUIREMENTS:
    pip install "qrcode[pil]" pillow

BRAND COLOR (Raptacon green): #84EC5C
    Documented here as the canonical reference value — also belongs
    in the team handbook. Not currently used to recolor the QR
    modules themselves (those stay black for scan reliability/
    contrast); it's the logo's own background color already.

LOGO:
    Expects Raptacon_Logo.png in the same directory as this script
    by default (override with --logo). The current logo has a solid
    green background rather than a transparent one — that's fine
    functionally (Level-H error correction tolerates roughly 30% of
    the code being obscured, and the logo here is sized well under
    that), but a transparent, icon-only version (dropping the
    "RAPTACON 3200" wordmark, which is too small to read at this
    size anyway) would look cleaner centered in a QR. Swap the logo
    file later without touching any code here if you make one.
"""

import argparse
import sys
from pathlib import Path

try:
    import qrcode
    from qrcode.constants import ERROR_CORRECT_H
except ImportError:
    print('Missing the qrcode library. Run: pip install "qrcode[pil]" pillow')
    sys.exit(1)

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print('Missing Pillow. Run: pip install "qrcode[pil]" pillow')
    sys.exit(1)

RAPTACON_GREEN = '#84EC5C'
DEFAULT_LOGO_PATH = Path(__file__).parent / 'Raptacon_Logo.png'
LOGO_SIZE_RATIO = 0.28  # logo width as a fraction of QR width — stays well
                        # within Level-H error correction's ~30% tolerance


def build_qr_with_logo(url: str, logo_path: Path) -> Image.Image:
    qr = qrcode.QRCode(
        error_correction=ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color='black', back_color='white').convert('RGBA')

    if logo_path.exists():
        logo = Image.open(logo_path).convert('RGBA')
        qr_w, qr_h = qr_img.size
        logo_target_w = int(qr_w * LOGO_SIZE_RATIO)
        scale = logo_target_w / logo.width
        logo = logo.resize((logo_target_w, int(logo.height * scale)), Image.LANCZOS)

        # White backing square behind the logo, slightly larger than the
        # logo itself, so it reads cleanly against the surrounding modules
        # instead of the QR's black squares touching the logo edge directly.
        pad = int(logo_target_w * 0.08)
        backing = Image.new('RGBA', (logo.width + pad * 2, logo.height + pad * 2), 'white')
        backing.paste(logo, (pad, pad), logo)

        pos = ((qr_w - backing.width) // 2, (qr_h - backing.height) // 2)
        qr_img.paste(backing, pos, backing)
    else:
        print(f'Warning: logo not found at {logo_path} — generating QR without a logo.')

    return qr_img


# Bold-ish fonts to try, in order, before falling back to Pillow's built-in.
# Covers Linux (DejaVu), macOS (Arial/Helvetica), and Windows (arialbd).
_CAPTION_FONT_CANDIDATES = (
    'DejaVuSans-Bold.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
    'arialbd.ttf',
    'Arial.ttf',
)


def _load_caption_font(font_size: int):
    for name in _CAPTION_FONT_CANDIDATES:
        try:
            return ImageFont.truetype(name, font_size)
        except OSError:
            continue
    # Pillow >= 10.1 lets load_default scale; older versions ignore the size
    # and render ~10px, which is too small for print but still legible.
    try:
        return ImageFont.load_default(size=font_size)
    except TypeError:
        return ImageFont.load_default()


def add_caption(img: Image.Image, caption: str) -> Image.Image:
    """Adds a bold caption below the QR on an expanded white canvas."""
    # Start at a size that scales with the QR, then shrink until the caption
    # fits inside the image with a small side margin.
    max_text_w = int(img.width * 0.92)
    font_size = max(24, img.width // 18)
    draw_probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    while True:
        font = _load_caption_font(font_size)
        bbox = draw_probe.textbbox((0, 0), caption, font=font)
        text_w, text_h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        if text_w <= max_text_w or font_size <= 10:
            break
        font_size -= 1

    padding = font_size
    canvas = Image.new('RGBA', (img.width, img.height + text_h + padding * 2), 'white')
    canvas.paste(img, (0, 0), img)

    draw = ImageDraw.Draw(canvas)
    text_x = (img.width - text_w) // 2
    text_y = img.height + padding
    draw.text((text_x, text_y), caption, fill='black', font=font)

    return canvas


def main():
    parser = argparse.ArgumentParser(description='Generate a branded Raptacon 3200 QR code.')
    parser.add_argument('--url', help='The URL the QR code should link to.')
    parser.add_argument('--caption', default=None, help='Optional caption printed below the QR.')
    parser.add_argument('--logo', default=str(DEFAULT_LOGO_PATH), help='Path to the logo image.')
    parser.add_argument('--output', default='raptacon_qr.png', help='Output PNG filename.')
    args = parser.parse_args()

    url = args.url or input('URL for the QR code: ').strip()
    if not url:
        print('A URL is required.')
        sys.exit(1)

    caption = args.caption
    if caption is None:
        caption = input('Optional caption (press Enter to skip): ').strip()

    img = build_qr_with_logo(url, Path(args.logo))
    if caption:
        img = add_caption(img, caption)

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    img.convert('RGB').save(args.output)
    print(f'Saved: {args.output}')


if __name__ == '__main__':
    main()
