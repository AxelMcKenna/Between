import EventKit
import Foundation

/// Fetches calendar events and extracts only start/end times
/// No event metadata is retained beyond what's needed for interval computation
final class EventsRepository {

    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    /// Fetches busy intervals for a given day
    /// Only returns start/end times - all other metadata is discarded immediately
    func fetchBusyIntervals(for date: Date) -> [TimeBlock] {
        let calendar = Calendar.current

        guard let dayStart = calendar.startOfDay(for: date) as Date?,
              let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        // Extract only start/end times, discard all metadata immediately
        return events.compactMap { event -> TimeBlock? in
            guard let start = event.startDate,
                  let end = event.endDate else {
                return nil
            }

            // Skip all-day events or events that don't have valid times
            if event.isAllDay {
                return nil
            }

            // Clamp to day boundaries
            let clampedStart = max(start, dayStart)
            let clampedEnd = min(end, dayEnd)

            guard clampedStart < clampedEnd else {
                return nil
            }

            return TimeBlock(start: clampedStart, end: clampedEnd)
        }
    }
}
