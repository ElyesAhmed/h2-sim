"""Integrity checks for the published logo/attribution media exports."""
from pathlib import Path
import hashlib
import json
import struct
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT/'doc/_static/examples'
NAMES = ['hydrogen_anticline', 'aquifer_storage', 'biochemistry_storage',
         'phreeqc_storage', 'hydrogen_mixing']


class AnimationBrandingTest(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((FOLDER/'animation_branding_provenance.json').read_text())

    def test_all_animation_assets_have_current_branding_hashes(self):
        expected = {n+s for n in NAMES for s in ['.png', '.gif', '.mp4']}
        self.assertEqual(set(self.record['assets']), expected)
        for name, asset in self.record['assets'].items():
            digest = hashlib.sha256((FOLDER/name).read_bytes()).hexdigest()
            self.assertEqual(digest, asset['outputSha256'], name)
            self.assertEqual(asset['sourceSize'][0], asset['outputSize'][0])
            self.assertGreater(asset['outputSize'][1], asset['sourceSize'][1])

    def test_footer_preserves_frame_counts_and_poster_dimensions(self):
        for name in NAMES:
            movie, gif, poster = [self.record['assets'][name+s] for s in ['.mp4', '.gif', '.png']]
            self.assertTrue(movie['playbackTimingPreserved'])
            self.assertTrue(gif['playbackTimingPreserved'])
            self.assertEqual(movie['frames'], gif['frames'])
            self.assertTrue(poster['scientificPixelsPreservedExactly'])
            payload = (FOLDER/(name+'.png')).read_bytes()
            self.assertEqual(payload[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual(list(struct.unpack('>II', payload[16:24])), poster['outputSize'])

    def test_signature_uses_project_logo_and_existing_attribution(self):
        signature = self.record['signature']
        logo = ROOT/signature['logo']
        self.assertEqual(hashlib.sha256(logo.read_bytes()).hexdigest(), signature['logoSha256'])
        text = ''.join(ET.fromstring(logo.read_text()).itertext())
        self.assertIn('H2sim', text)
        self.assertIn('SINTEF Digital, Mathematics & Cybernetics', signature['copyright'])
        self.assertIn('H2sim software', signature['attribution'])
        self.assertIn('GPL-3.0-or-later', signature['attribution'])


if __name__ == '__main__':
    unittest.main()
