import Foundation
import PirratesCore

public struct RadarrClient {
    public let profile: ServerProfile

    public init(profile: ServerProfile) {
        self.profile = profile
    }
}
