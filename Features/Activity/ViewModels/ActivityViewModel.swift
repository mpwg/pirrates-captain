import Observation
import PirratesCore

@MainActor
@Observable
final class ActivityViewModel {
    var state: LoadPhase<[ActivityItem]> = .idle

    private let activityProvider: any ActivityProviding

    init(activityProvider: any ActivityProviding) {
        self.activityProvider = activityProvider
    }

    func load() async {
        state = .loading

        do {
            state = .loaded(try await activityProvider.loadActivity())
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }
}
