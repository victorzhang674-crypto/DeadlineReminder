import SwiftUI
import WidgetKit

private let singaporeZone = TimeZone(identifier: "Asia/Singapore")!
private var singaporeCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = singaporeZone
    return calendar
}
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeZone = singaporeZone
    return formatter
}()

struct Reminder: Identifiable, Codable {
    var id: UUID
    var name: String
    var deadline: Date
    var details: String?
    var completed: Bool
}

struct Entry: TimelineEntry {
    let date: Date
    let reminders: [Reminder]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, reminders: []) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(load()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = load()
        let midnight = singaporeCalendar.date(byAdding: .day, value: 1, to: singaporeCalendar.startOfDay(for: entry.date))!
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
    private func load() -> Entry {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("reminders.json")
        let data = try? Data(contentsOf: url)
        let reminders = data.flatMap { try? JSONDecoder().decode([Reminder].self, from: $0) } ?? []
        return Entry(date: .now, reminders: reminders.filter { !$0.completed }.sorted { $0.deadline < $1.deadline })
    }
}

struct DeadlineWidgetView: View {
    let entry: Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Deadlines", systemImage: "calendar.badge.clock").font(.headline)
            Text("SINGAPORE TIME").font(.caption2.bold()).foregroundStyle(.secondary)
            if entry.reminders.isEmpty {
                Spacer()
                Text("No upcoming tasks").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(Array(entry.reminders.prefix(family == .systemSmall ? 2 : 4))) { reminder in
                    let days = singaporeCalendar.dateComponents([.day], from: singaporeCalendar.startOfDay(for: entry.date), to: singaporeCalendar.startOfDay(for: reminder.deadline)).day ?? 0
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.name).font(.caption.bold()).lineLimit(1)
                            Text(dateFormatter.string(from: reminder.deadline)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 2)
                        Text(days < 0 ? "\(-days)d overdue" : days == 0 ? "Today" : "\(days)d left")
                            .font(.caption2.bold()).foregroundStyle(days <= 0 ? Color.red : days <= 3 ? Color.orange : Color.blue)
                    }
                }
                Spacer(minLength: 0)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main struct DeadlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DeadlineReminderWidget", provider: Provider()) { entry in
            DeadlineWidgetView(entry: entry)
        }
        .configurationDisplayName("Deadline Reminder")
        .description("See upcoming deadlines and days remaining in Singapore time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
