import Foundation

public protocol InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: (Result<URLRequest, Error>) -> Void
    )
    func willRequest(_ request: URLRequest, endpoint: EndpointType)
    func process(
        _ result: Result<DataResponse, Error>,
        endpoint: EndpointType,
        completion: (Result<DataResponse, Error>) -> Void
    )
    func didReceive(_ result: Result<DataResponse, Error>, endpoint: EndpointType)
}

public extension InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: (Result<URLRequest, Error>) -> Void
    ) { completion(.success(request)) }
    func willRequest(_ request: URLRequest, endpoint: EndpointType) { }
    func process(
        _ result: Result<DataResponse, Error>,
        endpoint: EndpointType,
        completion: (Result<DataResponse, Error>) -> Void
    ) { completion(result) }
    func didReceive(_ result: Result<DataResponse, Error>, endpoint: EndpointType) { }
}
