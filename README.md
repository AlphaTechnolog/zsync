# ZSync

ZSync is a little tool made in zig, which given two folders paths
merges the content recursively of the source to the dest, so given the next
command:

```sh
zsync ./{a,b}
```

zsync will merge the content of a into b by checking recursively the
struct of the a folder.

## Installation

```sh
git clone https://github.com/alphatechnolog/zsync.git
cd zsync
zig build -Doptimize=ReleaseFast
install -Dvm755 ./zig-out/bin/zsync /bin
```

## Usage

Perform:

```sh
zsync
```

## Todo

- [] Better error handling?
- [] Better logging
- [] Faster arguments parsing
- [] Speed up the merging algorithm
