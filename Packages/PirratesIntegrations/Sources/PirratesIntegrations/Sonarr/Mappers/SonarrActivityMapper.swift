import Foundation
import PirratesCore

enum SonarrActivityMapper {
    static func mapQueue(_ dto: SonarrQueueRecordDTO, profile: ServerProfile, now: Date = .now) -> ActivityItem? {
        let title = cleaned(dto.series?.title) ?? cleaned(dto.title) ?? cleaned(dto.episode?.title)
        guard let title else { return nil }

        let detail = [
            secondaryTitle(primaryTitle: title, candidate: dto.title),
            cleaned(dto.status) ?? cleaned(dto.trackedDownloadStatus) ?? cleaned(dto.trackedDownloadState),
            cleaned(dto.timeleft).map { "ETA \($0)" },
        ]
            .compactMap { $0 }
            .joined(separator: " • ")

        return ActivityItem(
            title: title,
            detail: detail.isEmpty ? "Queued download" : detail,
            progress: progress(size: dto.size, sizeLeft: dto.sizeleft),
            service: .sonarr,
            serverName: profile.name,
            category: .queue,
            date: dto.estimatedCompletionTime ?? now
        )
    }

    static func mapHistory(_ dto: SonarrHistoryRecordDTO, profile: ServerProfile, now: Date = .now) -> ActivityItem? {
        let title = cleaned(dto.series?.title) ?? cleaned(dto.sourceTitle) ?? cleaned(dto.episode?.title)
        guard let title else { return nil }

        let detail = [
            secondaryTitle(primaryTitle: title, candidate: dto.episode?.title),
            cleaned(dto.eventType).map(formatEventType),
        ]
            .compactMap { $0 }
            .joined(separator: " • ")

        return ActivityItem(
            title: title,
            detail: detail.isEmpty ? "History event" : detail,
            service: .sonarr,
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

    private static func secondaryTitle(primaryTitle: String, candidate: String?) -> String? {
        guard let candidate = cleaned(candidate), candidate != primaryTitle else {
            return nil
        }
        return candidate
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
