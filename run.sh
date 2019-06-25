#!/bin/sh

export PYTHONPATH=~/projects/def-kenclark-ab/jrajewsk/pyglidein

python pyglidein/client.py --config=configs/cedar.config --secrets=secrets
