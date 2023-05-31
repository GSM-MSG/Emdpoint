import Combine
import Foundation

public final class EmdpointClient<Endpoint: EndpointType>: EmdpointClientProtocol {
    private var interceptors: [any InterceptorType] = []

    public init(interceptors: [any InterceptorType] = []) {
        self.interceptors = interceptors
    }

    public func setInterceptors(interceptors: [any InterceptorType]) {
        self.interceptors = interceptors
    }

    public func addInterceptor(interceptor: any InterceptorType) {
        self.interceptors.append(interceptor)
    }

    public func removeAllInterceptor() {
        self.interceptors.removeAll()
    }

    public func request(
        _ endpoint: Endpoint,
        completion: @escaping (Result<DataResponse, EmdpointError>) -> Void
    ) {
        do {
            let request = try configureURLRequest(from: endpoint)
            interceptRequest(
                request,
                endpoint: endpoint,
                using: self.interceptors
            ) { [weak self] result in
                guard let self = self else {
                    completion(.failure(EmdpointError.notFoundOwner))
                    return
                }
                switch result {
                case let .success(request):
                    self.requestNetworking(request, endpoint: endpoint, completion: completion)

                case let .failure(error):
                    if let emdpointError = error as? EmdpointError {
                        completion(.failure(emdpointError))
                    }
                    completion(.failure(EmdpointError.underlying(error)))
                }
            }
            
        } catch {
            if let emdpointError = error as? EmdpointError {
                completion(.failure(emdpointError))
            }
            completion(.failure(EmdpointError.underlying(error)))
        }
    }

    public func request(_ endpoint: Endpoint) async throws -> DataResponse {
        try await withCheckedThrowingContinuation { config in
            self.request(endpoint) { result in
                config.resume(with: result)
            }
        }
    }

    public func requestPublisher(
        _ endpoint: Endpoint
    ) -> AnyPublisher<DataResponse, EmdpointError> {
        Future { fulfill in
            self.request(endpoint) { result in
                fulfill(result)
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension EmdpointClient {
    func configureURLRequest(from endpoint: Endpoint) throws -> URLRequest {
        let requestURL: URL = URL(endpoint: endpoint)
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

    func requestNetworking(
        _ request: URLRequest,
        endpoint: Endpoint,
        completion: @escaping (Result<DataResponse, EmdpointError>) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                if let emdpointError = error as? EmdpointError {
                    completion(.failure(emdpointError))
                }
                completion(.failure(EmdpointError.underlying(error)))
                return
            }

            if let response {
                let dataResponse = DataResponse(
                    request: request,
                    data: data ?? .init(),
                    response: response
                )
                self.interceptResponse(
                    response: .success(dataResponse),
                    endpoint: endpoint,
                    using: self.interceptors,
                    completion: completion
                )
                return
            }

            completion(.failure(EmdpointError.networkError))
        }.resume()
    }

    // MARK: - Interceptor
    func interceptRequest(
        _ request: URLRequest,
        endpoint: EndpointType,
        using interceptors: [any InterceptorType],
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var pendingInterceptors = interceptors
        guard !pendingInterceptors.isEmpty else {
            completion(.success(request))
            return
        }

        let interceptor = pendingInterceptors.removeFirst()
        interceptor.willRequest(request, endpoint: endpoint)
        interceptor.prepare(request, endpoint: endpoint) { [weak self] result in
            guard let self = self else {
                completion(.failure(EmdpointError.notFoundOwner))
                return
            }
            switch result {
            case let .success(newRequest):
                self.interceptRequest(
                    newRequest,
                    endpoint: endpoint,
                    using: pendingInterceptors,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func interceptResponse(
        response: Result<DataResponse, EmdpointError>,
        endpoint: EndpointType,
        using interceptors: [any InterceptorType],
        completion: @escaping (Result<DataResponse, EmdpointError>) -> Void
    ) {
        var pendingInterceptors = interceptors
        guard !pendingInterceptors.isEmpty else {
            if case let .success(response) = response,
               let httpResponse = response.response as? HTTPURLResponse,
               !(endpoint.validationCode ~= httpResponse.statusCode) {
                completion(.failure(EmdpointError.statusCode(response)))
                return
            }
            completion(response)
            return
        }

        let interceptor = pendingInterceptors.removeFirst()
        interceptor.didReceive(response, endpoint: endpoint)
        interceptor.process(response, endpoint: endpoint) { [weak self] result in
            guard let self = self else {
                completion(.failure(EmdpointError.notFoundOwner))
                return
            }
            switch result {
            case let .success(newResponse):
                if let httpResponse = newResponse.response as? HTTPURLResponse,
                   !(endpoint.validationCode ~= httpResponse.statusCode) {
                    self.interceptResponse(
                        response: .failure(EmdpointError.statusCode(newResponse)),
                        endpoint: endpoint,
                        using: pendingInterceptors,
                        completion: completion
                    )
                    return
                }
                self.interceptResponse(
                    response: .success(newResponse),
                    endpoint: endpoint,
                    using: pendingInterceptors,
                    completion: completion
                )

            case let .failure(error):
                self.interceptResponse(
                    response: .failure(error),
                    endpoint: endpoint,
                    using: pendingInterceptors,
                    completion: completion
                )
            }
        }
    }
}
