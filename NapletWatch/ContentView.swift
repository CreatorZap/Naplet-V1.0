import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            if connectivity.currentBaby != nil {
                MainWatchView()
            } else {
                NoBabyView()
            }
        }
    }
}

// MARK: - No Baby View
struct NoBabyView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 40))
                .foregroundColor(.purple)

            Text("Abra o Naplet no iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("para sincronizar")
                .font(.caption)
                .foregroundColor(.secondary)

            if !connectivity.isReachable {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("iPhone desconectado")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
