import Foundation

struct URLQueryEncoder: ParameterEncodable {
    static func encode(request: inout URLRequest, with parameter: [String : Any]) throws {
        guard let url = request.url else { throw EmdpointError.encodingFailed }

        if var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameter.isEmpty {
            urlComponent.queryItems = .init()
            let queryItems = parameter.map {
                URLQueryItem(name: $0.key, value: $0.value as? String ?? "")
            }
            urlComponent.queryItems = queryItems
            request.url = urlComponent.url
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
    }
}
