import SwiftUI
import Combine

/// Stopwatch with start/stop/reset and a lap list showing lap + split times.
/// Elapsed time derives from absolute `Date`s, so it stays correct even if
/// the app is backgrounded mid-run.
struct StopwatchView: View {
    @State private var isRunning = false
    @State private var startDate: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var laps: [TimeInterval] = []
    @State private var now = Date()

    private let ticker = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    private var elapsed: TimeInterval {
        if isRunning, let startDate {
            return accumulated + now.timeIntervalSince(startDate)
        }
        return accumulated
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(format(elapsed))
                .bigDigits(56)
                .padding(.top, 32)

            HStack(spacing: 16) {
                if isRunning {
                    Button("Stop", action: stop)
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Lap", action: lap)
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(elapsed > 0 ? "Resume" : "Start", action: start)
                        .buttonStyle(PrimaryButtonStyle())
                    if elapsed > 0 || !laps.isEmpty {
                        Button("Reset", action: reset)
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }

            if laps.isEmpty {
                Text("No laps yet")
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
            } else {
                List {
                    ForEach(Array(laps.enumerated()), id: \.offset) { index, cumulative in
                        let previous = index == 0 ? 0 : laps[index - 1]
                        let split = cumulative - previous
                        HStack {
                            Text("Lap \(laps.count - index)")
                                .foregroundStyle(.white)
                                .bold()
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(format(cumulative))
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                                Text("+\(format(split))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .monospacedDigit()
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.12))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            Spacer()
        }
        .glassBackdrop()
        .onReceive(ticker) { now = $0 }
    }

    private func start() {
        startDate = Date()
        now = Date()
        isRunning = true
    }

    private func stop() {
        if let startDate {
            accumulated += Date().timeIntervalSince(startDate)
        }
        self.startDate = nil
        isRunning = false
    }

    private func lap() {
        laps.insert(elapsed, at: 0)
    }

    private func reset() {
        isRunning = false
        startDate = nil
        accumulated = 0
        laps = []
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = max(0, interval)
        let minutes = Int(total / 60)
        let seconds = Int(total.truncatingRemainder(dividingBy: 60))
        let hundredths = Int((total * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}
