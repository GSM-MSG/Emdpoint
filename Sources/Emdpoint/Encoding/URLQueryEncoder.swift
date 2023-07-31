import Foundation

/// Credits By https://github.com/Alamofire/Alamofire/blob/master/Source/ParameterEncoding.swift
public struct URLQueryEncoder: ParameterEncodable {
    public enum ArrayEncoding {
        /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
        /// \(key)[]
        case brackets
        /// No brackets are appended. The key is encoded as is.
        case noBrackets
        /// Brackets containing the item index are appended. This matches the jQuery and Node.js behavior.
        /// \(key)[\(index)]
        case indexInBrackets
        /// Provide a custom array key encoding with the given closure.
        case custom((_ key: String, _ index: Int) -> String)

        func encode(key: String, atIndex index: Int) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            case .indexInBrackets:
                return "\(key)[\(index)]"
            case let .custom(encoding):
                return encoding(key, index)
            }
        }
    }

    public enum BoolEncoding {
        /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
        case numeric
        /// Encode `true` and `false` as string literals.
        case literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }

    public let arrayEncoding: ArrayEncoding
    public let boolEncoding: BoolEncoding

    init(arrayEncoding: ArrayEncoding = .noBrackets, boolEncoding: BoolEncoding = .literal) {
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }

    public func encode(request: inout URLRequest, with parameter: [String: Any]) throws {
        guard let url = request.url else { throw EmdpointError.missingURL }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameter.isEmpty {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameter)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            request.url = urlComponents.url
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
    }
}

private extension URLQueryEncoder {
    func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        switch value {
        case let dictionary as [String: Any]:
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }

        case let array as [Any]:
            for (index, value) in array.enumerated() {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key, atIndex: index), value: value)
            }

        case let number as NSNumber:
            if number.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: number.boolValue))))
            } else {
                components.append((escape(key), escape("\(number)")))
            }

        case let bool as Bool:
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))

        default:
            components.append((escape(key), escape("\(value)")))
        }
        return components
    }

    func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}

fileprivate extension NSNumber {
    var isBool: Bool {
        // Use Obj-C type encoding to check whether the underlying type is a `Bool`, as it's guaranteed as part of
        // swift-corelibs-foundation, per [this discussion on the Swift forums](https://forums.swift.org/t/alamofire-on-linux-possible-but-not-release-ready/34553/22).
        String(cString: objCType) == "c"
    }
}

public extension ParameterEncodable where Self == URLQueryEncoder {
    static func urlQuery(
        arrayEncoding: URLQueryEncoder.ArrayEncoding = .noBrackets,
        boolEncoding: URLQueryEncoder.BoolEncoding = .literal
    ) -> URLQueryEncoder {
        URLQueryEncoder(arrayEncoding: arrayEncoding, boolEncoding: boolEncoding)
    }
}

