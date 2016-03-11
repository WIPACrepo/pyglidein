# create_glidein_tarball.py

This script automates the process of creating a glidein tarball for
a particular platform.

## Options

* `--output`: Tarball output name.

  This can be a relative or absolute path to the output tarball name.
  It defaults to `glidein.tar.gz`.

* `--template-dir`: Location of the template directory.

  Things in the template directory are directly copied into the tarball.
  The default template is [here](../glidein_template).

* `--htcondor-version`: The HTCondor version to build.

  The script automatically downloads and builds a specific release
  of HTCondor, adding the necessary parts to the glidein tarball.

* `--parrot-version`: The CCTools / Parrot version to build.

  Parrot is responsible for CVMFS emulation at sites that don't support
  it. As part of this installation, CVMFS is built from the latest
  master compatible with parrot. Then the specified version of CCTools
  (the package parrot belongs to) is built. Since parrot is statically
  linked, only the needed executable and helper are added to the tarball.
