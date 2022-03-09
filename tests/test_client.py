from collections import defaultdict
import importlib
import pytest
from unittest.mock import MagicMock

import pyglidein.config
import pyglidein.client


class SchedMod:
    state = defaultdict(MagicMock)
    class Testsched(MagicMock):
        def status(self):
            return SchedMod.state['status']()
        def submit(self, *args):
            return SchedMod.state['submit'](*args)
        def cleanup(self):
            return SchedMod.state['cleanup']()

@pytest.fixture
def scheduler_mock(mocker):
    p = mocker.patch('importlib.import_module')
    p.return_value = SchedMod
    SchedMod.state = defaultdict(MagicMock)
    yield p

@pytest.fixture
def server_mock(mocker):
    p = mocker.patch('pyglidein.client.Server')
    p.return_value.get.return_value = {}
    yield p

def test_defaults(scheduler_mock, server_mock):
    config = pyglidein.config.Config('cfg')
    config['Cluster']['scheduler'] = 'testsched'
    pyglidein.client.run(config, {})

    scheduler_mock.assert_called()
    assert list(SchedMod.state.keys()) == ['status', 'cleanup']
    server_mock.assert_called()

def test_empty_client_empty_server(scheduler_mock, server_mock):
    config = pyglidein.config.Config('cfg')
    config['Cluster']['scheduler'] = 'testsched'

    st = SchedMod.state['status'] = MagicMock()
    st.return_value = {'part1': {'running': 0, 'idle': 0}}
    #server_mock.return_value.get.return_value = {}

    pyglidein.client.run(config, {})

    scheduler_mock.assert_called()
    assert list(SchedMod.state.keys()) == ['status', 'cleanup']
    server_mock.assert_called()
    server_mock.return_value.get.assert_called_with(st.return_value)

def test_empty_client_queue_server(scheduler_mock, server_mock):
    config = pyglidein.config.Config('cfg')
    config['Cluster']['scheduler'] = 'testsched'

    st = SchedMod.state['status'] = MagicMock()
    st.return_value = {'part1': {'running': 0, 'idle': 0}}
    server_mock.return_value.get.return_value = {'part1': 1}

    pyglidein.client.run(config, {})

    scheduler_mock.assert_called()
    assert list(SchedMod.state.keys()) == ['status', 'submit', 'cleanup']
    SchedMod.state['submit'].assert_called_with(server_mock.return_value.get.return_value)
    server_mock.assert_called()
    server_mock.return_value.get.assert_called_with(st.return_value)
