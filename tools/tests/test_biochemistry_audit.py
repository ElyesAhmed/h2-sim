# Copyright 2026 H2sim contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check that notice updates preserve source attribution and MATLAB code."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1] / 'audit_mrst_biochemistry.py'
SPEC = importlib.util.spec_from_file_location('audit_mrst_biochemistry', MODULE)
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)


class CopyrightPolicyTest(unittest.TestCase):
    def test_inherited_source_retains_owner_and_code(self):
        source = 'function x = inherited()\nx = 3;\nend\n% Copyright 2009-2024 SINTEF Digital, Mathematics & Cybernetics.\n'
        revised, _ = audit.update_notice(source, True, None)
        self.assertIn('Copyright 2009-2026 SINTEF', revised)
        self.assertNotIn('H2sim contributors', revised)
        self.assertEqual(audit.code_lines(source), audit.code_lines(revised))

    def test_new_file_gets_h2sim_notice_and_keeps_gpl(self):
        source = 'function x = local()\nx = 3;\nend\n%{\nCopyright 2009-2024 SINTEF Digital, Mathematics & Cybernetics.\nThis file is part of The MATLAB Reservoir Simulation Toolbox (MRST).\nMRST is free software: GNU General Public License\n%}\n'
        revised, _ = audit.update_notice(source, False, None)
        self.assertIn('Copyright 2026 H2sim contributors.', revised)
        self.assertIn('GNU General Public License', revised)
        self.assertNotIn('SINTEF', revised)
        self.assertEqual(audit.code_lines(source), audit.code_lines(revised))

    def test_possible_derivative_keeps_original_notice(self):
        source = 'function x = derived()\nx = 3;\nend\n% Copyright 2009-2024 SINTEF Digital, Mathematics & Cybernetics.\n'
        revised, _ = audit.update_notice(source, False, 'modules/source.m')
        self.assertIn('Copyright 2009-2026 SINTEF', revised)
        self.assertIn('Copyright 2026 H2sim contributors.', revised)
        self.assertEqual(audit.code_lines(source), audit.code_lines(revised))
        self.assertEqual(audit.update_notice(revised, False, 'modules/source.m')[0], revised)

    def test_relocated_example_is_not_classified_as_new(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            upstream = root / 'mrst'
            local = root / 'h2sim'
            for repo in (upstream, local):
                repo.mkdir()
                subprocess.run(['git', '-C', str(repo), 'init', '-q'], check=True)
            old = upstream / 'modules/h2-biochem/examples/example.m'
            new = local / 'h2-biochem/examples/validation/example.m'
            for path in (old, new):
                path.parent.mkdir(parents=True)
                path.write_text('function x = example()\nx = 3;\nend\n')
            (upstream / 'modules/h2-biochem/README.md').write_text('Upstream module documentation\n')
            data_readme = local / 'h2-biochem/database/README.md'
            data_readme.parent.mkdir(parents=True)
            data_readme.write_text('Database source attribution\n')
            subprocess.run(['git', '-C', str(upstream), 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(upstream), '-c', 'user.name=Audit Test',
                            '-c', 'user.email=audit@example.invalid', 'commit', '-qm', 'fixture'], check=True)
            subprocess.run(['git', '-C', str(local), 'add', '.'], check=True)
            report = audit.audit(local, upstream)
            records = {record['path']: record for record in report['files']}
            example = records['h2-biochem/examples/validation/example.m']
            self.assertEqual(example['status'], 'relocated-unchanged')
            self.assertEqual(example['upstream'], 'modules/h2-biochem/examples/example.m')
            self.assertEqual(records['h2-biochem/database/README.md']['status'], 'new')
            self.assertEqual(report['upstream_only'], ['modules/h2-biochem/README.md'])
