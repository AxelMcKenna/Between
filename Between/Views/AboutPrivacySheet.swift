import SwiftUI

/// Minimal privacy information sheet
struct AboutPrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Between reads your calendar only to compute free time. No event details are shown or stored.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AboutPrivacySheet()
}
