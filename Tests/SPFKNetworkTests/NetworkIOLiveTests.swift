// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import SPFKUtils
import Testing

@testable import SPFKNetwork

// Requires network access. Run manually; not suitable for offline CI.
@Suite(.serialized, .tags(.file))
final class NetworkIOLiveTests: BinTestCase, @unchecked Sendable {
    /// Known-good test fixture hosted at a stable URL.
    /// Content: "SPFKNetwork test file\n" (22 bytes, UTF-8)
    /// Locally at: SPFKNetworkTests/spfk-network-test-file.txt
    private static let testFileURL = URL(string: "http://spongefork.com/dev/spfk-network-test-file.txt")!
    private static let testFileContent = Data("SPFKNetwork test file\n".utf8)

    override init() async {
        await super.init()
    }

    // MARK: - NetworkIO

    @Test func dataFromURL() async throws {
        let data = try await NetworkIO.data(from: Self.testFileURL)
        #expect(data == Self.testFileContent)
    }

    @Test func downloadToFile() async throws {
        let destURL = bin.appendingPathComponent("networkio-download.txt")
        try await NetworkIO.download(from: Self.testFileURL, to: destURL)

        #expect(destURL.exists)
        #expect(try Data(contentsOf: destURL) == Self.testFileContent)
    }

    // MARK: - BufferedDownloader

    @Test func bufferedDownload() async throws {
        let destURL = bin.appendingPathComponent("buffered-download.txt")
        let downloader = BufferedDownloader()
        let result = try await downloader.download(from: Self.testFileURL, to: destURL)

        #expect(result == destURL)
        #expect(try Data(contentsOf: destURL) == Self.testFileContent)
    }

    @Test func bufferedDownloadProgressEvents() async throws {
        let destURL = bin.appendingPathComponent("buffered-download-events.txt")
        let log = DownloadEventLog()
        let downloader = BufferedDownloader()

        _ = try await downloader.download(from: Self.testFileURL, to: destURL) { event in
            switch event {
            case let .start(id):
                log.events.append("start")
                log.fractions.append(id.fractionCompleted)
            case let .progress(id):
                log.events.append("progress")
                log.fractions.append(id.fractionCompleted)
            case let .complete(id):
                log.events.append("complete")
                log.fractions.append(id.fractionCompleted)
            }
        }

        // File is 23 bytes — below the flush threshold, so no mid-stream progress events
        #expect(log.events == ["start", "complete"])
        #expect(log.fractions.first == 0.0)
        #expect(log.fractions.last == 1.0)
    }

    @Test func bufferedDownloadStatusIdentifierIsStable() async throws {
        // The statusIdentifier should be consistent across all events for the same download
        let destURL = bin.appendingPathComponent("buffered-download-id.txt")
        let log = DownloadEventLog()
        let downloader = BufferedDownloader()

        _ = try await downloader.download(
            name: "test-download",
            from: Self.testFileURL,
            to: destURL
        ) { event in
            switch event {
            case let .start(id), let .progress(id), let .complete(id):
                log.events.append(id.statusIdentifier)
            }
        }

        // All events share the same statusIdentifier for the lifetime of the download
        let identifiers = Set(log.events)
        #expect(identifiers.count == 1)
        #expect(log.events.first?.hasPrefix("test-download_") == true)
    }
}
