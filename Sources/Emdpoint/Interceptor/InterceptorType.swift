import Foundation

public protocol InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: @escaping (Result<URLRequest, EmdpointError>) -> Void
    )
    func willRequest(_ request: URLRequest, endpoint: EndpointType)
    func process(
        _ result: Result<DataResponse, EmdpointError>,
        endpoint: EndpointType,
        completion: @escaping (Result<DataResponse, EmdpointError>) -> Void
    )
    func didReceive(_ result: Result<DataResponse, EmdpointError>, endpoint: EndpointType)
}

public extension InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: @escaping (Result<URLRequest, EmdpointError>) -> Void
    ) { completion(.success(request)) }
    func willRequest(_ request: URLRequest, endpoint: EndpointType) { }
    func process(
        _ result: Result<DataResponse, EmdpointError>,
        endpoint: EndpointType,
        completion: @escaping (Result<DataResponse, EmdpointError>) -> Void
    ) { completion(result) }
    func didReceive(_ result: Result<DataResponse, EmdpointError>, endpoint: EndpointType) { }
}
