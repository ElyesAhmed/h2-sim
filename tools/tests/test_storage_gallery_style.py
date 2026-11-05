"""Contracts for real-state sampling, shared colours and recorded diagnostics."""
import base64
import csv
import gzip
import importlib.util
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('storage_gallery_style', ROOT/'tools/storage_gallery_style.py')
style = importlib.util.module_from_spec(spec)
spec.loader.exec_module(style)


class StorageGalleryStyleTest(unittest.TestCase):
    def test_keeps_stage_ends_on_irregular_times(self):
        times = [0.01, 0.02, 0.05, 1, 3, 4, 9, 11]
        phases = ['Build', 'Build', 'Build', 'Idle', 'Inject', 'Inject', 'Withdraw', 'Withdraw']
        selected = style.select_state_indices(times, phases, 5)
        self.assertEqual(selected, [0, 2, 3, 5, 7])
        self.assertTrue(all(times[i] in times for i in selected))

    def test_does_not_add_initial_or_interpolated_states(self):
        times = [0.01, 0.02, 2, 5, 10]
        self.assertEqual(style.select_state_indices(times, ['Build']*5, 10), list(range(5)))
        self.assertEqual(times[style.select_state_indices(times, ['Build']*5, 2)[0]], 0.01)

    def test_rejects_invalid_times_or_too_few_frames(self):
        for times, phases in [([], []), ([1], []), ([1, 1], ['a', 'b']),
                              ([1, float('nan')], ['a', 'b'])]:
            with self.assertRaises(ValueError):
                style.select_state_indices(times, phases)
        with self.assertRaises(ValueError):
            style.select_state_indices([1, 2, 3, 4], ['a', 'b', 'c', 'd'], 2)

    def test_labels_pre_cycle_shut_in_from_control(self):
        self.assertEqual(style.storage_operation('cushion', True, 1), 'Cushion injection')
        self.assertEqual(style.storage_operation('shut', False, 0), 'Shut-in')
        self.assertEqual(style.storage_operation('charge', True, 1), 'Injection')
        self.assertEqual(style.storage_operation('discharge', True, -1), 'Withdrawal')

    def test_palette_matches_matlab_reference(self):
        source = (ROOT/'h2-store/utils/h2simStoragePlotStyle.m').read_text()
        matrix = re.search(r'anchors\s*=\s*\[(.*?)\];', source, re.S).group(1)
        numbers = [float(x) for x in re.findall(r'\d+(?:\.\d+)?', matrix)]
        self.assertEqual(numbers, [x for rgb in style.SATURATION_ANCHORS for x in rgb])

    def test_reaction_histories_retain_their_normalization(self):
        with (ROOT/'doc/_static/field2d/histories.csv').open() as handle:
            rows = list(csv.DictReader(handle))
        previous = {}
        for row in rows:
            key = row['workflow']
            consumed = float(row['consumed_h2_mol'])
            reactions = sum(float(row[name]) for name in ['met_h2_mol', 'ace_h2_mol', 'srb_h2_mol'])
            self.assertAlmostEqual(consumed, reactions, places=6)
            expected = 100 * consumed / float(row['cumulative_injected_h2_mol'])
            self.assertAlmostEqual(float(row['loss_percent']), expected, places=8)
            self.assertGreaterEqual(consumed + 1e-7, previous.get(key, 0))
            previous[key] = consumed

    def test_movie_and_explorer_use_the_same_selected_times(self):
        folder = ROOT/'doc/_static/field2d'
        record = json.loads((folder/'provenance.json').read_text())
        with gzip.open(folder/'frames.json.gz', 'rt') as handle:
            frames = json.load(handle)
        times = record['animation_times_days']
        self.assertEqual(len(times), record['frames'])
        self.assertEqual(len(times), len(record['animation_source_state_indices_zero_based']))
        self.assertEqual([round(t, 4) for t in times], frames['times'])
        self.assertAlmostEqual(times[-1], record['end_days'])
        for run in frames['runs'].values():
            self.assertEqual(len(run), 4)
            for encoded in run:
                self.assertEqual(len(base64.b64decode(encoded)), len(times)*record['cells'])
        for variable in frames['variables']:
            self.assertEqual(len(variable['palette']), 256)


if __name__ == '__main__':
    unittest.main()
