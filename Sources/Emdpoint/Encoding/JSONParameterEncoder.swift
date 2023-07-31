import Foundation

public struct JSONParameterEncoder: ParameterEncodable {
    public let options: JSONSerialization.WritingOptions

    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    public func encode(request: inout URLRequest, with parameter: [String: Any]) throws {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: options)
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            throw EmdpointError.encodingFailed
        }
    }
}

public extension ParameterEncodable where Self == JSONParameterEncoder {
    static func json(options: JSONSerialization.WritingOptions = []) -> JSONParameterEncoder {
        JSONParameterEncoder(options: options)
    }
}
