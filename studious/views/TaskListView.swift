import SwiftUI

struct TaskListView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle: String = ""

    var body: some View {
        VStack {
            Text("TASKS")
                .font(.system(size: 30))
                .bold()
                .padding(.top, 30)
            
            HStack {
                TextField("New Task", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onSubmit {
                        addTask()
                    }
                
                Button(action: {
                    addTask()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing)
            }
            
            List {
                ForEach(tasks, id: \.id) { task in
                    HStack {
                        Text(task.title)
                            .font(.headline)
                        Spacer()
                        if let start_time = task.start_time, let end_time = task.end_time {
                            Text(formatTime(start_time))
                                .font(.subheadline)
                            Text("-")
                            Text(formatTime(end_time))
                                .font(.subheadline)
                        }
                        Button(action: {
                            deleteTaskFromServer(taskId: task.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .cornerRadius(10)
                    .shadow(radius: 1)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        deleteTaskFromServer(taskId: tasks[index].id)
                    }
                    tasks.remove(atOffsets: indexSet)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
            .padding(.leading, -20)
            
            Spacer()
            
            NavigationLink(destination: CalendarView()) {
                Text("View Calendar")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom)
        }
        .padding(.horizontal, 15)
        .onAppear(perform: fetchTasks)
    }
    
    private func addTask() {
        if !newTaskTitle.isEmpty {
            let newTask = Task(id: 0, title: newTaskTitle, start_time: nil, end_time: nil, completed: false)
            tasks.append(newTask)
            newTaskTitle = ""
            addTaskToServer(task: newTask)
        }
    }

    private func deleteTaskFromServer(taskId: Int) {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks/\(taskId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                    self.tasks.remove(at: index)
                }
                print("Task deleted successfully.")
            }
        }.resume()
    }
    
    private func fetchTasks() {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let fetchedTasks = try decoder.decode([Task].self, from: data)
                DispatchQueue.main.async {
                    self.tasks = fetchedTasks
                }
            } catch {
                print("Error decoding tasks: \(error)")
            }
        }.resume()
    }
    
    private func addTaskToServer(task: Task) {
        guard let url = URL(string: "http://127.0.0.1:5000/tasks") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let taskData = try JSONEncoder().encode(task)
            request.httpBody = taskData
        } catch {
            print("Error encoding task: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let returnedTask = try JSONDecoder().decode(Task.self, from: data)
                DispatchQueue.main.async {
                    if let index = self.tasks.firstIndex(where: { $0.title == task.title }) {
                        self.tasks[index].id = returnedTask.id
                    }
                }
            } catch {
                print("Error decoding returned task: \(error)")
            }
        }.resume()
    }

    private func formatTime(_ dateString: String) -> String {
        // Extract the hour and minute components from the date string
        let timeComponents = dateString.split(separator: "T")[1].prefix(5) // Gets the "HH:MM" part of the string
        
        // Convert to 12-hour format with AM/PM
        let components = timeComponents.split(separator: ":")
        guard components.count == 2, let hour = Int(components[0]), let minute = Int(components[1]) else {
            return String(timeComponents)
        }
        
        let isPM = hour >= 12
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let period = isPM ? "PM" : "AM"
        
        return String(format: "%d:%02d %@", hour12, minute, period)
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}
