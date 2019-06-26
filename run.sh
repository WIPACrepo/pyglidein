#!/bin/sh

export PYTHONPATH=~/pyglidein

python pyglidein/client.py --config=configs/npx-test.config --secrets=secrets
