#!/bin/env python
"""
docstring
"""
# from subprocess import call
import yaml
# from ptpython.repl import embed

# embed(globals(), locals())

INPUT = open('vars/sourcery_palette.yml')
DEST = open('xcolors/test.xresources')

# use safe_load instead load
PALETTE = yaml.safe_load(INPUT)

INPUT.close()

print(PALETTE['bright_green'])


# call(["ls", "-l"])
