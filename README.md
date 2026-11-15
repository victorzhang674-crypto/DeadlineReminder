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

## Add the desktop widget

Open Deadline Reminder once after installing. Right-click an empty area of the desktop, choose **Edit Widgets**, search for **Deadline Reminder**, and click or drag the desired size onto the desktop. Choose **Done** to finish. macOS controls widget refresh timing; changes may take a little while to appear.

Use Command-N to add a task. The widget displays incomplete tasks and their deadlines, with day counts based on midnight in Singapore (Asia/Singapore), regardless of the Mac’s time zone. The app does not send notifications. Task data remains on the Mac. The widget reads a copy in its own local container; opening the app updates that copy.
