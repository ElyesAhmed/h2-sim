"""Add H2sim attribution beneath exported animations without covering plots.

Run after scientific rendering:
    python tools/brand_storage_animations.py
    python tools/brand_storage_animations.py --directory build/anticline \
        --animations hydrogen_anticline

Uses the existing project logo and software copyright/license attribution.
No scientific data are evaluated. Source frames and playback timing are kept;
MP4 is re-encoded at high quality and GIF colours are palette-quantized.
Repeated runs skip assets whose recorded branded hashes still match.
"""
from pathlib import Path
import argparse
import hashlib
import io
import json
import math
import os
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ANIMATIONS = ('hydrogen_anticline', 'aquifer_storage', 'biochemistry_storage',
              'phreeqc_storage', 'hydrogen_mixing')
SIDECARS = dict(zip(ANIMATIONS, (
    'hydrogen_anticline_provenance.json', 'aquifer_gallery_provenance.json',
    'biochemistry_gallery_provenance.json', 'phreeqc_gallery_provenance.json',
    'hydrogen_mixing_provenance.json')))
LOGO = ROOT/'doc/_static/h2sim-logo-on-dark.svg'
COPYRIGHT = '© 2009–2026 SINTEF Digital, Mathematics & Cybernetics.'
ATTRIBUTION = 'H2sim software • GPL-3.0-or-later  |  sintefmath.github.io/h2-sim'
BACKGROUND = (6, 14, 26)
FOOTER_HEIGHT_RATIO = 0.14


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def footer_height(width):
    """Even height with space below the signature for native player controls."""
    return 2 * math.ceil(round(width * FOOTER_HEIGHT_RATIO) / 2)


def signature_footer(width):
    from PIL import Image, ImageDraw, ImageFont
    import cairosvg
    from matplotlib import font_manager
    height = footer_height(width)
    footer = Image.new('RGB', (width, height), BACKGROUND)
    draw = ImageDraw.Draw(footer)
    draw.line((width*.04, 0, width*.96, 0), fill=(42, 80, 92), width=max(1, round(width/800)))
    logo_width = round(width*.16)
    logo = Image.open(io.BytesIO(cairosvg.svg2png(url=str(LOGO), output_width=logo_width))).convert('RGBA')
    footer.paste(logo, (round(width*.04), round(width*.012)), logo)
    font_path = font_manager.findfont('DejaVu Sans')
    font = ImageFont.truetype(font_path, max(9, round(width*.011)))
    position = (round(width*.235), round(width*.015))
    draw.text(position, COPYRIGHT, font=font, fill=(225, 235, 242))
    draw.text((position[0], position[1]+round(width*.019)), ATTRIBUTION,
              font=font, fill=(170, 199, 214))
    return footer


def append_footer(image, footer):
    from PIL import Image
    source = image.convert('RGB')
    canvas = Image.new('RGB', (source.width, source.height+footer.height), BACKGROUND)
    canvas.paste(source, (0, 0))
    canvas.paste(footer, (0, source.height))
    return canvas


def brand_png(source, target):
    from PIL import Image
    with Image.open(source) as image:
        original = image.convert('RGB')
    canvas = append_footer(original, signature_footer(original.width))
    assert canvas.crop((0, 0, original.width, original.height)).tobytes() == original.tobytes()
    canvas.save(target)
    return {'sourceSize': list(original.size), 'outputSize': list(canvas.size),
            'scientificPixelsPreservedExactly': True}


def brand_gif(source, target):
    from PIL import Image
    frames, durations = [], []
    with Image.open(source) as gif:
        original_size = gif.size
        footer = signature_footer(gif.width)
        for index in range(gif.n_frames):
            gif.seek(index)
            image = append_footer(gif, footer)
            # A single shared palette keeps colours stable during playback.
            if index == 0:
                palette = image.quantize(colors=256)
            frames.append(image.quantize(palette=palette, dither=Image.Dither.NONE))
            durations.append(gif.info.get('duration', 100))
    frames[0].save(target, save_all=True, append_images=frames[1:],
                   duration=durations, loop=0, optimize=False, disposal=2)
    with Image.open(target) as check:
        assert check.n_frames == len(frames), 'Branding changed the GIF frame count.'
        actual = []
        for index in range(check.n_frames):
            check.seek(index)
            actual.append(check.info['duration'])
        assert actual == durations, 'Branding changed GIF playback timing.'
    return {'sourceSize': list(original_size), 'outputSize': list(frames[0].size),
            'frames': len(frames), 'durationMs': sum(durations),
            'playbackTimingPreserved': True}


