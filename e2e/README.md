# bloom. — native Android E2E + Allure

This folder contains the native end-to-end suite for the Flutter app. It runs the
real Android build on an emulator, captures screenshots, and produces a readable
Allure report.

## What you need

- Flutter 3.47+ and an Android SDK (the app is Android-only).
- A booted Android emulator or a connected device. The scripts target
  `emulator-5554` (the `Pixel_7a` AVD).
- Java 17+ for the Allure CLI.
- Node 20+.

Start the emulator with:

```
flutter emulators --launch Pixel_7a
```

## Run everything

```
npm install
npm run report
```

`npm run report` does two things:

1. `test:native` builds and installs the debug APK, then runs
   `flutter_app/integration_test/app_test.dart` with `flutter drive` on
   `emulator-5554`.
2. `allure:build` converts the structured test report into Allure results and
   generates the HTML report.

The run produces:

| Path | Contents |
| --- | --- |
| `artifacts/screenshots/` | One PNG per key step, plus failure screenshots |
| `artifacts/integration_response_data.json` | Raw test/step report from the device |
| `allure-results/` | Allure result JSON and attachments |
| `allure-report/` | The generated HTML report |
| `allure-summary.json` | Pass/fail totals and suite breakdown |

## View the report

```
npm run serve:report
```

Then open [http://127.0.0.1:4040](http://127.0.0.1:4040). The report opens on the
Overview page. Use **Suites** for the grouped test list; each test shows its
description, numbered steps, duration and screenshots. The **Behaviors** view
groups the same tests by feature.

## Coverage

The suite has 18 tests across eight features:

- **First run** — fresh install starts empty, shows the new gold logo and
  welcome actions, and exposes a generic profile instead of a demo persona.
- **App shell & navigation** — branded dashboard, all five tabs, Home shortcuts.
- **Tasks** — create (with category), complete, search/filter, delete + undo.
- **Habits** — create a break habit with a custom icon, check off and verify the
  streak, filter Build/Break, delete + undo.
- **Journal** — write a reflection with a chosen mood, verify persistence, delete
  + undo.
- **Insights** — totals, strongest-habit card, activity chart, mood breakdown.
- **Profile & preferences** — profile stats, dark theme, explicit sample-data
  loading and notification sheet.
- **Home dashboard** — focus list advances after completion, mood carries into the
  Journal, and both celebration empty states.

Each test starts from a fresh in-memory store seeded with the app's sample data,
so tests are independent and do not depend on the device's saved state.

## How the reporting works

`integration_test/support/harness.dart` records each test's status, duration and
named steps. `binding.takeScreenshot()` stores the PNG bytes in the test report;
`test_driver/allure_driver.dart` writes them to `artifacts/screenshots/` on the
host. Finally, `tools/build-allure.mjs` turns that JSON into Allure results with
labels, descriptions, steps, attachments, environment and categories.

## Useful commands

| Command | What it does |
| --- | --- |
| `npm run test:native` | Run the E2E suite only |
| `npm run allure:build` | Rebuild the report from the last run |
| `npm run serve:report` | Serve the HTML report on port 4040 |
| `npm run logo` | Re-export the logo and launcher icons |

## Adding a test

Add a `registerTest(...)` block in `flutter_app/integration_test/app_test.dart`,
use `runStep(...)` for each user-visible action, and call
`capture(tester, 'what is on screen')` after a meaningful checkpoint. The
converter picks up new tests and screenshots automatically.
