import Foundation
import PirratesCore

public struct DownloadClient {
    public let profile: ServerProfile

    public init(profile: ServerProfile) {
        self.profile = profile
    }
}
