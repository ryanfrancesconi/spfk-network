// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import Testing

@testable import SPFKNetwork

@Suite
final class NetworkIORequestTests {
    private let url = URL(string: "https://example.com/api")!

    // MARK: - HTTP method

    @Test func defaultMethodIsPost() {
        let request = NetworkIO.createRequest(from: url)
        #expect(request.httpMethod == "POST")
    }

    @Test func getMethod() {
        let request = NetworkIO.createRequest(from: url, httpMethod: .get)
        #expect(request.httpMethod == "GET")
    }

    @Test func putMethod() {
        let request = NetworkIO.createRequest(from: url, httpMethod: .put)
        #expect(request.httpMethod == "PUT")
    }

    @Test func deleteMethod() {
        let request = NetworkIO.createRequest(from: url, httpMethod: .delete)
        #expect(request.httpMethod == "DELETE")
    }

    // MARK: - Authorization header

    @Test func accessTokenSetsBearerHeader() {
        let request = NetworkIO.createRequest(from: url, accessToken: "tok_abc123")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok_abc123")
    }

    @Test func nilAccessTokenOmitsAuthorizationHeader() {
        let request = NetworkIO.createRequest(from: url, accessToken: nil)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    // MARK: - Accept header

    @Test func acceptJsonHeader() {
        let request = NetworkIO.createRequest(from: url, accept: .json)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func acceptXmlHeader() {
        let request = NetworkIO.createRequest(from: url, accept: .xml)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/xml")
    }

    @Test func nilAcceptOmitsAcceptHeader() {
        let request = NetworkIO.createRequest(from: url, accept: nil)
        #expect(request.value(forHTTPHeaderField: "Accept") == nil)
    }

    // MARK: - Body

    @Test func httpBodyIsSet() {
        let body = Data("payload".utf8)
        let request = NetworkIO.createRequest(from: url, httpBody: body)
        #expect(request.httpBody == body)
    }

    @Test func nilHttpBodyIsAbsent() {
        let request = NetworkIO.createRequest(from: url, httpBody: nil)
        #expect(request.httpBody == nil)
    }

    // MARK: - Timeout

    @Test func timeoutIs240Seconds() {
        let request = NetworkIO.createRequest(from: url)
        #expect(request.timeoutInterval == 240)
    }

    // MARK: - URL

    @Test func urlIsPreserved() {
        let request = NetworkIO.createRequest(from: url)
        #expect(request.url == url)
    }
}
