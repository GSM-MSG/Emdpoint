import Foundation

public struct DataResponse: Equatable, Hashable {
    public let request: URLRequest
    public let data: Data
    public let response: URLResponse
}
