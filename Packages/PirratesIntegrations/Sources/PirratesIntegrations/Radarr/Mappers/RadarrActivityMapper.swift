import Foundation
import PirratesCore

enum RadarrActivityMapper {
    static func mapQueue(_ dto: RadarrQueueRecordDTO, profile: ServerProfile, now: Date = .now) -> ActivityItem? {
        let title = cleaned(dto.movie?.title) ?? cleaned(dto.title)
        guard let title else { return nil }

        let detail = [
            cleaned(dto.status) ?? cleaned(dto.trackedDownloadStatus) ?? cleaned(dto.trackedDownloadState),
            cleaned(dto.timeleft).map { "ETA \($0)" },
        ]
            .compactMap { $0 }
            .joined(separator: " • ")

        return ActivityItem(
            title: title,
            detail: detail.isEmpty ? "Queued download" : detail,
            progress: progress(size: dto.size, sizeLeft: dto.sizeleft),
            service: .radarr,
            serverName: profile.name,
            category: .queue,
            date: dto.estimatedCompletionTime ?? now
        )
    }

    static func mapHistory(_ dto: RadarrHistoryRecordDTO, profile: ServerProfile, now: Date = .now) -> ActivityItem? {
        let title = cleaned(dto.movie?.title) ?? cleaned(dto.sourceTitle)
        guard let title else { return nil }

        let detail = cleaned(dto.eventType)
            .map(formatEventType) ?? "History event"

        return ActivityItem(
            title: title,
            detail: detail,
            service: .radarr,
            serverName: profile.name,
            category: .history,
            date: dto.date ?? now
        )
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func progress(size: Double?, sizeLeft: Double?) -> Double? {
        guard let size, let sizeLeft, size > 0 else { return nil }
        return min(max((size - sizeLeft) / size, 0), 1)
    }

    private static func formatEventType(_ value: String) -> String {
        value
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
