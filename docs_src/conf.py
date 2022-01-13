import os
import sys
import sphinx_rtd_theme
sys.path.insert(0, os.path.abspath('../..'))

import datetime
now = datetime.datetime.now()


# -- Project information -----------------------------------------------------

project = 'Confluent CSID Secrets Provider documentation'
copyright = f'{now.year}, Confluent'
author = 'CSID'

# TODO retrieve the version number from the pom
# The full version, including alpha/beta/rc tags
# release = 'Release documentation'


# -- General configuration ---------------------------------------------------

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

source_parsers = {
    '.md': 'recommonmark.parser.CommonMarkParser',
}

'''
Add any Sphinx extension module names here, as strings. They can be extensions coming with Sphinx (named 'sphinx.ext.*')
or your custom ones.
'''

extensions = ['sphinx.ext.autodoc', 'sphinx.ext.mathjax', 'sphinx.ext.githubpages',
              'sphinx_rtd_theme', 'recommonmark', 'sphinx_markdown_tables',
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

'''
List of patterns, relative to source directory, that match files and directories to ignore when looking for source
files. This pattern also affects html_static_path and html_extra_path.
'''



source_suffix = ['.rst', '.md']

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.
html_theme = 'sphinx_rtd_theme'

'''
Add any paths that contain custom static files (such as style sheets) here,  relative to this directory. They
are copied after the builtin static files, so a file named "default.css" will overwrite the builtin "default.css".
'''

html_static_path = ['_static']