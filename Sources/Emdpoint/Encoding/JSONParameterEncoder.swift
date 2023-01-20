import Foundation

struct JSONParameterEncoder: ParameterEncodable {
    static func encode(request: inout URLRequest, with parameter: [String : Any]) throws {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            throw EmdpointError.encodingFailed
        }
    }
}
