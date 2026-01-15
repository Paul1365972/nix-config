# Contributions Welcome

All kinds of contributions are welcome.

All PRs are checked against the CI. New features should include a test in [`_example/ci/`](templates/examples/modules/_example/ci).

To run tests locally:

```console
nix flake check github:vic/checkmate --override-input target .
nix flake check ./templates/examples --override-input den .
```

Ensure the code is formatted:

```console
nix run github:vic/checkmate#fmt --override-input target .
```

## Hang Out, Say "Hello, Here's a Potato!"

Just share that you are *using* Den—that will mean a lot to me (vic).

## Reporting Bugs

If you have found something that feels odd, be sure to open a [discussion](https://github.com/vic/den/discussions).

We use issues for actionable, pending, or planned tasks. Issues are on my (vic's) agenda, so I prefer to have as few as possible; for me, they represent actionable to-dos that I can allocate time to.

### Share a `bogus` Den

We provide a `bogus` template you can use for sending bug reports. It will mean a lot if you reproduce the bug using our template, because it can save us a lot of time and because your own code can become a test suite in itself.

Use the following commands and share your repository with us:

```console
mkdir bogus && cd bogus
nix flake init -t github:vic/den#bogus
nix flake update den
nix flake check
```

## Become a Patron

Talking about time, I've spent a lot of my own personal time on these libraries because I love Nix (the community—and at times, the technology), and my Dendritic libraries are a way of giving back and trying to achieve something better than what we have now.

Having said that, my time (as is everyone's) is limited on this earth. I love creating tools for people like me—developers, and more specifically, for Nix people.

I have some plans for next year (2026) regarding `denful` and other Nix-related projects. I'd like to spend more time creating things that are valuable for other people like me.

> If you like Den and the effort I'm putting into it and other Dendritic libraries to create high-quality Nix, consider [sponsoring](https://github.com/sponsors/vic) vic.
