# -*- coding: utf-8 -*-
#
# This file is execfile()d with the current directory set to its containing dir.
#
# Note that not all possible configuration values are present in this file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.
#
# Updated documentation of the configuration options is available at
# https://www.sphinx-doc.org/en/master/usage/configuration.html
import sys
import os
from datetime import datetime

from antmicro_sphinx_utils.defaults import (
    extensions as default_extensions,
    myst_enable_extensions as default_myst_enable_extensions,
    myst_fence_as_directive as default_myst_fence_as_directive,
    antmicro_html,
    antmicro_latex,
)

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
# sys.path.insert(0, os.path.abspath('.'))

sys.path.insert(0, os.path.abspath("../extensions"))

# -- General configuration -----------------------------------------------------

# General information about the project.
project = "Guineveer"
basic_filename = "guineveer--docs"
authors = "Antmicro"
copyright = f"{authors}, {datetime.now().year}"

# The short X.Y version.
version = ""
# The full version, including alpha/beta/rc tags.
release = ""

# This is temporary before the clash between myst-parser and immaterial is fixed
sphinx_immaterial_override_builtin_admonitions = False

numfig = True

# If you need to add extensions just add to those lists
extensions = list(set(default_extensions + ["draw_graph"]))
myst_enable_extensions = default_myst_enable_extensions
myst_fence_as_directive = default_myst_fence_as_directive

myst_substitutions = {"project": project}

myst_heading_anchors = 4

today_fmt = "%Y-%m-%d"

todo_include_todos = False

# -- Options for HTML output ---------------------------------------------------

html_theme = "sphinx_immaterial"

html_last_updated_fmt = today_fmt

html_show_sphinx = False

(html_logo, html_theme_options, html_context) = antmicro_html(
    pdf_url=f"{basic_filename}.pdf"
)

html_title = project

(latex_elements, latex_documents, latex_logo, latex_additional_files) = antmicro_latex(
    basic_filename, authors, project
)
