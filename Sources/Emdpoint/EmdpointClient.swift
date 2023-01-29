import Combine
import Foundation

public final class EmdpointClient<Endpoint: EndpointType>: EmdpointClientProtocol {
    private var interceptors: [any InterceptorType] = []

    public init(interceptors: [any InterceptorType]) {
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
        completion: @escaping (Result<DataResponse, Error>) -> Void
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
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error))
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
    ) -> AnyPublisher<DataResponse, Error> {
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

    func requestNetworking(
        _ request: URLRequest,
        endpoint: Endpoint,
        completion: @escaping (Result<DataResponse, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let response {
                let dataResponse = DataResponse(data: data ?? .init(), response: response)
                self.interceptResponse(
                    response: dataResponse,
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
        completion: (Result<URLRequest, Error>) -> Void
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
        response: DataResponse,
        endpoint: EndpointType,
        using interceptors: [any InterceptorType],
        completion: (Result<DataResponse, Error>) -> Void
    ) {
        var pendingInterceptors = interceptors
        guard !pendingInterceptors.isEmpty else {
            completion(.success(response))
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
                self.interceptResponse(
                    response: newResponse,
                    endpoint: endpoint,
                    using: pendingInterceptors,
                    completion: completion
                )

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
