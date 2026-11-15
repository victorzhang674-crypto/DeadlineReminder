import SwiftUI

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var deadline: Date
    var completed = false
}

final class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(reminders) {
                UserDefaults.standard.set(data, forKey: "reminders")
            }
        }
    }
    init() {
        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let saved = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = saved
        }
    }
}

struct ContentView: View {
    @StateObject private var store = ReminderStore()
    @State private var adding = false
    @State private var editing: Reminder?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deadline Reminder").font(.largeTitle.bold())
                    Text("Keep your important dates in sight.").foregroundStyle(.secondary)
                }
                Spacer()
                Button { adding = true } label: { Label("Add task", systemImage: "plus") }
                    .controlSize(.large).keyboardShortcut("n", modifiers: .command)
            }.padding(24)
            Divider()
            if store.reminders.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock").font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("No tasks yet").font(.title2.bold())
                    Text("Add a task and its deadline to get started.").foregroundStyle(.secondary)
                    Button("Add your first task") { adding = true }.padding(.top, 6)
                }.frame(maxWidth: .infinity)
                Spacer()
            } else {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    List {
                        ForEach(store.reminders.sorted {
                            if $0.completed != $1.completed { return !$0.completed }
                            return $0.deadline < $1.deadline
                        }) { reminder in
                            row(reminder, now: context.date)
                        }
                    }.listStyle(.inset).padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 580, minHeight: 400)
        .sheet(isPresented: $adding) {
            Editor(reminder: nil) { name, date in
                store.reminders.append(Reminder(name: name, deadline: date))
            }
        }
        .sheet(item: $editing) { reminder in
            Editor(reminder: reminder) { name, date in
                if let index = store.reminders.firstIndex(where: { $0.id == reminder.id }) {
                    store.reminders[index].name = name
                    store.reminders[index].deadline = date
                }
            }
        }
    }

    @ViewBuilder private func row(_ reminder: Reminder, now: Date) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: reminder.deadline)).day ?? 0
        HStack(spacing: 14) {
            Button {
                if let index = store.reminders.firstIndex(where: { $0.id == reminder.id }) {
                    store.reminders[index].completed.toggle()
                }
            } label: {
                Image(systemName: reminder.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(reminder.completed ? Color.green : Color.secondary)
            }.buttonStyle(.plain).help(reminder.completed ? "Mark incomplete" : "Mark complete")
            VStack(alignment: .leading, spacing: 5) {
                Text(reminder.name).font(.headline).strikethrough(reminder.completed)
                Text("Deadline: \(reminder.deadline.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(reminder.completed ? "Completed" : days < 0 ? "\(-days) \(days == -1 ? "day" : "days") overdue" : days == 0 ? "Due today" : "\(days) \(days == 1 ? "day" : "days") left")
                .font(.subheadline.bold())
                .foregroundStyle(reminder.completed ? Color.secondary : days <= 0 ? Color.red : days <= 3 ? Color.orange : Color.blue)
            Menu {
                Button("Edit") { editing = reminder }
                Button("Delete", role: .destructive) { store.reminders.removeAll { $0.id == reminder.id } }
            } label: { Image(systemName: "ellipsis.circle").font(.title3) }
                .menuStyle(.borderlessButton).fixedSize().help("Task options")
        }.padding(.vertical, 8)
    }
}

struct Editor: View {
    let reminder: Reminder?
    let onSave: (String, Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var deadline: Date
    @FocusState private var focused: Bool

    init(reminder: Reminder?, onSave: @escaping (String, Date) -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        _name = State(initialValue: reminder?.name ?? "")
        _deadline = State(initialValue: reminder?.deadline ?? Date())
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(reminder == nil ? "Add a task" : "Edit task").font(.title2.bold())
            TextField("Task name", text: $name).textFieldStyle(.roundedBorder).focused($focused)
            DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), deadline)
                    dismiss()
                }.keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(24).frame(width: 400).onAppear { focused = true }
    }
}

@main struct DeadlineReminderApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }.defaultSize(width: 680, height: 500)
    }
}
