import Foundation

public enum AnyEndpoint: EndpointType {
    case endpoint(any EndpointType)

    public init(_ endpoint: any EndpointType) {
        self = .endpoint(endpoint)
    }

    public var endpoint: any EndpointType {
        switch self {
        case let .endpoint(endpoint):
            return endpoint
        }
    }

    public var baseURL: URL { endpoint.baseURL }

    public var route: Route { endpoint.route }

    public var sampleData: Data { endpoint.sampleData }

    public var task: HTTPTask { endpoint.task }

    public var validationCode: ClosedRange<Int> { endpoint.validationCode }

    public var headers: [String: String]? { endpoint.headers }

    public var timeout: TimeInterval { endpoint.timeout }
}
