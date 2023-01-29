import Foundation

public protocol InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: (Result<URLRequest, Error>) -> Void
    )
    func willRequest(_ request: URLRequest, endpoint: EndpointType)
    func process(
        _ result: DataResponse,
        endpoint: EndpointType,
        completion: (Result<DataResponse, Error>) -> Void
    )
    func didReceive(_ result: DataResponse, endpoint: EndpointType)
}

public extension InterceptorType {
    func prepare(
        _ request: URLRequest,
        endpoint: EndpointType,
        completion: (Result<URLRequest, Error>) -> Void
    ) { completion(.success(request)) }
    func willRequest(_ request: URLRequest, endpoint: EndpointType) { }
    func process(
        _ result: DataResponse,
        endpoint: EndpointType,
        completion: (Result<DataResponse, Error>) -> Void
    ) { completion(.success(result)) }
    func didReceive(_ result: DataResponse, endpoint: EndpointType) { }
}
