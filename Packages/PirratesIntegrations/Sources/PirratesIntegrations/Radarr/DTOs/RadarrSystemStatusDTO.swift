import Foundation

public struct RadarrSystemStatusDTO: Codable, Equatable, Sendable {
    public let appName: String?
    public let version: String?

    public init(appName: String?, version: String?) {
        self.appName = appName
        self.version = version
    }
}
