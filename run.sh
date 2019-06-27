#!/bin/sh

# This is an example that works for Cedar; can use it as a reference
export PYTHONPATH=$PWD

python pyglidein/client.py --config=configs/cedar.config --secrets=secrets
