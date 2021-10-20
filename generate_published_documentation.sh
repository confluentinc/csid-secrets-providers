#!/bin/sh

# Set up
mkdir -p docs
pip3 install sphinx-rtd-theme
pip3 install sphinx-markdown-tables
folder_location=$(pwd)


# Generate README HTML
cd docs_src
pwd=$(pwd)
make html

# copy the useful folder for release
cp -r $pwd/_build/html/ $folder_location/docs
