#!/bin/bash

# This assume we are on a RHEL style system


cd $HOME

# Install apptainer
sudo dnf install -y epel-release
sudo dnf install -y apptainer

# Get required image
apptainer pull docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release

# Settung up cvmfsexec
git clone https://github.com/cvmfs/cvmfsexec.git

$HOME/cvmfsexec/makedist osg

