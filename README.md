# Deadline Reminder

A native macOS app for keeping task deadlines visible. Add, edit, complete, and delete tasks; the list shows each deadline, optional short description, and calendar days remaining, including overdue tasks. Tasks are saved locally on this Mac.

## Build and install

Requires macOS and the Swift compiler from Xcode or the Xcode Command Line Tools.

```sh
./build.sh
mkdir -p ~/Applications
ditto 'build/Deadline Reminder.app' "$HOME/Applications/Deadline Reminder.app"
open "$HOME/Applications/Deadline Reminder.app"
```

Use Command-N to add a task. The count changes at midnight Singapore time (Asia/Singapore), regardless of the Mac’s time zone. The app displays reminders while it is open; it does not send notifications. Task data is stored in macOS preferences under the app's bundle identifier, `local.deadline-reminder.app`.
