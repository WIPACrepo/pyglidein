# Client

The client is broken up into several parts, with the driving logic in
`client.py`.

## client.py

The main script for the client handles interaction with the server and
decides which idle jobs could be matched by the remote site. It then
attempts to submit up to a rate limit and max jobs (idle/running) limit.

## [submit.py](submit.md)

## [glidein_start.sh](glidein_start.md)

