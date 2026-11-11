// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKNetwork

@Suite
final class NetworkIORequestTests {
    private let url = URL(string: "https://example.com/api")!

    // MARK: - Authorization header

    @Test func accessTokenSetsBearerHeader() {
        let request = NetworkIO.createRequest(from: url, accessToken: "tok_abc123")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok_abc123")
    }
}
