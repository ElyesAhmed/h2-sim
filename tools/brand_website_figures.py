"""Add a discreet H2sim logo/copyright margin to website scientific figures.

Run after figure export: python tools/brand_website_figures.py
PNG plot pixels are preserved; PDF pages retain their vector content. The two
site diagrams receive a vector signature. Animation posters already have their
own attribution and are excluded. Repeated runs skip unchanged branded files.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import io
import json
import os
import tempfile
import xml.etree.ElementTree as ET

from brand_storage_animations import ANIMATIONS, COPYRIGHT

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FOLDER = ROOT/'doc/_static/examples'
LOGO = ROOT/'doc/_static/h2sim-logo-on-light.svg'
LOGO_RATIO = .06
MARGIN_RATIO = .024
FONT_RATIO = .0065
TEXT_COLOR = '#69737b'
SVG = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def margin_height(width, minimum=22):
    return max(minimum, round(width*MARGIN_RATIO))


def brand_png(source, target):
    from PIL import Image, ImageDraw, ImageFont, PngImagePlugin
    import cairosvg
    from matplotlib import font_manager
    with Image.open(source) as image:
        metadata = image.info.copy()
        original = image.convert('RGBA')
    width, height = original.size
    band = margin_height(width)
    canvas = Image.new('RGBA', (width, height+band), 'white')
    canvas.paste(original, (0, 0))
    logo = Image.open(io.BytesIO(cairosvg.svg2png(url=str(LOGO),
        output_width=round(width*LOGO_RATIO)))).convert('RGBA')
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(font_manager.findfont('DejaVu Sans'), max(9, round(width*FONT_RATIO)))
    text_width = draw.textlength(COPYRIGHT, font=font)
    gap = round(width*.0075)
    right = round(width*.985)
    logo_x = round(right-text_width-gap-logo.width)
    canvas.paste(logo, (logo_x, height+(band-logo.height)//2), logo)
    draw.text((right-text_width, height+band/2), COPYRIGHT, fill=TEXT_COLOR,
              font=font, anchor='lm')
    crop = canvas.crop((0, 0, width, height))
    assert crop.tobytes() == original.tobytes(), 'Original plot pixels changed.'
    pnginfo = PngImagePlugin.PngInfo()
    for key, value in metadata.items():
        if isinstance(value, str):
            pnginfo.add_text(key, value)
    options = {key: metadata[key] for key in ('dpi', 'icc_profile') if key in metadata}
    canvas.save(target, pnginfo=pnginfo, **options)
    return {'sourceSize': [width, height], 'outputSize': list(canvas.size),
            'marginHeight': band, 'originalPixelsPreserved': True,
            'originalRegionRgbaSha256': hashlib.sha256(original.tobytes()).hexdigest()}


def brand_pdf(source, target):
    from pypdf import PdfReader, PdfWriter
    from pypdf.generic import RectangleObject
    from reportlab.pdfgen import canvas
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.graphics import renderPDF
    from reportlab.lib.colors import HexColor
    from svglib.svglib import svg2rlg
    from matplotlib import font_manager
    reader = PdfReader(source)
    writer = PdfWriter()
    writer.pdf_header = reader.pdf_header
    dimensions = []
    font_name = 'H2simCopyright'
    if font_name not in pdfmetrics.getRegisteredFontNames():
        pdfmetrics.registerFont(TTFont(font_name, font_manager.findfont('DejaVu Sans')))
    for page in reader.pages:
        assert page.rotation == 0 and list(page.cropbox) == list(page.mediabox)
        assert list(page.mediabox.lower_left) == [0, 0]
        width, height = float(page.mediabox.width), float(page.mediabox.height)
        band = max(7, width*MARGIN_RATIO)
        new = writer.add_blank_page(width=width, height=height+band)
        new.mediabox = RectangleObject([0, -band, width, height])
        new.cropbox = RectangleObject([0, -band, width, height])
        new.merge_page(page, expand=False)
        buffer = io.BytesIO()
        footer = canvas.Canvas(buffer, pagesize=(width, height+band))
        font_size = max(3, width*FONT_RATIO)
        footer.setFont(font_name, font_size)
        footer.setFillColor(HexColor(TEXT_COLOR))
        text_width = pdfmetrics.stringWidth(COPYRIGHT, font_name, font_size)
        logo = svg2rlg(str(LOGO))
        scale = width*LOGO_RATIO/logo.width
        logo.scale(scale, scale)
        logo_height = logo.height*scale
        x = width*.985-text_width-width*.0075-width*LOGO_RATIO
        renderPDF.draw(logo, footer, x, (band-logo_height)/2)
        footer.drawRightString(width*.985, (band-font_size)/2+font_size*.2, COPYRIGHT)
        footer.save()
        new.merge_translated_page(PdfReader(io.BytesIO(buffer.getvalue())).pages[0],
                                  0, -band, expand=False)
        dimensions.append({'sourceSizePoints': [width, height],
                           'outputSizePoints': [width, height+band], 'marginHeightPoints': band})
    if reader.metadata:
        writer.add_metadata({k: str(v) for k, v in reader.metadata.items() if v is not None})
    writer.add_metadata({'/H2simAttribution': COPYRIGHT})
    with target.open('wb') as handle:
        writer.write(handle)
    return {'pages': dimensions, 'vectorContentPreserved': True,
            'originalPdfCoordinatesPreserved': True, 'pdfHeader': reader.pdf_header}


def brand_svg(source, target):
    from PIL import ImageFont
    from matplotlib import font_manager
    tree = ET.parse(source)
    root = tree.getroot()
    x0, y0, width, height = map(float, root.attrib['viewBox'].split())
    assert x0 == 0 and y0 == 0
    original_children = [ET.tostring(child) for child in root]
    band = margin_height(width)
    root.set('viewBox', f'0 0 {width:g} {height+band:g}')
    if 'height' in root.attrib:
        root.set('height', f'{height+band:g}')
    group = ET.SubElement(root, f'{{{SVG}}}g', {'data-h2sim-figure-branding': 'copyright'})
    font_size = max(9, width*FONT_RATIO)
    font = ImageFont.truetype(font_manager.findfont('DejaVu Sans'), round(font_size))
    text_width = font.getlength(COPYRIGHT)
    logo = ET.parse(LOGO).getroot()
    scale = width*LOGO_RATIO/190
    logo_height = 54*scale
    logo_x = width*.985-text_width-width*.0075-width*LOGO_RATIO
    graphic = ET.SubElement(group, f'{{{SVG}}}g', {'transform':
        f'translate({logo_x:g} {height+(band-logo_height)/2:g}) scale({scale:g})'})
    for child in logo:
        graphic.append(copy.deepcopy(child))
    text = ET.SubElement(group, f'{{{SVG}}}text', {'x': f'{width*.985:g}',
        'y': f'{height+band/2+font_size*.35:g}', 'text-anchor': 'end',
        'font-family': 'DejaVu Sans,sans-serif', 'font-size': f'{font_size:g}', 'fill': TEXT_COLOR})
    text.text = COPYRIGHT
    assert [ET.tostring(child) for child in list(root)[:-1]] == original_children
    tree.write(target, encoding='unicode')
    return {'sourceSize': [width, height], 'outputSize': [width, height+band],
            'marginHeight': band, 'originalDiagramElementsPreserved': True}


def save_json(path, data):
    temporary = path.with_suffix(path.suffix+'.tmp')
    temporary.write_text(json.dumps(data, indent=2)+'\n')
    os.replace(temporary, path)


def update_hashes(data, replacements):
    changed = False
    if isinstance(data, dict):
        for key, value in data.items():
            if key in replacements and isinstance(value, str) and len(value) == 64:
                if value != replacements[key]:
                    data[key] = replacements[key]
                    changed = True
            elif isinstance(value, (dict, list)):
                changed = update_hashes(value, replacements) or changed
    elif isinstance(data, list):
        for value in data:
            changed = update_hashes(value, replacements) or changed
    return changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=DEFAULT_FOLDER)
    args = parser.parse_args()
    folder = args.directory.resolve()
    website = folder == DEFAULT_FOLDER.resolve()
    base = folder.parent if website else folder
    excluded = {name+'.png' for name in ANIMATIONS}
    images = sorted(p for p in folder.glob('*.png') if p.name not in excluded)
    targets = [p for image in images for p in [image, image.with_suffix('.pdf')] if p.exists()]
    if website:
        targets += [base/'workflows.svg', base/'reservoir.svg']
    signature = {'logo': str(LOGO.relative_to(ROOT)), 'logoSha256': sha(LOGO),
                 'copyright': COPYRIGHT, 'logoWidthRatio': LOGO_RATIO,
                 'marginWidthRatio': MARGIN_RATIO, 'fontWidthRatio': FONT_RATIO}
    manifest = folder/'figure_branding_provenance.json'
    record = json.loads(manifest.read_text()) if manifest.exists() else {'assets': {}}
    if record.get('signature', signature) != signature:
        raise ValueError('Regenerate original figure exports before changing the signature.')
    record.update(signature=signature, scientificDataChanged=False,
                  baseDirectory='doc/_static' if website else str(folder))
    for source in targets:
        name = str(source.relative_to(base))
        current = sha(source)
        prior = record['assets'].get(name)
        if prior and current == prior['outputSha256']:
            print('Already branded:', name, flush=True)
            continue
        exporter = {'.png': brand_png, '.pdf': brand_pdf, '.svg': brand_svg}[source.suffix]
        with tempfile.TemporaryDirectory(prefix='h2sim-figure-', dir=source.parent) as temp:
            output = Path(temp)/source.name
            details = exporter(source, output)
            details.update(sourceSha256=current, outputSha256=sha(output))
            os.replace(output, source)
        record['assets'][name] = details
        save_json(manifest, record)
        print('Branded:', name, flush=True)
    replacements = {Path(name).name: asset['outputSha256'] for name, asset in record['assets'].items()}
    for sidecar in folder.glob('*provenance.json'):
        if sidecar == manifest:
            continue
        data = json.loads(sidecar.read_text())
        if update_hashes(data, replacements):
            data['figureBranding'] = {'manifest': manifest.name, 'signature': signature,
                                     'scientificDataChanged': False}
            save_json(sidecar, data)


if __name__ == '__main__':
    main()
