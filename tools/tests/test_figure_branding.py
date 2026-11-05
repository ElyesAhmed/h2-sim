"""Published scientific figures retain small, current attribution margins."""
from pathlib import Path
import hashlib
import json
import math
import struct
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
STATIC = ROOT/'doc/_static'
FOLDER = STATIC/'examples'


class FigureBrandingTest(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((FOLDER/'figure_branding_provenance.json').read_text())

    def test_all_plots_matching_pdfs_and_diagrams_have_current_hashes(self):
        animations = json.loads((FOLDER/'animation_branding_provenance.json').read_text())
        excluded = {n for n in animations['assets'] if n.endswith('.png')}
        expected = set()
        for image in FOLDER.glob('*.png'):
            if image.name in excluded:
                continue
            expected.add('examples/'+image.name)
            if image.with_suffix('.pdf').exists():
                expected.add('examples/'+image.with_suffix('.pdf').name)
        expected.update(['workflows.svg', 'reservoir.svg'])
        self.assertEqual(set(self.record['assets']), expected)
        for name, asset in self.record['assets'].items():
            self.assertEqual(hashlib.sha256((STATIC/name).read_bytes()).hexdigest(),
                             asset['outputSha256'], name)
        self.assertLessEqual(self.record['signature']['logoWidthRatio'], .07)

    def test_png_margins_are_small_and_do_not_replace_the_plot_region(self):
        for name, asset in self.record['assets'].items():
            if not name.endswith('.png'):
                continue
            payload = (STATIC/name).read_bytes()
            dimensions = list(struct.unpack('>II', payload[16:24]))
            self.assertEqual(dimensions, asset['outputSize'])
            self.assertEqual(dimensions[0], asset['sourceSize'][0])
            self.assertEqual(dimensions[1], asset['sourceSize'][1]+asset['marginHeight'])
            self.assertLessEqual(asset['marginHeight'], max(22, math.ceil(dimensions[0]*.025)))
            self.assertTrue(asset['originalPixelsPreserved'])
            self.assertEqual(len(asset['originalRegionRgbaSha256']), 64)

    def test_pdf_and_svg_attribution_retain_original_coordinate_layouts(self):
        for name, asset in self.record['assets'].items():
            if name.endswith('.pdf'):
                payload = (STATIC/name).read_bytes()
                self.assertTrue(payload.startswith(asset['pdfHeader'].encode()))
                self.assertIn(b'/H2simAttribution', payload)
                self.assertTrue(asset['vectorContentPreserved'])
                self.assertTrue(asset['originalPdfCoordinatesPreserved'])
            elif name.endswith('.svg'):
                root = ET.parse(STATIC/name).getroot()
                groups = [g for g in root.iter() if g.get('data-h2sim-figure-branding')]
                self.assertEqual(len(groups), 1)
                self.assertIn(self.record['signature']['copyright'], ''.join(groups[0].itertext()))
                self.assertEqual(list(map(float, root.get('viewBox').split()))[2:], asset['outputSize'])
                self.assertTrue(asset['originalDiagramElementsPreserved'])


if __name__ == '__main__':
    unittest.main()
