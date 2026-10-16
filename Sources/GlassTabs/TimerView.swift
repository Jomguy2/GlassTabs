import SwiftUI
import Combine
import AudioToolbox
import UserNotifications

/// Countdown timer with presets, custom length, built-in sounds + vibration.
/// Keeps working in the background: the finish moment is an absolute `Date`
/// and a local notification fires even if iOS suspends the app.
struct TimerView: View {
    static let presets = [1, 5, 10, 15, 25]

    struct TimerSound: Identifiable, Hashable {
        let id: UInt32
        let name: String
    }

    static let sounds: [TimerSound] = [
        TimerSound(id: 1005, name: "Chime"),
        TimerSound(id: 1007, name: "Bell"),
        TimerSound(id: 1013, name: "Ping"),
        TimerSound(id: 1022, name: "Alert"),
        TimerSound(id: 1057, name: "Digital")
    ]

    @State private var totalSeconds: Int = 5 * 60
    @State private var customMinutes: Int = 5
    @State private var sound: TimerSound = sounds[0]
    @State private var vibrate = true
    @State private var endDate: Date?
    @State private var pausedRemaining: Int = 5 * 60
    @State private var isRunning = false
    @State private var now = Date()

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var remaining: Int {
        if let endDate {
            return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
        }
        return pausedRemaining
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(format(remaining))
                    .bigDigits(72)
                    .padding(.top, 24)

                // Preset chips
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(Self.presets, id: \.self) { minutes in
                        Button("\(minutes)") {
                            select(minutes * 60)
                        }
                        .presetChip(selected: totalSeconds == minutes * 60 && !isRunning)
                    }
                }
                .padding(.horizontal)

                // Custom length
                HStack {
                    Text("Custom")
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach(1...120, id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .onChange(of: customMinutes) { _, newValue in
                        select(newValue * 60)
                    }
                }
                .padding()
                .liquidGlassCard()
                .padding(.horizontal)

                // Sound + vibration
                VStack(spacing: 12) {
                    Picker("Sound", selection: $sound) {
                        ForEach(Self.sounds) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Vibrate on finish", isOn: $vibrate)
                        .foregroundStyle(.white)
                        .tint(.green)
                    Button("Preview sound") { playFinishFeedback() }
                        .font(.headline)
                        .foregroundStyle(Color.glassGreen)
                }
                .padding()
                .liquidGlassCard()
                .padding(.horizontal)

                // Controls
                HStack(spacing: 16) {
                    if isRunning {
                        Button("Pause", action: pause)
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Reset", action: reset)
                            .buttonStyle(SecondaryButtonStyle())
                    } else {
                        Button(remaining < totalSeconds && remaining > 0 ? "Resume" : "Start", action: start)
                            .buttonStyle(PrimaryButtonStyle())
                        if remaining != totalSeconds {
                            Button("Reset", action: reset)
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .glassBackdrop()
        .onReceive(ticker) { value in
            now = value
            if isRunning, endDate != nil, remaining <= 0 {
                finish()
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    private func select(_ seconds: Int) {
        guard !isRunning else { return }
        totalSeconds = seconds
        pausedRemaining = seconds
        customMinutes = max(1, seconds / 60)
    }

    private func start() {
        let seconds = remaining > 0 ? remaining : totalSeconds
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        pausedRemaining = seconds
        isRunning = true
        scheduleNotification(in: seconds)
    }

    private func pause() {
        pausedRemaining = remaining
        endDate = nil
        isRunning = false
        cancelNotification()
    }

    private func reset() {
        endDate = nil
        pausedRemaining = totalSeconds
        isRunning = false
        cancelNotification()
    }

    private func finish() {
        endDate = nil
        pausedRemaining = totalSeconds
        isRunning = false
        cancelNotification()
        playFinishFeedback()
    }

    private func playFinishFeedback() {
        AudioServicesPlaySystemSound(sound.id)
        if vibrate {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func scheduleNotification(in seconds: Int) {
        cancelNotification()
        let content = UNMutableNotificationContent()
        content.title = "GlassTabs Timer"
        content.body = "Time is up."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: "glasstabs-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["glasstabs-timer"])
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
