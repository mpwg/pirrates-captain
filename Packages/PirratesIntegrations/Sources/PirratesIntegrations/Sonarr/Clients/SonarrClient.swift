import Foundation
import PirratesCore

public struct SonarrClient {
    public let profile: ServerProfile

    public init(profile: ServerProfile) {
        self.profile = profile
    }
}
