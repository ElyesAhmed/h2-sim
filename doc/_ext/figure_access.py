"""Add accessible, build-time links to scientific figures, including notebooks."""
from pathlib import Path, PurePosixPath
import base64
import hashlib
import posixpath
from urllib.parse import urlsplit

from docutils import nodes
from sphinx import addnodes


def add_figure_links(app, doctree, docname):
    if app.builder.format != 'html':
        return
    static = Path(app.srcdir) / '_static'
    images = {p.name: p for p in (static / 'examples').glob('*.png')}
    images.update({name: static / name for name in ('workflows.svg', 'reservoir.svg')
                   if (static / name).is_file()})
    by_hash = {hashlib.sha256(p.read_bytes()).hexdigest(): p for p in images.values()}
    parent = posixpath.dirname(app.builder.get_target_uri(docname)) or '.'
    for image in list(doctree.findall(nodes.image)):
        ancestor = image.parent
        while ancestor is not None and not isinstance(ancestor, nodes.substitution_definition):
            ancestor = ancestor.parent
        if ancestor is not None:
            continue
        uri = image.get('uri', '')
        source = None
        target = None
        if uri.startswith('data:image/png;base64,'):
            payload = base64.b64decode(uri.split(',', 1)[1], validate=True)
            digest = hashlib.sha256(payload).hexdigest()
            source = by_hash.get(digest)
            if source is None:
                # Preserve figures unique to a notebook exactly as embedded.
                target = f'_images/notebook-figure-{digest}.png'
                output = Path(app.outdir) / target
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(payload)
        elif not urlsplit(uri).scheme:
            source = images.get(PurePosixPath(uri).name)
        if source is not None:
            target = '_static/' + source.relative_to(static).as_posix()
        if target is None:
            continue
        # Static copies and notebook attachments use the same published asset.
        image['uri'] = posixpath.relpath(target, parent)
        alt = image.get('alt') or 'Scientific figure'
        links = nodes.paragraph(classes=['figure-access'])
        options = [('Open full-size', target)]
        if source is not None and source.with_suffix('.pdf').is_file():
            options.append(('Download PDF', target.rsplit('.', 1)[0] + '.pdf'))
        for label, destination in options:
            if len(links):
                links += nodes.Text(' · ')
            kind = addnodes.download_reference if label == 'Download PDF' else nodes.reference
            link = kind('', '', refuri=posixpath.relpath(destination, parent))
            link += nodes.Text(label)
            link += nodes.inline('', ' — ' + alt, classes=['figure-access-context'])
            links += link
        container = image
        while container.parent is not None and not isinstance(container.parent,
                (nodes.figure, nodes.paragraph, nodes.document)):
            container = container.parent
        if isinstance(container.parent, (nodes.figure, nodes.paragraph)):
            container = container.parent
        container.parent.insert(container.parent.index(container) + 1, links)


def setup(app):
    app.connect('doctree-resolved', add_figure_links)
    return {'version': '1', 'parallel_read_safe': True, 'parallel_write_safe': True}
