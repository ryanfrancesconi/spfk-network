import Foundation

extension NetworkIO {
    public enum HttpMethod: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }

    public enum Accept: String {
        public static let header = "Accept"
        case json = "application/json"
        case xml = "application/xml"
        case all = "*/*"
    }

    public enum ContentType: String {
        public static let header = "Content-Type"
        case urlencodedForm = "application/x-www-form-urlencoded"
        case multipartForm = "multipart/form-data"
        case json = "application/json"
    }

    public enum Authorization: String {
        public static let header = "Authorization"
        case bearer = "Bearer"
    }
}
