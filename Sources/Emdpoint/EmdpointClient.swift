import Combine
import Foundation

public final class EmdpointClient<Endpoint: EndpointType>: EmdpointClientProtocol {
    public func request(
        _ endpoint: Endpoint,
        completion: @escaping (Result<DataResponse, Error>) -> Void
    ) {
        do {
            let request = try configureURLRequest(from: endpoint)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                if let response {
                    completion(.success(
                        DataResponse(data: data ?? .init(), response: response)
                    ))
                    return
                }

                completion(.failure(EmdpointError.networkError))
            }
        } catch {
            completion(.failure(error))
        }
    }

    public func request(_ endpoint: Endpoint) async throws -> DataResponse {
        let request = try configureURLRequest(from: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        return DataResponse(data: data, response: response)
    }

    public func requestPublisher(_ endpoint: Endpoint) -> AnyPublisher<DataResponse, Error> {
        do {
            let request = try configureURLRequest(from: endpoint)
            return URLSession.shared.dataTaskPublisher(for: request)
                .map { DataResponse(data: $0.data, response: $0.response) }
                .mapError { $0 }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}

private extension EmdpointClient {
    func configureURLRequest(from endpoint: Endpoint) throws -> URLRequest {
        var requestURL: URL
        if #available(iOS 16.0, *) {
            requestURL = endpoint.baseURL.appending(path: endpoint.route.path)
        } else {
            requestURL = endpoint.baseURL.appendingPathComponent(endpoint.route.path)
        }
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: endpoint.timeout
        )
        request.httpMethod = endpoint.route.method

        try endpoint.task.configureRequest(request: &request)

        if let headers = endpoint.headers {
            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }

        return request
    }
}
