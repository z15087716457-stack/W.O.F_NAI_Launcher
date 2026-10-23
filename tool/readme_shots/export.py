"""Export metadata-free README captures and 2000px contact sheets (Pillow)."""
from __future__ import annotations

import argparse
import io
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.dart_tool/readme-shots/out'
DEST = ROOT / 'docs/images/readme'
PANELS = {'blocks-random', 'blocks-sequential', 'blocks-locked', 'translation', 'tag-expansion'}
THEMES = {
    'stars': ('星图', 'Star chart'),
    'circuit': ('像素电路', 'Pixel circuit'),
    'abyss': ('深海', 'Deep sea'),
    'metro': ('地铁', 'Metro'),
    'score': ('乐谱', 'Music score'),
    'moon': ('月相', 'Moon phases'),
}
AGENT_CARDS = [
    'agent-card-diff', 'agent-card-position', 'agent-card-settings',
    'agent-card-gallery', 'agent-card-tags', 'agent-card-ask',
    'agent-card-gate', 'agent-card-images', 'agent-card-thinking',
    'agent-card-promptset',
]
TOTAL_LIMIT = 10_000_000


def trim(image: Image.Image, padding: int = 32) -> Image.Image:
    bg = Image.new('RGB', image.size, image.getpixel((0, 0)))
    diff = ImageChops.difference(image, bg).convert('L').point(lambda x: 255 if x > 16 else 0)
    box = diff.getbbox()
    if not box:
        raise ValueError('Capture is blank')
    l, t, r, b = box
    return image.crop((max(0, l-padding), max(0, t-padding), min(image.width, r+padding), min(image.height, b+padding)))


def content_frame(path: Path, image: Image.Image, padding: int) -> Image.Image:
    """Use render-object geometry, not white-pixel detection on a white panel."""
    frame = json.loads(path.with_suffix('.frame.json').read_text('utf-8'))['box']
    l, t, r, b = frame
    # crop intentionally permits padding outside the original edge.
    panel = image.crop((round(l), round(t), round(r), round(b)))
    result = Image.new('RGB', (panel.width + padding*2, panel.height + padding*2), '#f5f5f7')
    result.paste(panel, (padding, padding))
    return result


def encode(image: Image.Image, name: str, quality: int, agent_panel_width: int = 1600) -> bytes:
    card = name in AGENT_CARDS
    agent_panel = name.startswith('agent-') and not card
    width = 2400 if name.startswith('hero') or name == 'channel-themes' else 1920
    if card:
        width = 920
    elif agent_panel:
        width = agent_panel_width
    elif name.startswith('blocks-') and name not in {'blocks-library', 'blocks-dock'}:
        width = 1600
    limit = 200_000 if card else 700_000 if name.startswith('hero') else 400_000
    image = image.convert('RGB')
    while True:
        content_width = width - 48 if agent_panel else width
        resized = image.resize((content_width, round(image.height * content_width / image.width)), Image.Resampling.LANCZOS)
        if agent_panel:
            padded = Image.new('RGB', (width, resized.height + 48), '#f5f5f7')
            padded.paste(resized, (24, 24))
            resized = padded
        for q in range(quality, 49, -4):
            output = io.BytesIO()
            # Reconstruct pixels: remove all inherited metadata.
            clean = Image.frombytes('RGB', resized.size, resized.tobytes())
            clean.save(output, 'WEBP', quality=q, method=6)
            data = output.getvalue()
            if len(data) <= limit:
                return data
        if card or agent_panel or width == 1600 or name.startswith('hero'):
            raise ValueError(f'{name}: cannot meet byte limit without sacrificing minimum resolution')
        width = max(1600, width - 160)


def font(size: int) -> ImageFont.ImageFont:
    for path in [ROOT / 'assets/fonts/HarmonyOS_Sans_SC_Regular.ttf', Path('C:/Windows/Fonts/msyh.ttc')]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError('A CJK-capable font is required for theme labels')


