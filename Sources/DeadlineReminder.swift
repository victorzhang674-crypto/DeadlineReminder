import SwiftUI
import AppKit

let singaporeTimeZone = TimeZone(identifier: "Asia/Singapore")!
let singaporeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.timeZone = singaporeTimeZone
    return formatter
}()
var singaporeCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = singaporeTimeZone
    return calendar
}

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var deadline: Date
    var details: String? = nil
    var completed = false
}

final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()
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
            reminders = saved.map { item in
                var migrated = item
                if item.details == nil {
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: item.deadline)
                    migrated.deadline = singaporeCalendar.date(from: components) ?? item.deadline
                    migrated.details = ""
                }
                return migrated
            }
            if let data = try? JSONEncoder().encode(reminders) {
                UserDefaults.standard.set(data, forKey: "reminders")
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject private var store = ReminderStore.shared
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
            Editor(reminder: nil) { name, date, details in
                store.reminders.append(Reminder(name: name, deadline: date, details: details))
            }
        }
        .sheet(item: $editing) { reminder in
            Editor(reminder: reminder) { name, date, details in
                if let index = store.reminders.firstIndex(where: { $0.id == reminder.id }) {
                    store.reminders[index].name = name
                    store.reminders[index].deadline = date
                    store.reminders[index].details = details
                }
            }
        }
    }

    @ViewBuilder private func row(_ reminder: Reminder, now: Date) -> some View {
        let days = singaporeCalendar.dateComponents([.day], from: singaporeCalendar.startOfDay(for: now), to: singaporeCalendar.startOfDay(for: reminder.deadline)).day ?? 0
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
                if let details = reminder.details, !details.isEmpty {
                    Text(details).font(.subheadline).foregroundStyle(.secondary)
                }
                Text("Deadline: \(singaporeDateFormatter.string(from: reminder.deadline)) · Singapore time")
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
    let onSave: (String, Date, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var deadline: Date
    @State private var details: String
    @FocusState private var focused: Bool

    init(reminder: Reminder?, onSave: @escaping (String, Date, String) -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        _name = State(initialValue: reminder?.name ?? "")
        _deadline = State(initialValue: reminder?.deadline ?? Date())
        _details = State(initialValue: reminder?.details ?? "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(reminder == nil ? "Add a task" : "Edit task").font(.title2.bold())
            TextField("Task name", text: $name).textFieldStyle(.roundedBorder).focused($focused)
            TextField("Short description (optional)", text: $details).textFieldStyle(.roundedBorder)
            DatePicker("Deadline (Singapore time)", selection: $deadline, displayedComponents: .date)
                .environment(\.timeZone, singaporeTimeZone)
                .environment(\.calendar, singaporeCalendar)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), deadline, details.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }.keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(24).frame(width: 400).onAppear { focused = true }
    }
}

struct DesktopWidget: View {
    @ObservedObject var store: ReminderStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let upcoming = store.reminders.filter { !$0.completed }.sorted { $0.deadline < $1.deadline }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Deadlines", systemImage: "calendar.badge.clock").font(.headline)
                    Spacer()
                    Button("Open") {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.windows.first { !($0 is NSPanel) && $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
                    }.buttonStyle(.plain).font(.caption.bold())
                }
                Text("SINGAPORE TIME").font(.caption2.bold()).foregroundStyle(.secondary)
                if upcoming.isEmpty {
                    Spacer()
                    Text("No upcoming tasks").foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ForEach(Array(upcoming.prefix(4))) { reminder in
                        let days = singaporeCalendar.dateComponents([.day], from: singaporeCalendar.startOfDay(for: context.date), to: singaporeCalendar.startOfDay(for: reminder.deadline)).day ?? 0
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.name).font(.subheadline.bold()).lineLimit(1)
                                Text(singaporeDateFormatter.string(from: reminder.deadline)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 4)
                            Text(days < 0 ? "\(-days)d overdue" : days == 0 ? "Today" : "\(days)d left")
                                .font(.caption.bold()).foregroundStyle(days <= 0 ? Color.red : days <= 3 ? Color.orange : Color.blue)
                        }
                    }
                    Spacer(minLength: 0)
                    if upcoming.count > 4 { Text("+\(upcoming.count - 4) more in the app").font(.caption).foregroundStyle(.secondary) }
                }
            }.padding(16).frame(width: 300, height: 250, alignment: .topLeading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var widget: NSPanel?
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }
        let panel = NSPanel(contentRect: NSRect(x: screen.visibleFrame.maxX - 320, y: screen.visibleFrame.maxY - 270, width: 300, height: 250),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = NSHostingView(rootView: DesktopWidget(store: .shared))
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.orderFrontRegardless()
        widget = panel
    }
}

@main struct DeadlineReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup { ContentView() }.defaultSize(width: 680, height: 500)
    }
}
