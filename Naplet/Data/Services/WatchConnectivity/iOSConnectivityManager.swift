import Foundation
import WatchConnectivity

// MARK: - Notification Names for Watch
extension Notification.Name {
    static let watchRequestedStartSleep = Notification.Name("watchRequestedStartSleep")
    static let watchRequestedStopSleep = Notification.Name("watchRequestedStopSleep")
    static let watchRequestedSync = Notification.Name("watchRequestedSync")
    static let watchBecameReachable = Notification.Name("watchBecameReachable")
}

// MARK: - iOS Connectivity Manager
class iOSConnectivityManager: NSObject, ObservableObject {
    static let shared = iOSConnectivityManager()

    // MARK: - Published Properties
    @Published var isWatchPaired = false
    @Published var isWatchReachable = false
    @Published var isWatchAppInstalled = false

    // MARK: - Private Properties
    private var session: WCSession?

    // MARK: - Init
    override init() {
        super.init()

        #if DEBUG
        print("[iOS] iOSConnectivityManager INIT - WCSession.isSupported: \(WCSession.isSupported())")
        #endif

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            #if DEBUG
            print("[iOS] WCSession.activate() called")
            #endif
        } else {
            #if DEBUG
            print("[iOS] WCSession NOT supported on this device")
            #endif
        }
    }

    // MARK: - Send Data to Watch

    func sendSleepUpdate(
        baby: Baby,
        isSleeping: Bool,
        sleepType: SleepRecord.SleepType?,
        sleepStartTime: Date?,
        todayTotalSleep: Int,
        todayNaps: Int
    ) {
        guard let session = session else {
            Logger.info("📱 WCSession not available")
            return
        }

        // Check if Watch is available (isPaired for device, activationState for simulator)
        guard session.activationState == .activated else {
            Logger.info("📱 WCSession not activated yet")
            return
        }

        var context: [String: Any] = [
            "baby": [
                "id": baby.id.uuidString,
                "name": baby.name,
                "ageDescription": baby.ageDescription,
                "recommendedWakeWindow": Int(baby.recommendedWakeWindow / 60)
            ],
            "isSleeping": isSleeping,
            "todayTotalSleep": todayTotalSleep,
            "todayNaps": todayNaps
        ]

        if let type = sleepType {
            context["sleepType"] = type.rawValue
        }

        if let startTime = sleepStartTime {
            context["sleepStartTime"] = startTime.timeIntervalSince1970
        }

        // Try to send as message first (faster), fallback to context
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { error in
                Logger.error("Error sending message to watch: \(error)")
                // Fallback to application context
                try? session.updateApplicationContext(context)
            }
        } else {
            try? session.updateApplicationContext(context)
        }

        Logger.info("📤 Sent update to watch: isSleeping=\(isSleeping)")
    }

    func syncWithWatch(
        baby: Baby,
        isSleeping: Bool,
        sleepType: SleepRecord.SleepType?,
        sleepStartTime: Date?,
        todayTotalSleep: Int,
        todayNaps: Int
    ) {
        sendSleepUpdate(
            baby: baby,
            isSleeping: isSleeping,
            sleepType: sleepType,
            sleepStartTime: sleepStartTime,
            todayTotalSleep: todayTotalSleep,
            todayNaps: todayNaps
        )
    }

    // MARK: - Check Watch Status

    func checkWatchStatus() -> (isPaired: Bool, isReachable: Bool) {
        guard let session = session else {
            return (false, false)
        }
        return (session.isPaired, session.isReachable)
    }
}

// MARK: - WCSessionDelegate

extension iOSConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        print("[iOS] activationDidComplete - state: \(activationState.rawValue)")
        print("[iOS] isPaired: \(session.isPaired)")
        print("[iOS] isReachable: \(session.isReachable)")
        print("[iOS] isWatchAppInstalled: \(session.isWatchAppInstalled)")
        if let error = error {
            print("[iOS] WCSession activation error: \(error)")
        }
        #endif

        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.info("🔗 iOS session inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.info("🔗 iOS session deactivated")
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        #if DEBUG
        print("[iOS] reachabilityDidChange - isReachable: \(session.isReachable)")
        #endif

        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }

        // When Watch becomes reachable, trigger a sync
        if session.isReachable {
            #if DEBUG
            print("[iOS] Watch is reachable! Posting notification...")
            #endif
            NotificationCenter.default.post(name: .watchBecameReachable, object: nil)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Logger.info("📨 iOS received message from watch: \(message)")

        guard let action = message["action"] as? String else {
            replyHandler(["error": "No action specified"])
            return
        }

        DispatchQueue.main.async {
            switch action {
            case "startSleep":
                let typeString = message["type"] as? String ?? "nap"
                let type: SleepRecord.SleepType = typeString == "night" ? .night : .nap

                // Post notification for DashboardViewModel to handle
                NotificationCenter.default.post(
                    name: .watchRequestedStartSleep,
                    object: nil,
                    userInfo: ["type": type, "replyHandler": replyHandler]
                )

            case "stopSleep":
                // Post notification for DashboardViewModel to handle
                NotificationCenter.default.post(
                    name: .watchRequestedStopSleep,
                    object: nil,
                    userInfo: ["replyHandler": replyHandler]
                )

            case "sync":
                // Post notification to trigger sync
                NotificationCenter.default.post(
                    name: .watchRequestedSync,
                    object: nil,
                    userInfo: ["replyHandler": replyHandler]
                )

            default:
                replyHandler(["error": "Unknown action"])
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Logger.info("📨 iOS received message (no reply): \(message)")
    }
}
