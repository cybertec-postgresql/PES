"""Test availability of required packages."""

import unittest
from pathlib import Path

import pkg_resources

_REQUIREMENTS_PATH = Path("../patroni/requirements.txt")

requirements = pkg_resources.parse_requirements(_REQUIREMENTS_PATH.open())
found = 0
failed = False
for requirement in requirements:
    requirement = str(requirement)
    try:
        pkg_resources.require(requirement)
        found = found + 1
    except pkg_resources.DistributionNotFound as e:
        print(e)
        failed = True
if not failed:
    print("All {} packages are installed".format(found))