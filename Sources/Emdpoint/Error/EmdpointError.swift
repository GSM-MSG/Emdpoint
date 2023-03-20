import Foundation

public enum EmdpointError: Error {
    case encodingFailed
    case networkError
    case notFoundOwner
}

extension EmdpointError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "failed to encoding parameters"

        case .networkError:
            return "failed to request"

        case .notFoundOwner:
            return "this error occured arc"
        }
    }
}

extension EmdpointError {
    var underlyingError: Swift.Error? {
        return nil
    }
}

extension EmdpointError: CustomNSError {
    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        userInfo[NSUnderlyingErrorKey] = underlyingError
        return userInfo
    }
}
