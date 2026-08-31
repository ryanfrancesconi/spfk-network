# SPFKNetwork
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-network)](https://github.com/ryanfrancesconi/spfk-network/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)

Lightweight networking utilities for macOS and iOS built on `URLSession` and Swift concurrency.

## Requirements

- **Platforms:** macOS 13+, iOS 16+
- **Swift:** 6.2+

## Overview

### NetworkIO

A static namespace for common HTTP operations — GET, POST, HEAD, reachability, and decoding a
response body. All of them load the full body into memory; use `BufferedDownloader` for large
files. Failures arrive as `NetworkIOError`.

### BufferedDownloader

An actor that streams a remote URL to a local file with per-flush progress events, identified by a
`ProgressIdentifier`. Suitable for large files where memory efficiency and progress reporting
matter.

Progress fraction is computed from the server's `Content-Length` when available. For responses without `Content-Length`, the denominator is kept ahead of bytes received so the fraction approaches but never falsely reaches 1.0 mid-stream.

## Dependencies

| Package | Description |
|---|---|
| [spfk-utils](https://github.com/ryanfrancesconi/spfk-utils) | Filesystem helpers and Foundation extensions |

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
