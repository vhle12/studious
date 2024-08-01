import SwiftUI
import UserNotifications

struct TimerView: View {
    @State private var timeRemaining: TimeInterval = 0
    @State private var initialTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning: Bool = false
    @State private var isEditing: Bool = false
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading)
                .padding(.top, 10)
                .padding(.horizontal, -35)
                
                Spacer()
            }
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                Circle()
                    .trim(from: 0, to: initialTime > 0 ? CGFloat(timeRemaining / initialTime) : 0)
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear)

                if isEditing {
                    VStack {
                        HStack(spacing: 5) { // Reduced spacing for compactness
                            StepperView(value: $hours, range: 0...23, label: "hr")
                            Text(":")
                                .font(.title2)
                                .fontWeight(.bold)
                            StepperView(value: $minutes, range: 0...59, label: "min")
                            Text(":")
                                .font(.title2)
                                .fontWeight(.bold)
                            StepperView(value: $seconds, range: 0...59, label: "sec")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        Button(action: {
                            updateTimer()
                        }) {
                            Text("Set Timer")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onAppear {
                        let components = formattedTime().split(separator: ":").map { String($0) }
                        hours = Int(components[0]) ?? 0
                        minutes = Int(components[1]) ?? 0
                        seconds = Int(components[2]) ?? 0
                    }
                } else {
                    Text(formattedTime())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .onTapGesture {
                            isEditing = true
                            stopTimer()
                        }
                }
            }
            .frame(maxWidth: 300, maxHeight: 300)
            .padding(.top, 60)
            
            HStack {
                Button {
                    if !isEditing {
                        isRunning.toggle()
                        if isRunning {
                            startTimer()
                        } else {
                            stopTimer()
                        }
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 50, height: 50)
                        .font(.largeTitle)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 50, height: 50)
                        .font(.largeTitle)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 30)
        .onAppear {
            requestNotificationPermissions()
        }
    }
    
    
    private func formattedTime() -> String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                sendNotification()
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = 0
        initialTime = 0
    }

    private func updateTimer() {
        timeRemaining = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
        initialTime = timeRemaining
        isEditing = false
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time's Up!"
        content.body = "The timer has finished."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
}
    

struct StepperView: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var label: String

    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                if value < range.upperBound {
                    value += 1
                }
            }) {
                Image(systemName: "chevron.up")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(PlainButtonStyle())

            Text("\(value)")
                .font(.title2)
                .frame(width: 40)

            Button(action: {
                if value > range.lowerBound {
                    value -= 1
                }
            }) {
                Image(systemName: "chevron.down")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(5)
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
