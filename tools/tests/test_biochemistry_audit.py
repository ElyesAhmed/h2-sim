# Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.
#
# This file is part of h2sim.
#
# h2sim is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# h2sim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
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
        self.assertIn(audit.NOTICE.strip(), revised)
        self.assertIn('GNU General Public License', revised)
        self.assertIn('Copyright 2009-2026 SINTEF', revised)
        self.assertEqual(audit.update_notice(revised, False, None)[0], revised)
        self.assertEqual(audit.code_lines(source), audit.code_lines(revised))

    def test_possible_derivative_keeps_original_notice(self):
        source = 'function x = derived()\nx = 3;\nend\n% Copyright 2009-2024 SINTEF Digital, Mathematics & Cybernetics.\n'
        revised, _ = audit.update_notice(source, False, 'modules/source.m')
        self.assertIn('Copyright 2009-2026 SINTEF', revised)
        self.assertIn(audit.NOTICE.strip(), revised)
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
