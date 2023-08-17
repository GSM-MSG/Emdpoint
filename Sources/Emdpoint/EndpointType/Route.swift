import Foundation

public enum Route {
    case get(String)
    case head(String)
    case post(String)
    case put(String)
    case patch(String)
    case delete(String)
    case options(String)
    case trace(String)
    case connect(String)

    var method: String {
        switch self {
        case .get:
            return "GET"

        case .head:
            return "HEAD"

        case .post:
            return "POST"

        case .put:
            return "PUT"

        case .patch:
            return "PATCH"

        case .delete:
            return "DELETE"

        case .options:
            return "OPTIONS"

        case .trace:
            return "TRACE"

        case .connect:
            return "CONNECT"
        }
    }

    var path: String {
        switch self {
        case let .get(path),
            let .head(path),
            let .post(path),
            let .put(path),
            let .patch(path),
            let .delete(path),
            let .options(path),
            let .trace(path),
            let .connect(path):
            return path
        }
    }
}

