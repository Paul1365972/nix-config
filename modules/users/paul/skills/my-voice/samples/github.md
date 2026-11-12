# GitHub samples

The pull requests are from 2023, typed by Paul himself and unchanged.
The two comments at the end are from 2026: agent drafts he edited and posted, shortened here.

A pull request with a measured effect:

```
This PR adds an optimized function for iterating over all blocks inside a region, skipping all empty chunk sections.
This improves compile time speeds from ~200ms down to ~20ms on my machine for normal sized 256x256 plots.

Other changes:
- Same improvement for `//update`
- When executing `//update` without a selection the entire plot is updated instead
- Added `-u` flag for the `//paste` command to immediately update the pasted schematic
- `/rtps u` now works as an alias for `/rtps unlimited`

I hope someone has a good idea on how to deduplicate the optimized function without introducing overhead.
```

A pull request that asks for a second opinion:

```
I wrote this PR mostly to improve the interaction between the update loop and future new backends.
Some nice side effects are that when the redpiler is reset it will no longer hang or even timeout the player in extreme cases.
This also nearly solves the issue where changes would not flush at a consistent rate at very high tick rates.
The auto redpiler feature should also work more consistently now.
I additionally changed some of the magic constants, the new values worked better for my use cases, but I would still like a second opinion on them (Especially the reduction of the max batch size to 15_000 per update, does that create any issues?).
```

A pull request that explains a trade-off:

```
The default `std` HashMap/HashSet uses a cryptograpthic hash function (SipHash), this is definitely overkill. Since we don't need to protect against Hash DoS we can just use the same hash function that the rust compiler internally uses. The lower hash quality, and therefore resulting higher collision count, are offset by the drastically faster hashing algorithm.

I would have liked to replace all instances of HashMap, but that would mean also changing the nbt crate. Maybe a possible future enhancement. Anyways, the most important use cases are covered by this commit.
```

A small pull request:

```
Adds a new constant `PLOT_SECTIONS` to change the amount of sections per chunk.
Hope someone else can run the benchmark to make sure this doesn't negatively affect performance.

(Also fixes a spelling mistake and some minor compiler warnings)
```

A comment after a push:

```
Since the last push:

- Fixed fractional rates below 0.5 never ticking.
- Batches now end when the next world send is due, so sends land on schedule.
- `RateSchedule` now owns its rate and backlog cap.
```

The opening of a review:

```
Nice, that's a lot simpler now!
I built it locally and found a few things:
```
