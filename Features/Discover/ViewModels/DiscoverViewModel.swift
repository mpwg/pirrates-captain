import Observation
import PirratesCore

@MainActor
@Observable
final class DiscoverViewModel {
    var query = ""
    var state: LoadPhase<[SearchResult]> = .idle
    var selectedResult: SearchResult?
    var addContext: DiscoverAddContext?
    var isPreparingAdd = false
    var isAdding = false
    var addError: AppError?

    private let discoverProvider: any DiscoverProviding

    init(discoverProvider: any DiscoverProviding) {
        self.discoverProvider = discoverProvider
    }

    func search() async {
        state = .loading
        addError = nil

        do {
            let results = try await discoverProvider.search(query: query)
            state = .loaded(results)
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }

    func beginAddFlow(for result: SearchResult) {
        selectedResult = result
        addContext = nil
        addError = nil
        isPreparingAdd = true

        Task {
            do {
                let context = try await discoverProvider.prepareAdd(for: result)
                guard selectedResult?.id == result.id else { return }
                addContext = context
            } catch {
                guard selectedResult?.id == result.id else { return }
                addError = ErrorMapper.map(error)
            }

            guard selectedResult?.id == result.id else { return }
            isPreparingAdd = false
        }
    }

    func completeAddFlow() {
        selectedResult = nil
        addContext = nil
        addError = nil
        isPreparingAdd = false
        isAdding = false
    }

    func submitAdd(using configuration: DiscoverAddConfiguration) async {
        guard let selectedResult else { return }

        isAdding = true
        addError = nil

        do {
            try await discoverProvider.add(result: selectedResult, configuration: configuration)
            completeAddFlow()
        } catch {
            addError = ErrorMapper.map(error)
            isAdding = false
        }
    }
}
