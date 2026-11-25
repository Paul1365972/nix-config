# GitHub samples

Pull requests from 2023 to 2025, typed by Paul himself.
They are unchanged, except that the changelog of the bundled one is shortened.

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

A pull request to someone else's project:

```
I thought I would update this crate for bevy 0.10, now with stageless.
Also updated the bytemuck and bevy_egui dependencies.

All tests are passing and the examples seem to be working as well.

Also noticed that currently most operations only support the primary window, maybe that's a nice todo. For now I removed the WindowId from FillKind::Window, this should probably be an Entity (with a Window component + tracking) in the future.
```

A pull request that bundles many changes:

```
I extracted all the non destructive changes from my feature branches into one "nice" PR.
A lot of the changes are useful by themself. However this is mostly so I don't go insane rebasing stuff every few weeks, as my branches have diverged too far from the main branch by now.

Changelog:
- Added the remaining sign types
- Allow signs to be picked/placed with NBT data
- Add tab-complete to commonly used commands that were currently missing it
- Prepared for addition of new Backends by implementing Backend switching
- Modified constant_coalesce pass so that it won't coalesce constants that belong to different unconncted builds (This is one of the few changes that improve nothing for now and is mostly so that my threading doesn't break)
- A lot of other minor stuff
```

A pull request that says what is untested:

```
Added preview releases so that I hopefully don't have to recompile everytime I need an old/working version of MCHPRS.
Also updated the other workflows while at it.

Changes:
- Add automatic preview builds for the latest commit
- Add automatic release builds
- Switch out the deprecated actions
- Extend and rename test.yml file
  - Separate actions into multiple jobs so that they appear fail/pass separatly
  - Add clippy linting
- Improve Docker image tagging

Clippy complains about so much that I did not activate fail on warning yet (Can recommend going through the warnings, kind of interesting and I think it caught a legitimate bug as well, will look into it later).
I also immediately had to suppress a false positive of clippy in the noteblocks pitch LUT, as clippy thought it was a hard error.

I tested everything, except for the docker workflow.
However it should be (hopefully) fine as I mostly copied it from a different project of mine.
```