def brand_mp4(source, target):
    from PIL import Image
    import imageio_ffmpeg
    reader = imageio_ffmpeg.read_frames(str(source), pix_fmt='rgb24')
    metadata = next(reader)
    if metadata.get('audio_codec'):
        raise ValueError('This exporter expects the silent scientific previews.')
    width, height = metadata['size']
    footer = signature_footer(width)
    output_size = (width, height+footer.height)
    writer = imageio_ffmpeg.write_frames(str(target), output_size,
        fps=metadata['fps'], quality=8, codec='libx264', pix_fmt_in='rgb24',
        pix_fmt_out='yuv420p', macro_block_size=2, ffmpeg_log_level='error')
    writer.send(None)
    count = 0
    try:
        for pixels in reader:
            image = Image.frombytes('RGB', (width, height), pixels)
            writer.send(append_footer(image, footer).tobytes())
            count += 1
    finally:
        reader.close()
        writer.close()
    checked_count, seconds = imageio_ffmpeg.count_frames_and_secs(str(target))
    assert checked_count == count, 'Branding changed the MP4 frame count.'
    assert abs(seconds-count/metadata['fps']) < .03, 'Branding changed MP4 playback timing.'
    return {'sourceSize': [width, height], 'outputSize': list(output_size),
            'frames': count, 'fps': metadata['fps'], 'durationSeconds': count/metadata['fps'],
            'playbackTimingPreserved': True}


def write_json(path, data):
    temporary = path.with_suffix(path.suffix+'.tmp')
    temporary.write_text(json.dumps(data, indent=2)+'\n')
    os.replace(temporary, path)


def update_sidecar(path, assets, signature):
    data = json.loads(path.read_text())
    for key in ['assetSha256', 'assetsSha256']:
        for name in data.get(key, {}):
            if name in assets:
                data[key][name] = assets[name]['outputSha256']
    release_prefixes = {
        'hydrogen_mixing_provenance.json': 'hydrogen_mixing_branded',
        'hydrogen_anticline_provenance.json': 'hydrogen_anticline_ten_cycles_branded',
    }
    if path.name in release_prefixes:
        prefix = release_prefixes[path.name]
        mapping = {name: prefix+Path(name).suffix for name in assets}
        mapping[path.name] = prefix+'_provenance.json'
        if data.get('releaseAssetNames') != mapping:
            data.setdefault('originalReleaseAssetNames', data.get('releaseAssetNames',
                            {name: name for name in [*assets, path.name]}))
            data['releaseAssetNames'] = mapping
    data['branding'] = {'signature': signature, 'assets': assets,
                        'scientificDataChanged': False,
                        'layout': 'Attribution band appended below the original frame.'}
    if 'rendering' in data and 'gifDimensionsPixels' in data['rendering']:
        gif = next(v for n, v in assets.items() if n.endswith('.gif'))
        data['rendering']['gifDimensionsPixels'] = gif['outputSize']
    write_json(path, data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=ROOT/'doc/_static/examples')
    parser.add_argument('--animations', nargs='+', choices=ANIMATIONS, default=ANIMATIONS)
    args = parser.parse_args()
    folder = args.directory.resolve()
    manifest_path = folder/'animation_branding_provenance.json'
    signature = {'logo': str(LOGO.relative_to(ROOT)), 'logoSha256': sha(LOGO),
                 'copyright': COPYRIGHT, 'attribution': ATTRIBUTION,
                 'footerHeightRatio': FOOTER_HEIGHT_RATIO}
    record = json.loads(manifest_path.read_text()) if manifest_path.exists() else {'assets': {}}
    if record.get('signature', signature) != signature:
        raise ValueError('The signature changed; regenerate the original scientific exports first.')
    record['signature'] = signature
    record['scientificDataChanged'] = False
    for animation in args.animations:
        for suffix, exporter in [('.png', brand_png), ('.gif', brand_gif), ('.mp4', brand_mp4)]:
            name = animation+suffix
            source = folder/name
            if suffix == '.mp4' and not source.is_file():
                record['assets'].pop(name, None)
                write_json(manifest_path, record)
                print('No MP4 export; GIF and PNG remain available:', animation, flush=True)
                continue
            current = sha(source)
            prior = record['assets'].get(name)
            if prior and current == prior['outputSha256']:
                print('Already branded:', name, flush=True)
                continue
            with tempfile.TemporaryDirectory(prefix='h2sim-brand-', dir=folder) as temp:
                target = Path(temp)/name
                details = exporter(source, target)
                details.update(sourceSha256=current, outputSha256=sha(target))
                os.replace(target, source)
            record['assets'][name] = details
            write_json(manifest_path, record)
            print('Branded:', name, details, flush=True)
        sidecar = folder/SIDECARS[animation]
        if sidecar.exists():
            assets = {n: v for n, v in record['assets'].items() if n.startswith(animation+'.')}
            update_sidecar(sidecar, assets, signature)


if __name__ == '__main__':
    main()
