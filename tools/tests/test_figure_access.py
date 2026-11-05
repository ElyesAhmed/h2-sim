"""Figure access works on nested notebook pages and without a paired PDF."""
import base64
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest

from docutils import nodes
from docutils.utils import new_document

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('figure_access', ROOT/'doc/_ext/figure_access.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FigureAccessTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.static = self.root/'src/_static/examples'
        self.static.mkdir(parents=True)
        self.payload = b'embedded image payload'
        (self.static/'plot.png').write_bytes(self.payload)
        self.app = SimpleNamespace(srcdir=self.root/'src', outdir=self.root/'html',
            builder=SimpleNamespace(format='html', get_target_uri=lambda name: name+'.html'))

    def tree(self, uri):
        tree = new_document('example')
        figure = nodes.figure()
        image = nodes.image(uri=uri, alt='Hydrogen fraction after withdrawal')
        figure += image
        tree += figure
        return tree, image

    def test_nested_page_has_contextual_links_and_optional_pdf(self):
        (self.static/'plot.pdf').write_bytes(b'%PDF')
        tree, _ = self.tree('../_static/examples/plot.png')
        module.add_figure_links(self.app, tree, 'notebooks/example')
        links = list(tree.findall(nodes.reference))
        self.assertEqual([n['refuri'] for n in links],
                         ['../_static/examples/plot.png', '../_static/examples/plot.pdf'])
        self.assertIn('Hydrogen fraction after withdrawal', links[0].astext())
        self.assertIsInstance(links[1], module.addnodes.download_reference)

    def test_missing_pdf_does_not_produce_a_broken_download(self):
        tree, _ = self.tree('_static/examples/plot.png')
        module.add_figure_links(self.app, tree, 'example')
        self.assertEqual(len(list(tree.findall(nodes.reference))), 1)

    def test_portable_attachment_reuses_the_matching_published_figure(self):
        tree, image = self.tree('data:image/png;base64,' + base64.b64encode(self.payload).decode())
        module.add_figure_links(self.app, tree, 'notebooks/example')
        self.assertEqual(image['uri'], '../_static/examples/plot.png')

    def test_notebook_only_artwork_is_exported_without_changing_bytes(self):
        payload = b'notebook-only figure'
        tree, image = self.tree('data:image/png;base64,' + base64.b64encode(payload).decode())
        module.add_figure_links(self.app, tree, 'example')
        self.assertEqual((self.app.outdir/image['uri']).read_bytes(), payload)
        self.assertEqual(len(list(tree.findall(nodes.reference))), 1)
