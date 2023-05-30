import Foundation

public extension URL {
    init<Endpoint: EndpointType>(endpoint: Endpoint) {
        let path = endpoint.route.path
        if path.isEmpty {
            self = endpoint.baseURL
        } else {
            self = endpoint.baseURL.appendPath(path: path)
        }
    }
}

private extension URL {
    func appendPath(path: String) -> URL {
        if #available(iOS 16.0, *) {
            return self.appending(path: path)
        } else {
            return self.appendingPathComponent(path)
        }
    }
}