def collage(panels: list[tuple[str, Image.Image]], columns=3, width=768, ratio=.625, label=50, gap=16) -> Image.Image:
    h = round(width * ratio)
    result = Image.new('RGB', (columns*(width+gap)+gap, math.ceil(len(panels)/columns)*(h+label)+gap), '#edf0f5')
    draw = ImageDraw.Draw(result)
    for i, (name, original) in enumerate(panels):
        pic = original.copy()
        pic.thumbnail((width, h), Image.Resampling.LANCZOS)
        x = gap+(i % columns)*(width+gap)
        y = gap+(i // columns)*(h+label)
        result.paste(pic, (x+(width-pic.width)//2, y+(h-pic.height)//2))
        draw.text((x+8, y+h+8), name, fill='#202734', font=font(28 if label > 50 else 19))
    return result


def agent_contact() -> Image.Image:
    """Zh cards, full aspect ratios, in three compact masonry columns."""
    gap, width, label = 20, 640, 44
    columns: list[list[tuple[str, Image.Image]]] = [[], [], []]
    heights = [gap, gap, gap]
    for i, name in enumerate(AGENT_CARDS):
        with Image.open(DEST / 'zh' / f'{name}.webp') as source:
            image = source.convert('RGB')
        image = image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)
        column = i % 3
        columns[column].append((name, image))
        heights[column] += image.height + label + gap
    result = Image.new('RGB', (2000, max(heights)), '#edf0f5')
    draw = ImageDraw.Draw(result)
    for column, cards in enumerate(columns):
        x, y = gap + column * (width + gap), gap
        for name, image in cards:
            result.paste(image, (x, y))
            draw.text((x + 8, y + image.height + 8), name, fill='#202734', font=font(23))
            y += image.height + label + gap
    return result


def theme_detail(image: Image.Image) -> Image.Image:
    """Join both decoration wings; omit the uninformative middle of the art.

    Each wing retains the source image edge. A narrow gutter makes the
    editorial splice explicit; no decoration is painted or enhanced here.
    """
    wing = round(image.width * .30)
    result = Image.new('RGB', (wing*2+12, image.height), '#edf0f5')
    result.paste(image.crop((0, 0, wing, image.height)), (0, 0))
    result.paste(image.crop((image.width-wing, 0, image.width, image.height)), (wing+12, 0))
    return result


def collect(locale: str) -> list[tuple[str, Image.Image]]:
    folder = SOURCE / locale
    if not folder.exists():
        raise FileNotFoundError(f'Capture folder missing: {folder}')
    outputs = []
    for path in sorted(folder.glob('*.png')):
        if path.stem.startswith('theme-'):
            continue  # Only consume the six explicitly requested theme captures below.
        with Image.open(path) as source:
            image = source.convert('RGB')
        if path.stem in AGENT_CARDS:
            panel = content_frame(path, image, 0)
            if panel.width != 920:
                raise ValueError(f'{locale}/{path.stem}: expected 460 logical px at 2x')
            # Preserve exact width/side margins and add only vertical breathing
            # room, without leaking any part of the preceding user message.
            image = Image.new('RGB', (920, panel.height + 72), '#ffffff')
            image.paste(panel, (0, 36))
        elif path.stem == 'blocks-rules' or path.stem.startswith('agent-'):
            image = content_frame(path, image, 32 if path.stem == 'blocks-rules' else 0)
        elif path.stem in PANELS:
            image = trim(image)
        outputs.append((path.stem, image))
    panels = []
    for name, labels in THEMES.items():
        path = folder / f'theme-{name}.png'
        with Image.open(path) as source:
            image = content_frame(path, source.convert('RGB'), 0)
        panels.append((labels[0 if locale == 'zh' else 1], theme_detail(image)))
    outputs.append(('channel-themes', collage(panels, ratio=.90, label=64)))
    if len(outputs) != 34 + len(AGENT_CARDS):
        raise ValueError(f'{locale}: expected {34 + len(AGENT_CARDS)} scenes, got {len(outputs)}')
    return outputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contact-dir', type=Path, default=ROOT / '.dart_tool/readme-shots')
    parser.add_argument('--scene', action='append', choices=AGENT_CARDS,
                        help='Export only this card (repeatable); preserve other WebPs and refresh contact sheets')
    args = parser.parse_args()
    args.contact_dir.mkdir(parents=True, exist_ok=True)
    existing = DEST / 'manifest.json'
    manifest = {(e['locale'], e['name']): e for e in json.loads(existing.read_text('utf-8'))} if existing.exists() else {}
    captures = {locale: collect(locale) for locale in ['zh', 'en']}
    # Keep existing resolution unless the new card set exceeds the total cap.
    attempts = [(82, 1600)] + [(q, 1200) for q in [82, 78, 74, 70, 66]]
    for quality, agent_panel_width in attempts:
        encoded = {(locale, name): encode(image, name, quality, agent_panel_width)
                   for locale, scenes in captures.items() for name, image in scenes
                   if not args.scene or name in args.scene}
        # Count preserved files too: exporting never silently deletes old images.
        untouched = sum(p.stat().st_size for p in DEST.rglob('*') if p.is_file() and p != existing and (p.parent.name, p.stem) not in encoded)
        # Leave room for the JSON manifest itself.
        if sum(map(len, encoded.values())) + untouched <= TOTAL_LIMIT - 32_000:
            break
    else:
        raise ValueError('Cannot meet combined 10 MB budget')
    for locale, scenes in captures.items():
        for name, _ in scenes:
            if (locale, name) not in encoded:
                continue
            output = DEST / locale / f'{name}.webp'
            output.parent.mkdir(parents=True, exist_ok=True)
            data = encoded[locale, name]
            output.write_bytes(data)
            with Image.open(output) as check:
                if any(k in check.info for k in ('exif', 'icc_profile', 'xmp', 'comment')):
                    raise ValueError(f'Unexpected metadata: {output}')
                w, h = check.size
            manifest[locale, name] = dict(name=name, locale=locale, w=w, h=h, bytes=len(data))
            print(f'{locale}/{name}: {w}x{h}, {len(data)/1024:.1f} KiB')
        overview = collage([(name, Image.open(DEST/locale/f'{name}.webp').convert('RGB')) for name, _ in scenes], columns=4, width=480)
        assert overview.width == 2000
        overview.save(args.contact_dir/f'contact-{locale}.jpg', quality=90)
    agent_contact().save(args.contact_dir / 'contact-agent-cards.jpg', quality=90)
    existing.write_text(json.dumps(sorted(manifest.values(), key=lambda e: (e['locale'], e['name'])), ensure_ascii=False, indent=2)+'\n', 'utf-8')
    total = sum(p.stat().st_size for p in DEST.rglob('*') if p.is_file())
    if total > TOTAL_LIMIT:
        raise ValueError(f'Combined output too large: {total} bytes')
    print(f'TOTAL: {total:,} bytes; quality ceiling {quality}; Agent panels {agent_panel_width}px; metadata/size checks passed')


if __name__ == '__main__':
    main()
