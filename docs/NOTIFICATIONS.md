# Notifications

```
features/notifications/
├── domain/notification_models.dart         PlannedNotification, NotificationProvider interface
├── application/notification_planner.dart   pure rules: what to schedule and when
├── application/notification_service.dart   debounced re-planning + scheduled history
├── data/local_notification_provider.dart   flutter_local_notifications adapter
├── templates/notification_templates.dart   user-facing copy
└── presentation/notification_settings_screen.dart
```

## Rules

Reminders are off until the user enables them and grants permission. Categories (each toggleable):
upcoming salary (N days before), payday, upcoming bonus, overdue payment, temporary job ending,
variable-income actual update (1st of next month), month-end review, backup reminder, daily/weekly
earnings summary, calendar "remind me" events.

- Planned for the next 45 days, at most 60 pending (iOS allows 64).
- Every event has a stable key (e.g. `pay:<source>:2024-10:due`) hashed to a stable platform id;
  re-planning replaces all pending notifications, so duplicates cannot accumulate.
- Reminder time and quiet hours are configurable; a time inside quiet hours moves to the end of
  quiet hours.
- Reminders are planned **per account**, from that account's own records, reminder settings,
  currency and calendar.
  - Keys are prefixed with the account id. Taps open the right account first (`?account=<id>`).
  - When several accounts have reminders on, titles name the account.
  - A reminder never includes another account's data.
  - The backup reminder is app-wide and planned once.
- Privacy mode removes amounts from notification text.
- Reminders of a PIN-protected account use a generic text with no source names, titles or amounts.
- Re-planning happens (debounced 2 s) whenever data, settings, events, backup state or the date
  change, and on app resume. Tapping a notification opens the related screen.
- `notification_history` records what was **scheduled**. Scheduling is never presented as delivery.

## Platform behaviour

| Platform | Behaviour |
|---|---|
| Android | OS-scheduled (`zonedSchedule`), survives app close and reboot (boot receiver). Uses inexact alarms unless exact alarms are permitted, so delivery may shift by a few minutes. Android 13+ asks for notification permission. |
| iOS | OS-scheduled via UNUserNotificationCenter; permission requested explicitly. Max 64 pending. |
| Web | Browsers cannot schedule notifications in the background. EarnLens shows due reminders via in-page timers **only while a tab is open** (next 24 h). The settings screen states this. |

## Future providers

Email, SMS and push require a server (credentials must never ship in the app). A backend would own
delivery; the app would register a `NotificationProvider` that sends preferences/events to the
server. The planner output (`PlannedNotification`) is channel-agnostic, so income modules need no
changes — implement the interface and register it in `dependency_injection.dart`.
