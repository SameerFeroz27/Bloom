# bloom. — Flutter (Android)

Flutter port of the React prototype that sits in the parent folder. Same screens,
same colours, same behaviour. Android only.

## Run it

```
flutter pub get
flutter run
```

Build an installable APK with `flutter build apk --release`. The debug build lands
at `build/app/outputs/flutter-apk/app-debug.apk`.

Run the widget tests with `flutter test`.

Two packages are used: `google_fonts` (Manrope + DM Sans) and `shared_preferences`
(saves the data on the device). The fonts are bundled under `assets/fonts/`, so the
app does not need a network connection to render correctly.

## Branding

The new gold-on-green mark is supplied as
`assets/branding/bloom_logo_master.jpg` (source artwork) and exported to
`assets/branding/bloom_logo.jpg` for the top bar and welcome/empty state. The
same artwork drives the Android launcher icon (legacy, round and adaptive) at
every density. Regenerate the exports with `cd ../e2e && npm run logo`.

## Native E2E tests

The Android E2E suite lives in `integration_test/app_test.dart` and is driven by
`test_driver/allure_driver.dart`. Run it against a booted emulator or device:

```
cd ../e2e
npm install
npm run report
```

This builds and installs the app, runs 18 user-journey tests (first run,
navigation, tasks, habits, journal, insights, profile, notifications, mood and
empty states), saves a screenshot for each key step, and writes an Allure
report. See `e2e/README.md` for details and the report URL.

## Home shows only what is left

The two Home lists — "Today's focus" and "Your daily habits" — show only unfinished
work, three items each. Checking something off fades the row out, collapses its
space, and the next item moves up. When nothing is left the card shows an all-clear
message instead.

The Tasks and Habits tabs are deliberately *not* filtered this way: they show
everything, with the All / Open / Done and All / Build / Break filters. That is
where you go to see or undo something you already checked off.

`RemovableRow` in `lib/widgets/rows.dart` implements the exit animation. It delays
the actual change until the animation ends, so a row takes a `leave` callback
instead of calling the store itself.

## Where things live

| File | What it holds |
| --- | --- |
| `lib/main.dart` | Entry point. Loads saved data, then starts the app. |
| `lib/app.dart` | The shell: top bar, bottom nav and the add button. |
| `lib/store.dart` | All the data, every action, and saving. |
| `lib/models.dart` | The shapes: Task, Habit, Entry, moods, icons, tones. |
| `lib/theme.dart` | Colours, text styles and shadows, for light and dark. |
| `lib/screens/` | One file per tab. |
| `lib/widgets/` | Shared pieces: rows, sheets, progress ring, mood face. |

## How the state works

`BloomStore` is a `ChangeNotifier` that holds everything. `BloomScope` hands it to
any widget that asks for it with `BloomScope.of(context)`, and that widget then
rebuilds whenever the data changes.

To add a new action, add a method to `BloomStore` and call it from a screen.

## Data

Saved on the device under the key `bloom.store.v1`, as JSON. The shape is the same
as the React prototype's, so data from the web version can be pasted straight in.

A fresh install starts empty — no demo persona and no sample tasks or habits. The
welcome screen offers the first task, first habit and first reflection actions.
Profile has an **Add your name** action (pencil) that stores an optional name and
uses it in the Home greeting and avatar; leave it empty to keep the greeting
anonymous. Sample content is only loaded when the user explicitly chooses **Load
sample data** in Profile.

There is no server and no account. Everything stays on the device.

## Notes

- The prototype's Pixel frame, fake status bar and caption are gone. On a real
  phone the system draws those, so the app fills the screen.
- `google_fonts` is pinned to 6.x. Version 9 depends on a vendored `material_ui`
  package whose `TextTheme` is a different type from `package:flutter/material.dart`,
  which breaks mixing it with normal Flutter widgets.
- Streak logic counts today as optional, so a day you have not checked off yet does
  not break a streak.
- Only the `android/` target exists. `ios/`, `web/` and `windows/` were removed;
  add one back with `flutter create --platforms=<name> .` if it is ever needed.
