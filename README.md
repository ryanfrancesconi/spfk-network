# SPFKNetwork
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-network)](https://github.com/ryanfrancesconi/spfk-network/tags)
[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)

Small networking helpers built on `URLSession` and Swift concurrency.

## Features

- `NetworkIO` fetches data, sends requests, and treats a non-2xx status as an error
- `BufferedDownloader` streams a download to a file with progress events, and deletes the partial
  file if the download fails
- Without a `Content-Length`, download progress does not reach completion until the stream ends

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
