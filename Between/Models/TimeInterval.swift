import Foundation

/// Represents a time interval with start and end times
struct TimeBlock: Equatable, Hashable {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Duration in minutes
    var durationMinutes: Double {
        duration / 60.0
    }
}

/// Represents the type of interval in the timeline
enum IntervalType {
    case free
    case busy
}

/// A segment to display in the timeline
struct TimelineSegment: Identifiable {
    let id = UUID()
    let block: TimeBlock
    let type: IntervalType

    var start: Date { block.start }
    var end: Date { block.end }
    var duration: TimeInterval { block.duration }
    var durationMinutes: Double { block.durationMinutes }
}
