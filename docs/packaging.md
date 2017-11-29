# Packaging

For the most up to date instructions on creating python packages go [here](https://packaging.python.org/tutorials/distributing-packages/#uploading-your-project-to-pypi)

## Version info

Pyglidein uses source control version management.  When the python package is being built the git tag on the commit is used for versioning. Pyglidein uses a Simple "major.minor.micro" versioning scheme:

1.1.0
1.1.1
1.1.2
1.2.0
...

## Source Distribution

To create a source distribution in `dest/*`:

`python setup.py sdist`

## Binary Distribution

To create a binary distribution in `dest/*`:

`python setup.py bdist`

## Uploading Packages

`twine upload dist/*`
