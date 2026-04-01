// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKUtils

public struct ProgressIdentifier: Sendable {
    public var statusIdentifier: String
    public var statusString: String
    public var fractionCompleted: UnitInterval

    public init(
        statusIdentifier: String,
        statusString: String,
        fractionCompleted: UnitInterval = 0
    ) {
        self.statusIdentifier = statusIdentifier
        self.statusString = statusString
        self.fractionCompleted = fractionCompleted
    }
}

/// Downloads a remote URL to a local file path with streaming progress events.
public actor BufferedDownloader {
    public enum Event: Sendable {
        case start(ProgressIdentifier)
        case progress(ProgressIdentifier)
        case complete(ProgressIdentifier)
    }

    private static let bufferSize = 65_536
    private static let estimatedFallbackSize: Int64 = 1_000_000

    public private(set) var name: String = ""
    public private(set) var isDownloading: Bool = false

    private var currentTask: Task<URL, Error>?

    public init() {}

    /// Cancels the current in-flight download, if any.
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    /// Downloads `remoteURL` to `fileURL`, reporting events via `onEvent`.
    /// - Parameters:
    ///   - name: Display name used in progress events. Defaults to the destination filename.
    ///   - remoteURL: The remote resource to download.
    ///   - fileURL: The local destination path.
    ///   - onEvent: Called on `.start`, `.progress`, and `.complete` events.
    /// - Returns: `fileURL` on success.
    /// - Throws: `CancellationError` if cancelled, or a network/write error on failure.
    ///           Any partial file at `fileURL` is deleted on failure.
    public func download(
        name: String? = nil,
        from remoteURL: URL,
        to fileURL: URL,
        onEvent: (@Sendable (Event) -> Void)? = nil
    ) async throws -> URL {
        self.name = name ?? fileURL.lastPathComponent
        isDownloading = true
        defer { isDownloading = false }

        // Capture before leaving actor isolation
        let taskName = self.name

        let task = Task<URL, Error> {
            try await Self.perform(
                name: taskName,
                from: remoteURL,
                to: fileURL,
                onEvent: onEvent
            )
        }
        currentTask = task
        defer { currentTask = nil }

        do {
            return try await task.value
        } catch {
            try? fileURL.delete()
            throw error
        }
    }

    // MARK: - Private

    private static func perform(
        name: String,
        from remoteURL: URL,
        to fileURL: URL,
        onEvent: (@Sendable (Event) -> Void)?
    ) async throws -> URL {
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: URLRequest(url: remoteURL))
        let expectedLength = response.expectedContentLength

        let statusIdentifier = "\(name)_\(Entropy.uniqueId)"
        var identifier = ProgressIdentifier(
            statusIdentifier: statusIdentifier,
            statusString: "Downloading \(name)..."
        )

        guard let output = OutputStream(url: fileURL, append: false) else {
            throw URLError(.cannotOpenFile)
        }
        output.open()
        defer { output.close() }

        onEvent?(.start(identifier))

        var buffer = Data(capacity: bufferSize)
        var bytesReceived: Int64 = 0

        for try await byte in asyncBytes {
            bytesReceived += 1
            buffer.append(byte)

            if buffer.count >= bufferSize {
                // Check once per flush rather than per byte to avoid per-byte overhead
                try Task.checkCancellation()
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                identifier.fractionCompleted = fraction(received: bytesReceived, expected: expectedLength)
                onEvent?(.progress(identifier))
            }
        }

        // Flush any remaining buffered bytes
        if !buffer.isEmpty {
            try output.write(buffer)
        }

        identifier.fractionCompleted = 1.0
        onEvent?(.complete(identifier))

        return fileURL
    }

    /// Computes download fraction. When content-length is unknown, the denominator
    /// stays ahead of `received` so progress never falsely reaches 100% mid-stream.
    private static func fraction(received: Int64, expected: Int64) -> Double {
        guard expected > 0 else {
            return Double(received) / Double(received + estimatedFallbackSize)
        }
        return min(1.0, Double(received) / Double(expected))
    }
}

// MARK: - OutputStream

private extension OutputStream {
    func write(_ data: Data) throws {
        guard !data.isEmpty else { return }
        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) throws in
            guard var pointer = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw URLError(.cannotCreateFile)
            }
            var remaining = raw.count
            while remaining > 0 {
                let written = write(pointer, maxLength: remaining)
                guard written > 0 else { throw URLError(.cannotWriteToFile) }
                pointer += written
                remaining -= written
            }
        }
    }
}
