"""H2sim code and selected examples. No MATLAB execution during docs builds."""
from pathlib import Path
import os
import pypandoc
os.environ['PATH'] = str(Path(pypandoc.get_pandoc_path()).parent) + os.pathsep + os.environ.get('PATH', '')
project = 'H2sim'
author = 'Elyes Ahmed, Xavier Raynaud'
master_doc = 'index'
source_suffix = '.rst'
extensions = ['nbsphinx', 'nbsphinx_link', 'sphinxcontrib.bibtex', 'sphinx.ext.mathjax',
              'sphinx.ext.autosectionlabel', 'sphinx_design', 'sphinx_copybutton']
autosectionlabel_prefix_document = True
exclude_patterns = ['_build', 'unparsed', '**/.ipynb_checkpoints']
nbsphinx_execute = 'never'
bibtex_bibfiles = ['references.bib']
mathjax3_config = {'loader': {'load': ['[tex]/mhchem']}, 'tex': {'packages': {'[+]': ['mhchem']}}}
html_theme = 'furo'
html_title = 'H2sim · Hydrogen storage modeling'
html_logo = '_static/h2sim-logo.svg'
html_favicon = '_static/h2sim-icon.svg'
html_static_path = ['_static']
html_css_files = ['css/custom.css']
html_js_files = [('js/community.js', {'defer': 'defer'})]
html_baseurl = 'https://sintefmath.github.io/h2-sim/'
html_theme_options = {
 'sidebar_hide_name': True,
 'light_css_variables': {'color-brand-primary': '#087f82', 'color-brand-content': '#087579'},
 'dark_css_variables': {'color-brand-primary': '#6cddd2', 'color-brand-content': '#6cddd2'},
 'source_repository': 'https://github.com/sintefmath/h2-sim/',
 'source_branch': 'master', 'source_directory': 'doc/',
}
html_show_sourcelink = False
html_show_sphinx = False
html_show_copyright = False
html_scaled_image_link = False
