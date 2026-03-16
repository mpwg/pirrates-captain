import Foundation
import PirratesCore

public struct UnsupportedServerConnectionValidator: ServerConnectionValidating {
    public init() {}

    public func validateServer(_ profile: ServerProfile, apiKey: String?) async throws {
        return
    }
}
