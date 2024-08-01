import SwiftUI
import UniformTypeIdentifiers

struct CalendarView: View {
    @State private var tasks: [Task] = []
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var draggedTask: Task?
    @State private var isDragging: Bool = false
    @State private var showTimerView: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: TaskListView()) {
                    Image(systemName: "arrow.left")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading)
                .padding(.top, 4)
                .padding(.horizontal, -5)
                
                Spacer()
                
                NavigationLink(destination: TimerView()) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 30))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 10)
                .padding(.leading, 275)
                
                Spacer()
            }
            
            ZStack {
                VStack(alignment: .leading) {
                    // Date headline
                    HStack {
                        Text(Date().formatted(.dateTime.day().month().year()))
                            .bold()
                    }
                    .font(.title)
                    .padding(.leading, 115)
                    Spacer()
                    
                    
                    // Scrollable HStack for tasks
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tasks.filter { $0.start_time == nil && $0.end_time == nil }) { task in
                                Text(task.title)
                                    .padding()
                                    .background(Color.blue.opacity(0.3))
                                    .cornerRadius(10)
                                    .onDrag {
                                        self.draggedTask = task
                                        self.isDragging = true
                                        return NSItemProvider(object: task.title as NSString)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.leading)
                    
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            ZStack(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(0..<24) { index in
                                        let hour = index % 12 == 0 ? 12 : index % 12
                                        let period = index < 12 ? "AM" : "PM"
                                        HStack {
                                            Text("\(hour) \(period)")
                                                .font(.caption)
                                                .frame(width: 60, alignment: .trailing)
                                            Color.gray
                                                .frame(height: 1)
                                        }
                                        .frame(height: 50)
                                        .id(index)
                                    }
                                }
                                
                                ForEach(tasks.filter { $0.start_time != nil && $0.end_time != nil }) { task in
                                    eventCell(task)
                                        .onAppear {
                                            print("Task \(task.title) appears with start_time: \(task.start_time ?? "nil") and end_time: \(task.end_time ?? "nil")")
                                        }
                                }
                            }
                            .padding(.trailing, 50)
                            .padding(.leading, -20)
                            .onDrop(of: [UTType.text], isTargeted: nil) { providers, location in
                                if let draggedTask = self.draggedTask {
                                    self.handleDrop(providers: providers, at: location, for: draggedTask)
                                    self.isDragging = false
                                    self.draggedTask = nil
                                }
                                return true
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(7, anchor: .top)
                            self.scrollViewProxy = proxy
                            print("Fetching tasks on appear")
                            fetchTasks()
                        }
                    }
                    .padding([.leading, .trailing])
                }
                .padding(.top, -10)
                .padding(.leading, -15)
                .padding()
                
                if isDragging {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                        }
                    }
                }
            }
            
            // Button to auto-generate tasks
            Button(action: autoGenerateSchedule) {
                Text("Auto Generate Schedule")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func eventCell(_ task: Task) -> some View {
        guard let start_time = ISO8601DateFormatter().date(from: task.start_time ?? ""),
              let end_time = ISO8601DateFormatter().date(from: task.end_time ?? "") else {
            return AnyView(EmptyView())
        }
        
        let duration = end_time.timeIntervalSince(start_time)
        let height = duration / 60 / 60 * 50

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: start_time)
        let minute = calendar.component(.minute, from: start_time)
        let offset = Double(hour) * 50 + Double(minute) / 60 * 50

        return AnyView(
            VStack(alignment: .leading) {
                HStack {
                    Text(task.title).bold()
                    Spacer()
                    NavigationLink(destination: TimerView()) {
                        Text("Start Task")
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(alignment: .trailing)
            }
            .font(.caption)
            .frame(maxWidth: 250, alignment: .leading)
            .padding(4)
            .frame(height: height, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 8).fill(task.completed ? Color.orange.opacity(0.5) : Color.teal.opacity(0.5)))
            .offset(x: 60, y: offset + 25)
            .onDrag {
                self.draggedTask = task
                self.isDragging = true
                return NSItemProvider(object: task.title as NSString)
            }
            .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                self.isDragging = false
                return true
            }
            .contextMenu {
                Button(action: {
                    if tasks.contains(where: { $0.id == task.id }) {
                        self.deleteTaskOnServer(taskId: task.id)
                    }
                }) {
                    Image(systemName: "trash")
                }
            }
            .onTapGesture(count: 2) {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].completed.toggle()
                    updateTaskOnServer(task: tasks[index])
                }
            }
        )
    }

    private func handleDrop(providers: [NSItemProvider], at location: CGPoint, for task: Task) {
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        let hour = Int(location.y / 50)
        components.hour = hour
        components.minute = 0
        components.second = 0
        components.timeZone = timeZone

        if let start_time = calendar.date(from: components) {
            let end_time = calendar.date(byAdding: .hour, value: 1, to: start_time)!
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.timeZone = timeZone
            
            print("Dropped task at hour: \(hour)")
            print("New start_time: \(start_time)")
            print("New end_time: \(end_time)")
            
            // Update the state immediately
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].start_time = isoFormatter.string(from: start_time)
                tasks[index].end_time = isoFormatter.string(from: end_time)
                
                print("Updated task in Swift state: \(tasks[index])")
                
                // Update the backend
                DispatchQueue.main.async {
                    self.updateTaskOnServer(task: self.tasks[index])
                }
            }
        } else {
            print("Error: Unable to create date from components")
        }
    }

    private func updateTaskOnServer(task: Task) {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks/\(task.id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let body = try? encoder.encode(task) {
            request.httpBody = body

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error updating task on server: \(error)")
                    return
                }
                guard let data = data else { return }
                do {
                    let updatedTask = try JSONDecoder().decode(Task.self, from: data)
                    DispatchQueue.main.async {
                        if let index = self.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                            self.tasks[index] = updatedTask
                            print("Task updated on server and state updated: \(self.tasks[index])")
                        }
                    }
                } catch {
                    print("Error decoding updated task: \(error)")
                }
            }.resume()
        }
    }

    func createTaskOnServer(task: Task) {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let body = try? encoder.encode(task) {
            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error creating task on server: \(error)")
                    return
                }
                guard let data = data else { return }
                do {
                    let createdTask = try JSONDecoder().decode(Task.self, from: data)
                    DispatchQueue.main.async {
                        self.tasks.append(createdTask)
                        print("Task created on server and state updated.")
                    }
                } catch {
                    print("Error decoding created task: \(error)")
                }
            }.resume()
        }
    }

    func deleteTaskOnServer(taskId: Int) {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks/\(taskId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting task on server: \(error)")
                return
            }
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                    self.tasks.remove(at: index)
                    print("Task deleted on server and state updated.")
                }
            }
        }.resume()
    }

    func autoGenerateSchedule() {
        guard let url = URL(string: "http://127.0.0.1:5000/generate_schedule") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let taskTitles = tasks.map { ["title": $0.title] }
        let body = try? JSONSerialization.data(withJSONObject: taskTitles)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let schedule = try JSONDecoder().decode([Task].self, from: data)
                DispatchQueue.main.async {
                    self.tasks = schedule
                    print("Schedule auto-generated and state updated.")
                    self.fetchTasks()
                }
            } catch {
                print("Error decoding schedule: \(error)")
            }
        }.resume()
    }

    func fetchTasks() {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let fetchedTasks = try decoder.decode([Task].self, from: data)
                DispatchQueue.main.async {
                    self.tasks = fetchedTasks
                    print("Fetched tasks: \(fetchedTasks)")
                }
            } catch {
                print("Error decoding tasks: \(error)")
            }
        }.resume()
    }

    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ha"
        return dateFormatter.string(from: date)
    }
    
    struct CalendarView_Previews: PreviewProvider {
        static var previews: some View {
            CalendarView()
        }
    }
}
    
extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}
