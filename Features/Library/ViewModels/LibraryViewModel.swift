import Observation
import PirratesCore

@MainActor
@Observable
final class LibraryViewModel {
    var state: LoadPhase<[LibraryItem]> = .idle

    private let libraryProvider: any LibraryProviding

    init(libraryProvider: any LibraryProviding) {
        self.libraryProvider = libraryProvider
    }

    func load() async {
        state = .loading

        do {
            state = .loaded(try await libraryProvider.loadLibrary())
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }
}
