import Foundation

public struct MultiPartFormData {
    public let field: String
    public let data: Data
    public let fileName: String?

    public init(field: String, data: Data, fileName: String? = nil) {
        self.field = field
        self.data = data
        self.fileName = fileName
    }
}
