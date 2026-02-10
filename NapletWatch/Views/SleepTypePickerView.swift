import SwiftUI

// MARK: - Sleep Type Picker View
struct SleepTypePickerView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Nap option
            Button(action: {
                connectivity.startSleep(type: .nap)
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Soneca")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Sono durante o dia")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.purple.opacity(0.1))

            // Night sleep option
            Button(action: {
                connectivity.startSleep(type: .night)
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundColor(.indigo)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Noite")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Sono noturno")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.indigo.opacity(0.1))
        }
        .navigationTitle("Tipo de Sono")
    }
}

// MARK: - Preview
#Preview {
    SleepTypePickerView()
        .environmentObject(WatchConnectivityManager.shared)
}
