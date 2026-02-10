import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Connectivity Manager
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties
    @Published var currentBaby: WatchBaby?
    @Published var isSleeping = false
    @Published var sleepType: WatchSleepType?
    @Published var sleepStartTime: Date?
    @Published var todayTotalSleep: Int = 0
    @Published var todayNaps: Int = 0
    @Published var isReachable = false

    // MARK: - Private Properties
    private var session: WCSession?
    private var timer: Timer?

    // MARK: - Computed Properties
    var currentSleepDuration: TimeInterval? {
        guard isSleeping, let startTime = sleepStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Init
    override init() {
        super.init()

        print("⌚ [Watch] WatchConnectivityManager INIT - WCSession.isSupported: \(WCSession.isSupported())")

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("⌚ [Watch] WCSession.activate() called")
        } else {
            print("❌ [Watch] WCSession NOT supported")
        }

        // Timer to update sleep duration display
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if self?.isSleeping == true {
                self?.objectWillChange.send()
            }
        }
    }

    // MARK: - Actions

    func startSleep(type: WatchSleepType) {
        guard let session = session, session.isReachable else {
            print("❌ iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "action": "startSleep",
            "type": type.rawValue
        ]

        session.sendMessage(message, replyHandler: { [weak self] response in
            print("✅ Start sleep response: \(response)")
            DispatchQueue.main.async {
                self?.isSleeping = true
                self?.sleepType = type
                self?.sleepStartTime = Date()
            }
        }, errorHandler: { error in
            print("❌ Error starting sleep: \(error)")
        })
    }

    func stopSleep() {
        guard let session = session, session.isReachable else {
            print("❌ iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "action": "stopSleep"
        ]

        session.sendMessage(message, replyHandler: { [weak self] response in
            print("✅ Stop sleep response: \(response)")
            DispatchQueue.main.async {
                self?.isSleeping = false
                self?.sleepType = nil
                self?.sleepStartTime = nil

                // Update stats from response
                if let totalSleep = response["todayTotalSleep"] as? Int {
                    self?.todayTotalSleep = totalSleep
                }
                if let naps = response["todayNaps"] as? Int {
                    self?.todayNaps = naps
                }
            }
        }, errorHandler: { error in
            print("❌ Error stopping sleep: \(error)")
        })
    }

    func requestSync() {
        print("⌚ [Watch] requestSync() called")

        guard let session = session else {
            print("❌ [Watch] requestSync - session is nil")
            return
        }

        guard session.isReachable else {
            print("❌ [Watch] requestSync - iPhone not reachable")
            return
        }

        print("⌚ [Watch] Sending sync message to iPhone...")
        session.sendMessage(["action": "sync"], replyHandler: { [weak self] response in
            print("✅ [Watch] Sync response received: \(response)")
            self?.handleSyncResponse(response)
        }, errorHandler: { error in
            print("❌ [Watch] Sync error: \(error)")
        })
    }

    // MARK: - Handle Sync Response

    private func handleSyncResponse(_ response: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            // Baby data
            if let babyData = response["baby"] as? [String: Any] {
                self?.currentBaby = WatchBaby(
                    id: UUID(uuidString: babyData["id"] as? String ?? "") ?? UUID(),
                    name: babyData["name"] as? String ?? "",
                    ageDescription: babyData["ageDescription"] as? String ?? "",
                    recommendedWakeWindow: babyData["recommendedWakeWindow"] as? Int ?? 120
                )
            }

            // Sleep state
            self?.isSleeping = response["isSleeping"] as? Bool ?? false

            if let typeString = response["sleepType"] as? String, !typeString.isEmpty {
                self?.sleepType = WatchSleepType(rawValue: typeString)
            } else {
                self?.sleepType = nil
            }

            if let startTimeInterval = response["sleepStartTime"] as? TimeInterval, startTimeInterval > 0 {
                self?.sleepStartTime = Date(timeIntervalSince1970: startTimeInterval)
            } else {
                self?.sleepStartTime = nil
            }

            self?.todayTotalSleep = response["todayTotalSleep"] as? Int ?? 0
            self?.todayNaps = response["todayNaps"] as? Int ?? 0
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("⌚ [Watch] activationDidComplete - state: \(activationState.rawValue)")
        print("⌚ [Watch] isReachable: \(session.isReachable)")

        if let error = error {
            print("❌ [Watch] activation error: \(error)")
        }

        if activationState == .activated {
            DispatchQueue.main.async {
                self.isReachable = session.isReachable
            }
            print("⌚ [Watch] Calling requestSync()...")
            requestSync()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("⌚ [Watch] reachabilityDidChange - isReachable: \(session.isReachable)")

        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if session.isReachable {
            print("⌚ [Watch] iPhone reachable! Calling requestSync()...")
            requestSync()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📨 Watch received message: \(message)")
        handleSyncResponse(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("📦 Watch received context: \(applicationContext)")
        handleSyncResponse(applicationContext)
    }
}
