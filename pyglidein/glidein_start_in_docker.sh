#!/bin/sh

if [ -z $GPUS ]; then
    export GPUS=0
fi

if [ $GPUS != 0 ]; then
    # Override $GPUS with whatever is in $NVIDIA_VISIBLE_DEVICES.
    # We assume that this script is only used inside of a conatiner built
    # from nvidia/cuda and decendants, so $NVIDIA_VISIBLE_DEVICES should
    # always be set to *something*.
    # (https://github.com/nvidia/nvidia-container-runtime#environment-variables-oci-spec)
    if [ -z $NVIDIA_VISIBLE_DEVICES ]; then
        echo "expected NVIDIA_VISIBLE_DEVICES to be set. Unexpectedly, it is not. Will set GPUS=0"
        export GPUS=0
    else
        if [ "$NVIDIA_VISIBLE_DEVICES" = "none" ]; then
            export GPUS=0
        else
            # echo "setting GPUS to NVIDIA_VISIBLE_DEVICES. GPUS=$NVIDIA_VISIBLE_DEVICES"
            export GPUS=$NVIDIA_VISIBLE_DEVICES
        fi
    fi
fi

echo "Starting dockerized pyglidein with GPUS=$GPUS"

# now run glidein_start.sh
exec $PWD/glidein_start.sh
