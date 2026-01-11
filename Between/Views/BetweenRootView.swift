import SwiftUI

/// Root view that handles authorization states and displays the timeline
struct BetweenRootView: View {

    @StateObject private var authService = CalendarAuthorizationService()
    @StateObject private var viewModel = BetweenViewModel()

    var body: some View {
        Group {
            switch authService.authorizationState {
            case .notDetermined:
                NotDeterminedView {
                    Task {
                        await authService.requestAccess()
                    }
                }

            case .authorized:
                BetweenTimelineView(viewModel: viewModel)
                    .onAppear {
                        viewModel.loadDay()
                    }

            case .denied, .restricted:
                AccessDeniedView()
            }
        }
        .onAppear {
            authService.updateAuthorizationState()
        }
    }
}

/// View shown when calendar access hasn't been requested yet
private struct NotDeterminedView: View {
    let onRequestAccess: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Between shows the spaces in your day.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRequestAccess) {
                Text("Allow Calendar Access")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// View shown when calendar access is denied
private struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Calendar access is off.")
                .font(.body)
                .foregroundStyle(.secondary)

            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) {
                    Text("Open Settings")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calendar access is off. Open Settings to enable.")
    }
}

#Preview {
    BetweenRootView()
}
