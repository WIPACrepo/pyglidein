import logging
import os
import stat

import pytest

import pyglidein.config
from pyglidein.queues.condor import Condor


@pytest.fixture
def subprocess_mock(mocker):
    mocker.patch('subprocess.check_call')
    yield mocker.patch('subprocess.check_output')


def test_status_default():
    config = pyglidein.config.Config('cfg')
    config['Cluster']['running_cmd'] = 'echo 1'
    config['Cluster']['idle_cmd'] = 'echo 2'

    q = Condor(config, {})
    ret = q.status()

    assert ret == {'Cluster': {'running': 1, 'idle': 2}}

def test_status_condor(subprocess_mock):
    config = pyglidein.config.Config('cfg')
    config['Cluster']['cpus'] = 1
    config['Cluster']['gpus'] = 0
    config['Cluster']['memory'] = 4
    config['Cluster']['disk'] = 1
    config['Cluster']['time'] = 24
    q = Condor(config, {})

    subprocess_mock.return_value = '''
1 1 0 4000 1000000 24
2 1 0 4000 1000000 24
'''
    ret = q.status()

    assert ret == {'Cluster': {'running': 1, 'idle': 1}}

def test_submit_condor(subprocess_mock, tmpdir):
    config = pyglidein.config.Config('cfg')
    config['Cluster']['cpus'] = 1
    config['Cluster']['gpus'] = 0
    config['Cluster']['memory'] = 4
    config['Cluster']['disk'] = 1
    config['Cluster']['time'] = 24
    config['SubmitFile']['filename'] = tmpdir / 'submit'
    config['SubmitFile']['env_wrapper_name'] = tmpdir / 'env.sh'

    q = Condor(config, {})
    q.submit({'Cluster': 2})

    assert os.path.exists(config['SubmitFile']['env_wrapper_name'])
    assert os.stat(config['SubmitFile']['env_wrapper_name']).st_mode & stat.S_IXUSR

    assert os.path.exists(config['SubmitFile']['filename'])
    data = open(config['SubmitFile']['filename']).read()
    logging.debug(data)
    data = data.strip('\n').split('\n')
    assert f'executable = {config["SubmitFile"]["env_wrapper_name"]}' in data
    assert 'request_cpus = 1' in data
    assert not any('request_gpus' in line for line in data)
    assert 'request_memory = 4000' in data
    assert 'request_disk = 1000000' in data
    assert any('+TimeHours = 24' in line for line in data) # can be float 24.0000
    assert data[-1] == 'queue 2'

def test_cleanup_condor():
    config = pyglidein.config.Config('cfg')
    q = Condor(config, {})
    q.cleanup()