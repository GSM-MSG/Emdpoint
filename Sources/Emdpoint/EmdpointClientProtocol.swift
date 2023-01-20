import Combine
import Foundation

public protocol EmdpointClientProtocol {
    associatedtype Endpoint: EndpointType

    func request(
        _ endpoint: Endpoint,
        completion: @escaping (Result<DataResponse, Error>) -> Void
    )
    func request(_ endpoint: Endpoint) async throws -> DataResponse
    func requestPublisher(_ endpoint: Endpoint) -> AnyPublisher<DataResponse, Error>
}
