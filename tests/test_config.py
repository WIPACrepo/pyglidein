
import pytest

import pyglidein.config


def test_file_does_not_exist(tmp_path):
    cfg_filename = str(tmp_path / 'config.cfg')
    pyglidein.config.Config(cfg_filename)

def test_defaults(tmp_path):
    cfg_filename = tmp_path / 'config.cfg'
    cfg_filename.touch()
    cfg = pyglidein.config.Config(cfg_filename)

    assert cfg['Mode']['debug'] == False
    assert 'address' in cfg['Glidein']

def test_custom(tmp_path):
    cfg_filename = tmp_path / 'config.cfg'
    with cfg_filename.open('w') as f:
        print('''[Glidein]
site = Foo
''', file=f)
    cfg = pyglidein.config.Config(cfg_filename)

    assert cfg['Mode']['debug'] == False
    assert 'address' in cfg['Glidein']
    assert cfg['Glidein']['site'] == 'Foo'
