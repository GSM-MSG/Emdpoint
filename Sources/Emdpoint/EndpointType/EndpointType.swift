import Foundation

public protocol EndpointType {
    var baseURL: URL { get }
    var route: Route { get }
    var sampleData: Data { get }
    var task: HTTPTask { get }
    var validationCode: ClosedRange<Int> { get }
    var headers: [String: String]? { get }
    var timeout: TimeInterval { get }
}

extension EndpointType {
    var sampleData: Data { .init() }
    var validationCode: ClosedRange<Int> { 200...300 }
    var timeout: TimeInterval { 300 }
}
