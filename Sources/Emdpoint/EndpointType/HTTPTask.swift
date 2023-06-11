import Foundation

public enum HTTPTask {
    case requestPlain
    case requestParameters(body: [String: Any]? = nil, query: [String: Any]? = nil)
    case requestJSONEncodable(_ encodable: any Encodable, query: [String: Any]? = nil)
    case uploadMultipart([MultiPartFormData])
}

public extension HTTPTask {
    func configureRequest(request: inout URLRequest) throws {
        switch self {
        case .requestPlain:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case let .requestParameters(body, query):
            try configureParams(body: body, query: query, request: &request)

        case let .requestJSONEncodable(encodable, query):
            try configureEncodable(encodable: encodable, query: query, request: &request)

        case let .uploadMultipart(multiParts):
            try configureMultiparts(formDatas: multiParts, request: &request)
        }
    }

    func configureParams(
        body: [String: Any]?,
        query: [String: Any]?,
        request: inout URLRequest
    ) throws {
        if let body {
            try JSONParameterEncoder.encode(request: &request, with: body)
        }
        if let query {
            try URLQueryEncoder.encode(request: &request, with: query)
        }
    }

    func configureEncodable(
        encodable: any Encodable,
        query: [String: Any]?,
        request: inout URLRequest
    ) throws {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(encodable)

        if let query {
            try URLQueryEncoder.encode(request: &request, with: query)
        }
    }

    func configureMultiparts(
        formDatas: [MultiPartFormData],
        request: inout URLRequest
    ) throws {
        let boundary = String(
            format: "request.boundary.%08x%08x",
            UInt32.random(in: .min ... .max),
            UInt32.random(in: .min ... .max)
        )
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let bodyData = buildFormBodyData(formDatas: formDatas, boundary: boundary)
        request.httpBody = bodyData
    }

    func buildFormBodyData(
        formDatas: [MultiPartFormData],
        boundary: String
    ) -> Data {
        var formBody = Data()
        let boundaryPrefix = "\r\n--\(boundary)\r\n"
        for formData in formDatas {
            formBody.append(boundaryPrefix.data(using: .utf8) ?? .init())
            if let filename = formData.fileName, !filename.isEmpty {
                formBody.append("Content-Disposition: form-data; name=\"\(formData.field)\"; filename=\"\(filename)\"\r\n".data(using: .utf8) ?? .init())
            } else {
                formBody.append("Content-Disposition: form-data; name=\"\(formData.field)\"\r\n\r\n".data(using: .utf8) ?? .init())
            }
            formBody.append(
                "Content-Type: image/\(formData.fileName?.components(separatedBy: ".").last ?? "png")\r\n\r\n"
                    .data(using: .utf8) ?? .init()
            )
            formBody.append(formData.data)
            formBody.append("\r\n".data(using: .utf8) ?? .init())
        }
        formBody.append(boundaryPrefix.data(using: .utf8) ?? .init())
        return formBody
    }
}
