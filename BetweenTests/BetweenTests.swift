import XCTest
@testable import Between

final class BetweenIntervalTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }

    private func makeBlock(startHour: Int, startMinute: Int = 0, endHour: Int, endMinute: Int = 0) -> TimeBlock {
        return TimeBlock(
            start: makeDate(hour: startHour, minute: startMinute),
            end: makeDate(hour: endHour, minute: endMinute)
        )
    }

    // MARK: - Merge Busy Intervals Tests

    func testMergeBusyIntervals_emptyInput() async {
        let viewModel = await BetweenViewModel()
        let result = await viewModel.mergeBusyIntervals([])
        XCTAssertTrue(result.isEmpty)
    }

    func testMergeBusyIntervals_singleInterval() async {
        let viewModel = await BetweenViewModel()
        let intervals = [makeBlock(startHour: 9, endHour: 10)]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 9))
        XCTAssertEqual(result[0].end, makeDate(hour: 10))
    }

    func testMergeBusyIntervals_nonOverlapping() async {
        let viewModel = await BetweenViewModel()
        let intervals = [
            makeBlock(startHour: 9, endHour: 10),
            makeBlock(startHour: 14, endHour: 15)
        ]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 2)
    }

    func testMergeBusyIntervals_overlapping() async {
        let viewModel = await BetweenViewModel()
        let intervals = [
            makeBlock(startHour: 9, endHour: 11),
            makeBlock(startHour: 10, endHour: 12)
        ]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 9))
        XCTAssertEqual(result[0].end, makeDate(hour: 12))
    }

    func testMergeBusyIntervals_adjacent() async {
        let viewModel = await BetweenViewModel()
        // Events within 1 minute should merge
        let intervals = [
            makeBlock(startHour: 9, endHour: 10),
            makeBlock(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0)
        ]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 9))
        XCTAssertEqual(result[0].end, makeDate(hour: 11))
    }

    func testMergeBusyIntervals_multipleOverlapping() async {
        let viewModel = await BetweenViewModel()
        let intervals = [
            makeBlock(startHour: 9, endHour: 10),
            makeBlock(startHour: 9, startMinute: 30, endHour: 11, endMinute: 0),
            makeBlock(startHour: 10, startMinute: 30, endHour: 12, endMinute: 0),
            makeBlock(startHour: 14, endHour: 15)
        ]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].start, makeDate(hour: 9))
        XCTAssertEqual(result[0].end, makeDate(hour: 12))
        XCTAssertEqual(result[1].start, makeDate(hour: 14))
        XCTAssertEqual(result[1].end, makeDate(hour: 15))
    }

    func testMergeBusyIntervals_unsortedInput() async {
        let viewModel = await BetweenViewModel()
        let intervals = [
            makeBlock(startHour: 14, endHour: 15),
            makeBlock(startHour: 9, endHour: 10),
            makeBlock(startHour: 11, endHour: 12)
        ]
        let result = await viewModel.mergeBusyIntervals(intervals)

        XCTAssertEqual(result.count, 3)
        // Should be sorted by start time
        XCTAssertEqual(result[0].start, makeDate(hour: 9))
        XCTAssertEqual(result[1].start, makeDate(hour: 11))
        XCTAssertEqual(result[2].start, makeDate(hour: 14))
    }

    // MARK: - Compute Free Intervals Tests

    func testComputeFreeIntervals_noBusyBlocks() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let result = await viewModel.computeFreeIntervals(busy: [], dayRange: dayRange)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 0))
        XCTAssertEqual(result[0].end, makeDate(hour: 24))
    }

    func testComputeFreeIntervals_singleBusyBlock() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let busy = [makeBlock(startHour: 10, endHour: 11)]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        XCTAssertEqual(result.count, 2)
        // Morning gap: 0:00 - 10:00
        XCTAssertEqual(result[0].start, makeDate(hour: 0))
        XCTAssertEqual(result[0].end, makeDate(hour: 10))
        // Afternoon gap: 11:00 - 24:00
        XCTAssertEqual(result[1].start, makeDate(hour: 11))
        XCTAssertEqual(result[1].end, makeDate(hour: 24))
    }

    func testComputeFreeIntervals_multipleBusyBlocks() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let busy = [
            makeBlock(startHour: 9, endHour: 10),
            makeBlock(startHour: 14, endHour: 16)
        ]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        XCTAssertEqual(result.count, 3)
        // 0:00 - 9:00
        XCTAssertEqual(result[0].start, makeDate(hour: 0))
        XCTAssertEqual(result[0].end, makeDate(hour: 9))
        // 10:00 - 14:00
        XCTAssertEqual(result[1].start, makeDate(hour: 10))
        XCTAssertEqual(result[1].end, makeDate(hour: 14))
        // 16:00 - 24:00
        XCTAssertEqual(result[2].start, makeDate(hour: 16))
        XCTAssertEqual(result[2].end, makeDate(hour: 24))
    }

    func testComputeFreeIntervals_filtersShortGaps() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 8, endHour: 18)
        // Create a very short gap (3 minutes) between events
        let busy = [
            makeBlock(startHour: 10, endHour: 11),
            makeBlock(startHour: 11, startMinute: 3, endHour: 12, endMinute: 0)
        ]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        // The 3-minute gap should be filtered out (< 5 minutes threshold)
        // Should have: 8:00-10:00 and 12:00-18:00
        XCTAssertEqual(result.count, 2)
    }

    func testComputeFreeIntervals_busyAtStartOfDay() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let busy = [makeBlock(startHour: 0, endHour: 8)]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 8))
        XCTAssertEqual(result[0].end, makeDate(hour: 24))
    }

    func testComputeFreeIntervals_busyAtEndOfDay() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let busy = [makeBlock(startHour: 20, endHour: 24)]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].start, makeDate(hour: 0))
        XCTAssertEqual(result[0].end, makeDate(hour: 20))
    }

    func testComputeFreeIntervals_entireDayBusy() async {
        let viewModel = await BetweenViewModel()
        let dayRange = makeBlock(startHour: 0, endHour: 24)
        let busy = [makeBlock(startHour: 0, endHour: 24)]
        let result = await viewModel.computeFreeIntervals(busy: busy, dayRange: dayRange)

        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - TimeBlock Tests

final class TimeBlockTests: XCTestCase {

    func testDuration() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        let block = TimeBlock(start: start, end: end)

        XCTAssertEqual(block.duration, 3600)
        XCTAssertEqual(block.durationMinutes, 60)
    }

    func testEquality() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(3600)

        let block1 = TimeBlock(start: date1, end: date2)
        let block2 = TimeBlock(start: date1, end: date2)

        XCTAssertEqual(block1, block2)
    }
}
