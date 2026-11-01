// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import SPFKUtils
import Testing

@testable import SPFKNetwork

/// Collects progress events from a download for assertion.
/// @unchecked Sendable is safe here because events are delivered serially
/// from within a single Task — there is no concurrent mutation in practice.
final class DownloadEventLog: @unchecked Sendable {
    var events: [String] = []
    var fractions: [Double] = []
}

@Suite(.tags(.file))
final class BufferedDownloaderTests: BinTestCase, @unchecked Sendable {
    override init() async {
        await super.init()
    }

    // MARK: - Small file (< bufferSize, no mid-stream progress flushes)

    @Test func downloadSmallFile() async throws {
        let content = Data("Hello, SPFKNetwork".utf8)
        let sourceURL = bin.appendingPathComponent("source_small.txt")
        let destURL = bin.appendingPathComponent("dest_small.txt")
        try content.write(to: sourceURL)

        let downloader = BufferedDownloader()
        let result = try await downloader.download(from: sourceURL, to: destURL)

        #expect(result == destURL)
        #expect(destURL.exists)
        #expect(try Data(contentsOf: destURL) == content)
    }

    @Test func progressEventsSmallFile() async throws {
        let content = Data(repeating: 0xFF, count: 1_024) // 1 KB — below flush threshold
        let sourceURL = bin.appendingPathComponent("source_events_small.bin")
        let destURL = bin.appendingPathComponent("dest_events_small.bin")
        try content.write(to: sourceURL)

        let log = DownloadEventLog()
        let downloader = BufferedDownloader()
        _ = try await downloader.download(from: sourceURL, to: destURL) { event in
            switch event {
            case .start: log.events.append("start")
            case .progress: log.events.append("progress")
            case .complete: log.events.append("complete")
            }
        }

        // Small file: only start and complete — buffer never fills so no mid-stream flush
        #expect(log.events == ["start", "complete"])
    }

    // MARK: - Large file (> bufferSize, triggers mid-stream progress events)

    @Test func downloadLargeFile() async throws {
        let largeData = Data(repeating: 0xAB, count: 200_000) // ~200 KB, ~3 buffer flushes
        let sourceURL = bin.appendingPathComponent("source_large.bin")
        let destURL = bin.appendingPathComponent("dest_large.bin")
        try largeData.write(to: sourceURL)

        let downloader = BufferedDownloader()
        let result = try await downloader.download(from: sourceURL, to: destURL)

        #expect(result == destURL)
        #expect(try Data(contentsOf: destURL) == largeData)
    }

    @Test func progressEventsLargeFile() async throws {
        let largeData = Data(repeating: 0xAB, count: 200_000)
        let sourceURL = bin.appendingPathComponent("source_events_large.bin")
        let destURL = bin.appendingPathComponent("dest_events_large.bin")
        try largeData.write(to: sourceURL)

        let log = DownloadEventLog()
        let downloader = BufferedDownloader()
        _ = try await downloader.download(from: sourceURL, to: destURL) { event in
            switch event {
            case .start(let id):
                log.events.append("start")
                log.fractions.append(id.fractionCompleted)
            case .progress(let id):
                log.events.append("progress")
                log.fractions.append(id.fractionCompleted)
            case .complete(let id):
                log.events.append("complete")
                log.fractions.append(id.fractionCompleted)
            }
        }

        #expect(log.events.first == "start")
        #expect(log.events.last == "complete")
        #expect(log.events.contains("progress"))
        #expect(log.fractions.last == 1.0)

        // All reported fractions should be non-decreasing
        for (a, b) in zip(log.fractions, log.fractions.dropFirst()) {
            #expect(a <= b)
        }
    }

    // MARK: - Name

    @Test func nameDefaultsToDestinationFilename() async throws {
        let content = Data("test".utf8)
        let sourceURL = bin.appendingPathComponent("src.txt")
        let destURL = bin.appendingPathComponent("dest_named.txt")
        try content.write(to: sourceURL)

        let downloader = BufferedDownloader()
        _ = try await downloader.download(from: sourceURL, to: destURL)

        let name = await downloader.name
        #expect(name == "dest_named.txt")
    }

    @Test func nameOverride() async throws {
        let content = Data("test".utf8)
        let sourceURL = bin.appendingPathComponent("src_override.txt")
        let destURL = bin.appendingPathComponent("dest_override.txt")
        try content.write(to: sourceURL)

        let downloader = BufferedDownloader()
        _ = try await downloader.download(name: "My File", from: sourceURL, to: destURL)

        let name = await downloader.name
        #expect(name == "My File")
    }

    // MARK: - Cancellation

    @Test func cancellationCleansUpPartialFile() async throws {
        // Large enough that it won't complete before cancellation is checked
        let largeData = Data(repeating: 0xCD, count: 1_000_000) // 1 MB
        let sourceURL = bin.appendingPathComponent("source_cancel.bin")
        let destURL = bin.appendingPathComponent("dest_cancel.bin")
        try largeData.write(to: sourceURL)

        let downloader = BufferedDownloader()
        let task = Task<URL, Error> {
            try await downloader.download(from: sourceURL, to: destURL)
        }

        // Yield to let download() start and register its inner currentTask
        await Task.yield()
        await downloader.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected download to throw after cancellation")
        } catch {
            #expect(!destURL.exists, "Partial file should be cleaned up on cancellation")
        }
    }
}

// MARK: - HTTP status

/// Answers requests to `host` with the HTTP status named by the URL's last path component.
final class HTTPStubProtocol: URLProtocol {
    static let host = "buffered-downloader.stub.test"
    static let body = Data("stub body".utf8)

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let status = Int(url.lastPathComponent),
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized, .tags(.file))
final class BufferedDownloaderHTTPStatusTests: BinTestCase, @unchecked Sendable {
    override init() async {
        await super.init()
        URLProtocol.registerClass(HTTPStubProtocol.self)
    }

    deinit {
        URLProtocol.unregisterClass(HTTPStubProtocol.self)
    }

    private func stubURL(status: Int) throws -> URL {
        try #require(URL(string: "https://\(HTTPStubProtocol.host)/\(status)"))
    }

    @Test func successStatusWritesBody() async throws {
        let destURL = bin.appendingPathComponent("dest_200.txt")

        _ = try await BufferedDownloader().download(from: stubURL(status: 200), to: destURL)

        #expect(try Data(contentsOf: destURL) == HTTPStubProtocol.body)
    }

    @Test func errorStatusThrowsAndLeavesNoFile() async throws {
        let destURL = bin.appendingPathComponent("dest_404.txt")

        let error = await #expect(throws: NetworkIOError.self) {
            try await BufferedDownloader().download(from: self.stubURL(status: 404), to: destURL)
        }

        guard case .httpError(let statusCode) = error else {
            Issue.record("Expected httpError, got \(String(describing: error))")
            return
        }
        #expect(statusCode == 404)

        #expect(!destURL.exists)
    }
}
