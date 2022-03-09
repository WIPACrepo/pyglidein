#!/bin/sh
unset PYTHONPATH
if command -v python3 &>/dev/null; then
    PYTHON3=1
else
    PYTHON3=0
fi

if [ "$PYTHON3" = "1" ]; then
    python3 -m virtualenv -p python3 env
else
    python -m virtualenv -p python env
fi

echo "unset PYTHONPATH" >> env/bin/activate
. env/bin/activate
pip install --upgrade pip

if [ "$PYTHON3" = "1" ]; then
    pip install -r requirements.txt
else
    pip install -r requirements-py2.txt
fi
