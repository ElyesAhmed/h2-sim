"""Exercise launcher routing without MATLAB or chemistry dependencies."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.name == "posix" and shutil.which("bash"),
                     "Launcher checks require Linux/WSL Bash.")
class MatlabLauncherTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "checkout with 'quotes'"
        self.root.mkdir()
        source = Path(__file__).resolve().parents[2] / 'run_matlab_h2sim.sh'
        shutil.copy2(source, self.root / source.name)
        self.capture = Path(self.temp.name) / 'args.json'
        self.matlab = Path(self.temp.name) / 'fake matlab'
        self.matlab.write_text(
            '#!/usr/bin/env python3\nimport json, os, sys\n'
            'with open(os.environ["LAUNCH_CAPTURE"], "w") as f:\n'
            '    json.dump({"args": sys.argv[1:], "preloaded": '
            'os.environ.get("TEST_PRELOADED")}, f)\n'
            'sys.exit(int(os.environ.get("TEST_EXIT", "0")))\n'
        )
        self.matlab.chmod(0o755)
        self.env = dict(os.environ, MATLAB_BIN=str(self.matlab),
                        LAUNCH_CAPTURE=str(self.capture))

    def launch(self, *args):
        return subprocess.run(['bash', str(self.root / 'run_matlab_h2sim.sh'), *args],
                              env=self.env, capture_output=True, text=True)

    def captured(self):
        return json.loads(self.capture.read_text())

    def test_core_runs_without_chemistry_checkout(self):
        result = self.launch("disp('core')")
        self.assertEqual(result.returncode, 0, result.stderr)
        data = self.captured()
        self.assertIsNone(data['preloaded'])
        self.assertEqual(data['args'][0], '-batch')
        self.assertIn('startupH2sim;', data['args'][1])
        self.assertNotIn("'phreeqc'", data['args'][1])
        self.assertIn(str(self.root).replace("'", "''"), data['args'][1])
        self.assertFalse((self.root / 'submodules').exists())

    def test_explicit_chemistry_uses_dependency_launcher_and_preserves_exit(self):
        helper = self.root / 'submodules' / 'PhreeqcMatlab' / 'run_matlab.sh'
        helper.parent.mkdir(parents=True)
        helper.write_bytes(b'#!/bin/bash\r\nexport TEST_PRELOADED=yes\r\n'
                           b'exec "$MATLAB_BIN" "$@"\r\n')
        self.env['TEST_EXIT'] = '23'
        result = self.launch('--phreeqc', "disp('chemistry')")
        self.assertEqual(result.returncode, 23, result.stderr)
        data = self.captured()
        self.assertEqual(data['preloaded'], 'yes')
        self.assertIn("startupH2sim('phreeqc', true);", data['args'][1])

    def test_missing_chemistry_launcher_is_actionable(self):
        result = self.launch('--phreeqc', "disp('chemistry')")
        self.assertEqual(result.returncode, 1)
        self.assertIn('git submodule update --init --recursive -- submodules/PhreeqcMatlab',
                      result.stderr)
        self.assertFalse(self.capture.exists())

    def test_core_preserves_matlab_failure(self):
        self.env['TEST_EXIT'] = '19'
        self.assertEqual(self.launch("error('test')").returncode, 19)

    def test_windows_chemistry_does_not_require_linux_preloader(self):
        windows = self.matlab.with_suffix('.exe')
        shutil.copy2(self.matlab, windows)
        self.env['MATLAB_BIN'] = str(windows)
        binary = Path(self.temp.name) / 'bin'
        binary.mkdir()
        converter = binary / 'wslpath'
        converter.write_text('#!/bin/sh\nprintf "C:/fixture\\n"\n')
        converter.chmod(0o755)
        self.env['PATH'] = str(binary) + os.pathsep + self.env['PATH']
        result = self.launch('--phreeqc', "disp('chemistry')")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(self.captured()['preloaded'])
        self.assertIn("startupH2sim('phreeqc', true);", self.captured()['args'][1])

    def test_help_and_invalid_usage_do_not_start_matlab(self):
        self.assertEqual(self.launch('--help').returncode, 0)
        for args in [(), ('--unknown',), ('--phreeqc',), ('a', 'b')]:
            self.assertEqual(self.launch(*args).returncode, 2)
        self.assertFalse(self.capture.exists())
