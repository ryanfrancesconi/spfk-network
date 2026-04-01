# SPFKNetwork
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-network%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-network)

Lightweight networking utilities for macOS and iOS built on `URLSession` and Swift concurrency.

## Requirements

- **Platforms:** macOS 13+, iOS 16+
- **Swift:** 6.2+

## Overview

### NetworkIO

A static namespace for common HTTP operations. All functions load the full response body into memory — use `BufferedDownloader` for large files.

```swift
// Fetch raw data
let data = try await NetworkIO.data(from: url)

// Download to a local file
try await NetworkIO.download(from: remoteURL, to: localURL)

// POST with a JSON body
let response = try await NetworkIO.post(to: url, accessToken: token, json: encodedData)

// POST with URL-encoded form fields
let response = try await NetworkIO.post(query: [URLQueryItem(name: "key", value: "val")], to: url)

// Build a URLRequest manually
let request = NetworkIO.createRequest(from: url, httpMethod: .get, accessToken: token, accept: .json)
```

### BufferedDownloader

An `actor` that streams a remote URL to a local file with per-flush progress events. Suitable for large files where memory efficiency and progress reporting matter.

```swift
let downloader = BufferedDownloader()

let localURL = try await downloader.download(
    name: "My File",
    from: remoteURL,
    to: destinationURL
) { event in
    switch event {
    case .start(let progress): print("Starting:", progress.statusString)
    case .progress(let progress): print("Progress:", progress.fractionCompleted)
    case .complete(let progress): print("Done")
    }
}

// Cancel an in-flight download
await downloader.cancel()
```

Progress fraction is computed from the server's `Content-Length` when available. For responses without `Content-Length`, the denominator is kept ahead of bytes received so the fraction approaches but never falsely reaches 1.0 mid-stream.

## Dependencies

| Package | Description |
|---|---|
| [spfk-utils](https://github.com/ryanfrancesconi/spfk-utils) | Filesystem helpers and Foundation extensions |

## About

Spongefork (SPFK) is the personal software projects of [Ryan Francesconi](https://github.com/ryanfrancesconi). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2016 to 2025 he was the lead macOS developer at [Audio Design Desk](https://add.app).
