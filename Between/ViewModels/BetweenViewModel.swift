import Foundation
import Combine

/// ViewModel that handles busy interval merging and free gap computation
@MainActor
final class BetweenViewModel: ObservableObject {

    @Published private(set) var segments: [TimelineSegment] = []
    @Published private(set) var selectedDate: Date = Date()
    @Published private(set) var isLoading: Bool = false

    private let repository: EventsRepository

    /// Day range: 00:00 to 24:00
    private let dayStartHour: Int = 0
    private let dayEndHour: Int = 24

    /// Minimum gap duration to display (in seconds) - 5 minutes
    private let minimumGapDuration: TimeInterval = 5 * 60

    /// Adjacency threshold for merging nearby events (in seconds) - 1 minute
    private let adjacencyThreshold: TimeInterval = 60

    init(repository: EventsRepository = EventsRepository()) {
        self.repository = repository
    }

    /// Loads and processes events for the selected date
    func loadDay() {
        isLoading = true
        let busyIntervals = repository.fetchBusyIntervals(for: selectedDate)
        let mergedBusy = mergeBusyIntervals(busyIntervals)
        let dayRange = dayRange(for: selectedDate)
        let freeIntervals = computeFreeIntervals(busy: mergedBusy, dayRange: dayRange)

        // Build timeline segments
        var allSegments: [TimelineSegment] = []

        for block in mergedBusy {
            allSegments.append(TimelineSegment(block: block, type: .busy))
        }

        for block in freeIntervals {
            allSegments.append(TimelineSegment(block: block, type: .free))
        }

        // Sort by start time
        segments = allSegments.sorted { $0.start < $1.start }
        isLoading = false
    }

    /// Navigate to the next day
    func goToNextDay() {
        if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = next
            loadDay()
        }
    }

    /// Navigate to the previous day
    func goToPreviousDay() {
        if let previous = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = previous
            loadDay()
        }
    }

    /// Navigate to today
    func goToToday() {
        selectedDate = Date()
        loadDay()
    }

    /// Check if selected date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Interval Processing

    /// Merges overlapping and adjacent busy intervals
    func mergeBusyIntervals(_ intervals: [TimeBlock]) -> [TimeBlock] {
        guard !intervals.isEmpty else { return [] }

        // Sort by start time
        let sorted = intervals.sorted { $0.start < $1.start }

        var merged: [TimeBlock] = []
        var current = sorted[0]

        for i in 1..<sorted.count {
            let next = sorted[i]

            // Check for overlap or adjacency
            // next.start <= current.end means overlap
            // next.start <= current.end + threshold means adjacent
            let overlapOrAdjacent = next.start.timeIntervalSince(current.end) <= adjacencyThreshold

            if overlapOrAdjacent {
                // Merge: extend current to include next
                let newEnd = max(current.end, next.end)
                current = TimeBlock(start: current.start, end: newEnd)
            } else {
                // No overlap, save current and move to next
                merged.append(current)
                current = next
            }
        }

        // Don't forget the last interval
        merged.append(current)

        return merged
    }

    /// Computes free intervals as the complement of busy intervals within the day range
    func computeFreeIntervals(busy: [TimeBlock], dayRange: TimeBlock) -> [TimeBlock] {
        var freeIntervals: [TimeBlock] = []

        // Sort busy intervals by start time (should already be sorted after merge)
        let sortedBusy = busy.sorted { $0.start < $1.start }

        var currentStart = dayRange.start

        for busyBlock in sortedBusy {
            // If there's a gap between current position and busy block start
            if busyBlock.start > currentStart {
                let gap = TimeBlock(start: currentStart, end: busyBlock.start)

                // Only include gaps above minimum duration
                if gap.duration >= minimumGapDuration {
                    freeIntervals.append(gap)
                }
            }

            // Move current position to end of busy block
            currentStart = max(currentStart, busyBlock.end)
        }

        // Check for gap at end of day
        if currentStart < dayRange.end {
            let gap = TimeBlock(start: currentStart, end: dayRange.end)
            if gap.duration >= minimumGapDuration {
                freeIntervals.append(gap)
            }
        }

        return freeIntervals
    }

    /// Returns the day range for a given date
    func dayRange(for date: Date) -> TimeBlock {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        var startComponents = calendar.dateComponents([.year, .month, .day], from: dayStart)
        startComponents.hour = dayStartHour
        startComponents.minute = 0
        startComponents.second = 0

        var endComponents = calendar.dateComponents([.year, .month, .day], from: dayStart)
        endComponents.hour = dayEndHour
        endComponents.minute = 0
        endComponents.second = 0

        let start = calendar.date(from: startComponents) ?? dayStart
        let end = calendar.date(from: endComponents) ?? dayStart.addingTimeInterval(24 * 60 * 60)

        return TimeBlock(start: start, end: end)
    }
}
