import Foundation

public struct APIRequest: Sendable {
    public let path: String
    public let method: String
    public let queryItems: [URLQueryItem]
    public let body: Data?

    public init(path: String, method: String = "GET", queryItems: [URLQueryItem] = [], body: Data? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
    }
}

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}

public enum RequestBuilder {
    public static func makeURLRequest(
        for profile: ServerProfile,
        apiKey: String?,
        request: APIRequest
    ) throws -> URLRequest {
        guard var components = URLComponents(url: profile.baseURL, resolvingAgainstBaseURL: false) else {
            throw AppError.validationFailed("Invalid base URL.")
        }

        components.path = request.path
        components.queryItems = request.queryItems

        guard let url = components.url else {
            throw AppError.validationFailed("Could not create request URL.")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        if let apiKey, !apiKey.isEmpty {
            urlRequest.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }
        if request.body != nil {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}

public enum ErrorMapper {
    public static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .notConnectedToInternet, .timedOut:
                return .unreachableServer
            default:
                return .unknown(urlError.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }
}

public enum ResponseValidator {
    public static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown("The server returned an invalid response.")
        }

        switch httpResponse.statusCode {
        case 200 ..< 300:
            return
        case 401, 403:
            throw AppError.authenticationFailed
        case 429:
            throw AppError.rateLimited
        default:
            throw AppError.unknown("The server returned HTTP \(httpResponse.statusCode).")
        }
    }
}
