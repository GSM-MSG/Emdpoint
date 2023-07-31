import Foundation

public protocol ParameterEncodable {
    func encode(request: inout URLRequest, with parameter: [String: Any]) throws
}
