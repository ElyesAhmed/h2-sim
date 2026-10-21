"""Keep the website's introductory notebook executable code aligned with MATLAB."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
EXAMPLE = ROOT / 'h2-biochem/examples/1D_validation/simple1DBacterialExampleMetacet.m'
NOTEBOOK = EXAMPLE.parent / 'notebooks' / (EXAMPLE.stem + '.ipynb')


def executable_lines(source):
    """Ignore MATLAB documentation, retaining executable text and string values."""
    lines = []
    in_comment = False
    for line in source.splitlines():
        stripped = line.strip()
        if stripped == '%{':
            in_comment = True
        elif stripped == '%}':
            in_comment = False
        elif stripped and not in_comment and not stripped.startswith('%'):
            lines.append(stripped)
    return lines


class IntroNotebookTest(unittest.TestCase):
    def test_published_notebook_executes_the_current_example(self):
        notebook = json.loads(NOTEBOOK.read_text(encoding='utf-8'))
        code = []
        for cell in notebook['cells']:
            if cell['cell_type'] == 'code':
                source = cell.get('source', [])
                code.append(source if isinstance(source, str) else ''.join(source))
        self.assertEqual(executable_lines(EXAMPLE.read_text(encoding='utf-8')),
                         executable_lines('\n'.join(code)))
