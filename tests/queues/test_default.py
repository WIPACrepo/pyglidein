import os
import stat

import pytest

import pyglidein.config
import pyglidein.queues


def test_status():
    config = pyglidein.config.Config('cfg')
    config['Cluster']['running_cmd'] = 'echo 1'
    config['Cluster']['idle_cmd'] = 'echo 2'

    q = pyglidein.queues.BatchQueue(config, {})
    ret = q.status()

    assert ret == {'Cluster': {'running': 1, 'idle': 2}}

def test_submit():
    config = pyglidein.config.Config('cfg')
    q = pyglidein.queues.BatchQueue(config, {})
    with pytest.raises(NotImplementedError):
        q.submit({})

def test_cleanup():
    config = pyglidein.config.Config('cfg')
    q = pyglidein.queues.BatchQueue(config, {})
    q.cleanup()

def test_partitions_none():
    config = pyglidein.config.Config('cfg')
    config['Cluster']['running_cmd'] = 'echo 1'

    q = pyglidein.queues.BatchQueue(config, {})
    assert q._partitions == ['Cluster']

def test_partitions_many(tmp_path):
    cfg_filename = tmp_path / 'config.cfg'
    with cfg_filename.open('w') as f:
        print('''[Cluster]
partitions = one, two, three
[one]
[two]
[three]
''', file=f)
    config = pyglidein.config.Config(cfg_filename)

    assert 'one' in config

    q = pyglidein.queues.BatchQueue(config, {})
    assert q._partitions == ['one', 'two', 'three']

def test_all_partitions_running_idle_cmd_false():
    config = pyglidein.config.Config('cfg')

    q = pyglidein.queues.BatchQueue(config, {})
    assert q.all_partitions_running_idle_cmd() == False

def test_all_partitions_running_idle_cmd_true():
    config = pyglidein.config.Config('cfg')
    config['Cluster']['running_cmd'] = 'echo 1'
    config['Cluster']['idle_cmd'] = 'echo 2'

    q = pyglidein.queues.BatchQueue(config, {})
    assert q.all_partitions_running_idle_cmd() == True

def test_make_env_wrapper(tmpdir):
    config = pyglidein.config.Config('cfg')
    q = pyglidein.queues.BatchQueue(config, {})

    env_filename = tmpdir / 'env_wrapper.sh'

    q.make_env_wrapper(env_filename, config['Cluster'])

    assert os.path.exists(env_filename)
    assert os.stat(env_filename).st_mode & stat.S_IXUSR

def test_make_env_wrapper_customenv(tmpdir):
    config = pyglidein.config.Config('cfg')
    config['CustomEnv'] = {'foo': 'bar'}
    q = pyglidein.queues.BatchQueue(config, {})

    env_filename = tmpdir / 'env_wrapper.sh'

    q.make_env_wrapper(env_filename, config['Cluster'])

    data = open(env_filename).read()
    assert 'foo=bar' in data
