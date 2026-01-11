import EventKit
import Foundation

/// Handles calendar authorization state and requests
@MainActor
final class CalendarAuthorizationService: ObservableObject {

    enum AuthorizationState: Equatable {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    @Published private(set) var authorizationState: AuthorizationState = .notDetermined

    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        updateAuthorizationState()
    }

    /// Updates the current authorization state from the system
    func updateAuthorizationState() {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorizationState = mapStatus(status)
    }

    /// Requests calendar access from the user
    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationState = granted ? .authorized : .denied
        } catch {
            authorizationState = .denied
        }
    }

    private func mapStatus(_ status: EKAuthorizationStatus) -> AuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .fullAccess, .writeOnly:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}
