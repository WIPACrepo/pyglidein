# Pyglidein Development Environment

The Pyglidein Development Environment is composed of a server container and a client container.  The intention is to mimic a server site running HTCondor and a remote grid client site running HTCondor.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

```
Docker
Docker-Compose
Copy of glidein.tar.gz
```

### Installing

```
#!/bin/bash -e

cd dev_build/server
sudo ./build_server.sh
cd ../client
sudo ./build_client.sh
cd ..
sudo docker-compose up -d
sudo docker cp /path/to/glidein.tar.gz devbuild_pyglidein-client_1:/pyglidein/glidein.tar.gz
```

## Running the tests

```
sudo docker exec -it devbuild_pyglidein-server_1 /bin/bash
su - condor
source condor-8.7.2/condor.sh
python /pyglidein/tests/integration/test_htcondor_glidein.py
```
