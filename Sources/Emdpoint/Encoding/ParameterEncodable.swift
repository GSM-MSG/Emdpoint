import Foundation

public protocol ParameterEncodable {
    static func encode(request: inout URLRequest, with parameter: [String: Any]) throws
}
