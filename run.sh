#!/bin/sh

export PYTHONPATH=$PWD

python pyglidein/client.py --config=configs/cedar.config --secrets=secrets
