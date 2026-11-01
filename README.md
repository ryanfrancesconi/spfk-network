# SPFKNetwork
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-network)](https://github.com/ryanfrancesconi/spfk-network/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)

Support for the few places the products touch the network: fetching a resource, sending a small
request, and downloading a large file to disk with progress. Built on `URLSession` and Swift
concurrency, with no state of its own.

`NetworkIO` loads a whole response into memory and treats a non-2xx status as an error.
`BufferedDownloader` streams to a file, reports progress as it goes, and deletes the partial file
when the download fails or is cancelled. Use the downloader for anything large. Without a
`Content-Length`, its progress approaches completion but never reports it before the stream ends.

What is fetched, and why, belongs to the caller.

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
