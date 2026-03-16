import Observation
import PirratesCore

@MainActor
@Observable
final class DiscoverViewModel {
    var query = ""
    var state: LoadPhase<[SearchResult]> = .idle

    private let discoverProvider: any DiscoverProviding

    init(discoverProvider: any DiscoverProviding) {
        self.discoverProvider = discoverProvider
    }

    func search() async {
        state = .loading

        do {
            let results = try await discoverProvider.search(query: query)
            state = .loaded(results)
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }
}
