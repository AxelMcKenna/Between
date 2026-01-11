import SwiftUI

/// Main timeline view showing the day's free and busy intervals
struct BetweenTimelineView: View {

    @ObservedObject var viewModel: BetweenViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showingAbout = false

    private let swipeThreshold: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Minimal date indicator
                    dateIndicator
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    // Timeline
                    timelineContent(height: geometry.size.height - 100)
                        .padding(.horizontal, 40)

                    Spacer(minLength: 16)
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        if value.translation.width < -swipeThreshold {
                            viewModel.goToNextDay()
                        } else if value.translation.width > swipeThreshold {
                            viewModel.goToPreviousDay()
                        }
                    }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day timeline")
        .onLongPressGesture(minimumDuration: 0.8) {
            showingAbout = true
        }
        .sheet(isPresented: $showingAbout) {
            AboutPrivacySheet()
                .presentationDetents([.medium])
        }
    }

    // MARK: - Components

    private var dateIndicator: some View {
        HStack {
            Spacer()

            if !viewModel.isToday {
                Button(action: { viewModel.goToToday() }) {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Return to today")
            }

            Spacer()
        }
        .frame(height: 20)
    }

    private func timelineContent(height: CGFloat) -> some View {
        let dayRange = viewModel.dayRange(for: viewModel.selectedDate)
        let totalDuration = dayRange.end.timeIntervalSince(dayRange.start)

        return ZStack(alignment: .top) {
            // Background track
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.03))
                .frame(width: 48, height: height)

            // Segments
            ForEach(viewModel.segments) { segment in
                segmentView(
                    segment: segment,
                    totalDuration: totalDuration,
                    dayStart: dayRange.start,
                    totalHeight: height
                )
            }

            // Subtle hour markers (no text)
            hourMarkers(totalHeight: height)
        }
        .frame(width: 48, height: height)
    }

    private func segmentView(
        segment: TimelineSegment,
        totalDuration: TimeInterval,
        dayStart: Date,
        totalHeight: CGFloat
    ) -> some View {
        let offset = segment.start.timeIntervalSince(dayStart)
        let duration = segment.duration

        let yOffset = (offset / totalDuration) * totalHeight
        let segmentHeight = max((duration / totalDuration) * totalHeight, 1)

        return Group {
            switch segment.type {
            case .free:
                FreeGapSegmentView(segment: segment)
                    .frame(width: 48, height: segmentHeight)
                    .offset(y: yOffset)

            case .busy:
                BusySegmentView()
                    .frame(width: 48, height: segmentHeight)
                    .offset(y: yOffset)
            }
        }
        .frame(width: 48, height: totalHeight, alignment: .top)
    }

    private func hourMarkers(totalHeight: CGFloat) -> some View {
        let hourHeight = totalHeight / 24

        return ZStack(alignment: .top) {
            ForEach(0..<24, id: \.self) { hour in
                Rectangle()
                    .fill(Color.primary.opacity(hour % 6 == 0 ? 0.08 : 0.03))
                    .frame(width: 48, height: 1)
                    .offset(y: CGFloat(hour) * hourHeight)
            }
        }
        .frame(width: 48, height: totalHeight, alignment: .top)
        .allowsHitTesting(false)
    }
}

/// View for free time gaps - visually prominent but quiet
struct FreeGapSegmentView: View {
    let segment: TimelineSegment

    @State private var isHighlighted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.primary.opacity(isHighlighted ? 0.15 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Gentle highlight micro-interaction
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHighlighted = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isHighlighted = false
                    }
                }
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let duration = segment.durationMinutes
        if duration >= 180 {
            return "Long gap"
        } else if duration >= 60 {
            return "Medium gap"
        } else {
            return "Short gap"
        }
    }
}

/// View for busy time - muted/minimal
struct BusySegmentView: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .overlay(
                // Faint linework to indicate occupied time
                VStack(spacing: 4) {
                    ForEach(0..<100, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.primary.opacity(0.04))
                            .frame(height: 1)
                    }
                }
                .clipped()
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    BetweenTimelineView(viewModel: BetweenViewModel())
}
