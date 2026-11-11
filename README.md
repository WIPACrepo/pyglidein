# pyglidein

glidein configurations for icecube grid computing. 
these run on remote sites and then connect back to the condor pool at `glidein-cm.icecube.wisc.edu` to advertise slots.


## layout

```
configs/        # glidein slurm jobs
helpers/        # submit and cleanup scripts
pyglidein/      # glidein_start.sh (TODO: move this to the root)
docs_old/       # old 1.x and 2.0 docs for historical reference.
```


## docs

- [architecture.md](architecture.md) -- how a glidein works end to end
- [sites.md](sites.md) -- per-site reference and how to add a site
- [cvmfsexec.md](cvmfsexec.md) -- unprivileged CVMFS


## history

first there was the bespoke 1.x glidein python package shipping condor in a box, 
connecting back to a central server. with a client on each cluster that submitted glidein jobs dynamically based on demand.
then in 2021 an attempt was made to rebuild this core idea atop the OSG pilots instead, but was never finished.
in practice it was superceded by the scripts based workflow you see here now. 

what's lacking compared to the previous incarnations is a feedback mechanism to dynamically submit glideins based on real demand.
however, this is rarely an issue in reality since we're almost always supply constrained and demand is quite consistent.

if we do ever wish to revive 2.0 or some other similar client-server architecture, here's where to look:
- [docs_old/](docs_old/README.md) -- the 1.x and 2.0 docs, frozen (links may be broken)
- [archive-1.x](https://github.com/WIPACrepo/pyglidein/tree/archive-1.x) -- old 1.x branch. same as the v1.1.23 tag
- [archive-2.0](https://github.com/WIPACrepo/pyglidein/tree/archive-2.0) -- branch with final version of the repo before unused 2.0 code was removed
- [WIPACrepo/pyglidein-server](https://github.com/WIPACrepo/pyglidein-server/) -- the unfinished 2.0 server implementation
