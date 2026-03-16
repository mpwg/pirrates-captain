import Foundation

struct RootFolderDTO: Decodable, Sendable {
    let id: Int
    let path: String
    let accessible: Bool
}
