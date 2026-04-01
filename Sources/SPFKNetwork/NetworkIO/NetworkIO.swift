import Foundation
import SPFKBase

/// Lightweight namespace for common HTTP operations using `URLSession.shared`.
///
/// All functions load the full response into memory. Use `BufferedDownloader`
/// for large files where streaming and progress reporting are required.
public enum NetworkIO {
    /// Downloads a remote URL and writes the response body to `localURL`.
    ///
    /// - Parameters:
    ///   - remoteURL: The remote resource to fetch.
    ///   - localURL: The local file path to write the response body to.
    /// - Throws: A `URLError` or file-write error on failure.
    public static func download(from remoteURL: URL, to localURL: URL) async throws {
        let data = try await data(from: remoteURL)
        try data.write(to: localURL)
    }

    /// Fetches the response body from `url` as `Data`.
    ///
    /// - Parameter url: The URL to fetch.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func data(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    /// Fetches the response body for `request` as `Data`.
    ///
    /// - Parameter request: The `URLRequest` to perform.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func data(for request: URLRequest) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

extension NetworkIO {
    /// Sends a PUT request with `data` as the body and returns the response body.
    ///
    /// - Parameters:
    ///   - data: The request body.
    ///   - url: The target URL.
    ///   - accept: Optional `Accept` header value. Pass `nil` to omit the header.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func put(
        data: Data,
        url: URL,
        accept: Accept? = nil
    ) async throws -> Data {
        let request = NetworkIO.createRequest(from: url, httpMethod: .put, httpBody: data, accept: accept)
        return try await NetworkIO.data(for: request)
    }

    /// Sends a POST request with `query` items URL-encoded in the body.
    ///
    /// Sets `Content-Type: application/x-www-form-urlencoded`.
    ///
    /// - Parameters:
    ///   - query: The query items to encode into the request body.
    ///   - url: The target URL.
    ///   - accessToken: Optional Bearer token added to the `Authorization` header.
    ///   - accept: `Accept` header value. Defaults to `.json`.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func post(
        query: [URLQueryItem],
        to url: URL,
        accessToken: String? = nil,
        accept: Accept? = .json
    ) async throws -> Data {
        var request = createRequest(from: url, accessToken: accessToken, accept: accept)

        request.setValue(
            ContentType.urlencodedForm.rawValue,
            forHTTPHeaderField: ContentType.header
        )

        request.httpBody = URL.queryString(items: query).toData(using: .utf8)
        return try await NetworkIO.data(for: request)
    }

    /// Sends a POST request with a pre-encoded JSON body.
    ///
    /// Sets `Content-Type: application/json`.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - accessToken: Optional Bearer token added to the `Authorization` header.
    ///   - accept: `Accept` header value. Defaults to `.json`.
    ///   - json: The JSON-encoded request body.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func post(
        to url: URL,
        accessToken: String? = nil,
        accept: Accept = .json,
        json: Data
    ) async throws -> Data {
        var request = createRequest(from: url, accessToken: accessToken, accept: accept)

        request.setValue(
            ContentType.json.rawValue,
            forHTTPHeaderField: ContentType.header
        )

        request.httpBody = json

        return try await NetworkIO.data(for: request)
    }

    /// Fetches data from `url` using the specified HTTP method and optional Bearer token.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - accessToken: Optional Bearer token added to the `Authorization` header.
    ///   - httpMethod: The HTTP method to use. Defaults to `.get`.
    ///   - accept: `Accept` header value. Defaults to `.json`.
    /// - Returns: The raw response body.
    /// - Throws: A `URLError` on failure.
    public static func data(
        from url: URL,
        accessToken: String?,
        httpMethod: HttpMethod = .get,
        accept: Accept = .json
    ) async throws -> Data {
        let request = createRequest(from: url, httpMethod: httpMethod, accessToken: accessToken, accept: accept)
        return try await NetworkIO.data(for: request)
    }
}

extension NetworkIO {
    /// Builds a `URLRequest` with a 240-second timeout and optional auth, body, and Accept header.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - httpMethod: The HTTP method. Defaults to `.post`.
    ///   - httpBody: Optional request body data.
    ///   - accessToken: Optional Bearer token added to the `Authorization` header.
    ///   - accept: Optional `Accept` header value. Pass `nil` to omit the header.
    /// - Returns: A configured `URLRequest`.
    public static func createRequest(
        from url: URL,
        httpMethod: HttpMethod = .post,
        httpBody: Data? = nil,
        accessToken: String? = nil,
        accept: Accept? = .json
    ) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 240)

        request.httpMethod = httpMethod.rawValue

        if let accessToken {
            request.setValue(
                "\(Authorization.bearer.rawValue) \(accessToken)",
                forHTTPHeaderField: Authorization.header
            )
        }

        if let accept {
            request.setValue(accept.rawValue, forHTTPHeaderField: Accept.header)
        }

        if let httpBody {
            request.httpBody = httpBody
        }

        return request
    }
}
