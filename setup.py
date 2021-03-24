#!/usr/bin/env python
"""Setup."""

# fmt:off

import os

from setuptools import find_packages, setup  # type: ignore[import]

kwargs = {}

current_path = os.path.dirname(os.path.realpath(__file__))

with open(os.path.join(current_path, "pyglidein", "__init__.py")) as f:
    for line in f.readlines():
        if "__version__" in line:
            # grab "X.Y.Z" from "__version__ = 'X.Y.Z'" (quote-style insensitive)
            kwargs["version"] = line.replace('"', "'").split("=")[-1].split("'")[1]
            break
    else:
        raise Exception("cannot find __version__")

setup(
    name='pyglidein',
    use_scm_version=True,
    setup_requires=['setuptools_scm'],
    description='Some python scripts to launch HTCondor glideins',
    url='https://github.com/WIPACrepo/pyglidein',
    author='WIPAC',
    author_email='contact-us@icecube.wisc.edu',
    classifiers=[
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],
    keywords='htcondor dHTC glidein',
    packages=find_packages(),
    install_requires=['minio', 'tornado'],
    package_data={
        'pyglidein': ['etc/client_defaults.cfg',
                      'glidein_start.sh', 'log_shipper.sh', 'os_arch.sh',
                      'startd_cron_scripts/clsim_gpu_test.py',
                      'startd_cron_scripts/cvmfs_test.py',
                      'startd_cron_scripts/gridftp_test.py',
                      'startd_cron_scripts/post_cvmfs.sh',
                      'startd_cron_scripts/pre_cvmfs.sh']
    },
    entry_points={
        'console_scripts': [
            'pyglidein_client=pyglidein.client:main',
            'pyglidein_server=pyglidein.server:main'
        ]
    },
    python_requires='>=2.6',
    **kwargs,
)
