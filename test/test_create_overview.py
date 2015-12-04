import os

__author__ = 'pbelmann'

import nose.tools as nose
import tempfile
from scripts import create_overview

OVERVIEW_HEADER = [
    'cov1\tcov2\tGene ID\tHMM\tGroup\tscore HMM\tEvalue HMM\tBest blastp hit\tEvalue best blastp\tIdentity\tSubject accsession\tSubject titles\tSubject tax ids\tSubject ids\tLinks\tGene sequence\n']

def write_config_file(path):
    with open(path, "w") as config:
        config.write("""
- A:
   - A1
   - A2
- B:
   - B1
   - B2
        """)

def test_determine_config_values():
    _, path = tempfile.mkstemp()
    write_config_file(path)
    with open(path, "r") as configFile:
        config = create_overview.load_search_config(configFile)
        clazz = create_overview.determine_config_values(config, "A1")
    nose.assert_equal(clazz[1], "A")


def test_write_header():
    coverages = ["/test/path/cov1", "/test/path/cov2"]
    _, path = tempfile.mkstemp()
    with open(path, "r+") as temp_file:
        create_overview.writeHeader(coverages, temp_file, True)
        temp_file.seek(0)
        nose.assert_equals(temp_file.readlines(), OVERVIEW_HEADER)
    os.remove(path)

def test_load_config():
    _, path = tempfile.mkstemp()
    write_config_file(path)
    with open(path, "r") as config:
        config = create_overview.load_search_config(config)
        print config
        nose.assert_equals(config, [{'A': ['A1', 'A2']}, {'B': ['B1', 'B2']}])
