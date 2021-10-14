import sys

# get a RestClient
if sys.version[0] == 3 and sys.version[1] >= 6:
    from rest_tools.client import RestClient
else:
    import requests
    import os

    class RestClient:
        def __init__(self, address, token=None):
            self.address = address
            self.token = token
        def request_seq(self, method, path, args):
            if path.startswith('/'):
                path = path[1:]
            url = os.path.join(self.address, path)
            headers = {}
            if self.token:
                headers['Authorization'] = 'Bearer ' + self.token
            if method in ('GET', 'HEAD'):
                r = requests.query(method, url, params=args, headers=headers)
            else:
                r = requests.query(method, url, json=args, headers=headers)
            r.raise_for_status()
            return r.json()


class Server:
    def __init__(self, config, secrets):
        self.config = config
        self.secrets = secrets

    def get(self, status):
        client_id = self.config['Glidein']['client_id']
        path = '/api/clients/'+client_id+'/actions/queue'

        data = {}
        for p in status:
            data[p] = {
                'resources': {k: self.config[p][k] for k in ('cpus', 'gpus', 'memory', 'disk', 'time')},
                'num_queued': status[p]['idle'],
                'num_processing': status[p]['running'],
            }

        r = RestClient(self.config['Glidein']['address'],
                       token=self.secrets.get('token', None))
        return r.request_seq('POST', path, data)
