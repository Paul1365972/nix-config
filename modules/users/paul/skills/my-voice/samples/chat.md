# Chat samples

Paul's own Discord messages, unchanged.

Short replies in a technical thread:

```
i just looked through mc src and couldn't find any part where "powered = output_strength > 0"  isn't true, well i found some wonky-ness but nothing we could hit with just the redstone subset we currently implement
```

```
put it in draft mode until the rest settles, too many merge conflicts are in flight atm
atleast the command touching stuff is now out of the way i guess
```

```
i mean it should be, branch predictors should be smart enough for that, i don't think they even differentiate between direct and indirect jumps, but reality sometimes disagrees for some reason
yeah maybe inlining is the issue, could be that
```

A proposal with open questions:

```
Hmmm, i feel like the optimizations in the redpiler are all generic that it should be correct to run them in any case always before any backend compilation, that each backend only sees the result of the redpiler, is there any reason not to do this?
any further transformations needed could be done on a case by case basis by the backend itself, but that would be their responsibility anyways
```

Disagreeing with a design:

```
we can honestly just make it a Box<dyn> thing, the enum delegate stuff is probably not even needed, at least i wouldn't know why, although both is fine
```
