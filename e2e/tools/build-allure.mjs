import { createHash, randomUUID } from 'node:crypto';
import { copyFile, mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const e2e = path.resolve(here, '..');
const root = path.resolve(e2e, '..');
const artifacts = path.join(e2e, 'artifacts');
const screenshots = path.join(artifacts, 'screenshots');
const results = path.join(e2e, 'allure-results');
const summaryFile = path.join(e2e, 'allure-summary.json');

const reportPath = path.join(artifacts, 'integration_response_data.json');

async function readReport() {
  let raw;
  try {
    raw = await readFile(reportPath, 'utf8');
  } catch {
    throw new Error(
      `No native test report found at ${reportPath}. Run the suite with "npm run test:native" first.`,
    );
  }
  const data = JSON.parse(raw);
  const tests = data.bloom_tests;
  if (!Array.isArray(tests) || tests.length === 0) {
    throw new Error(
      'The integration test report has no "bloom_tests" entries. The app may have failed before reporting.',
    );
  }
  return tests;
}

const humanize = (value) => {
  const label = value.includes('--') ? value.split('--').pop() : value;
  return label
    .replaceAll('-', ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^\w/, (c) => c.toUpperCase());
};

const slugify = (value) =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const stableId = (value) => createHash('sha1').update(value).digest('hex');

function classify(record) {
  if (record.status === 'passed') return 'passed';
  const message = `${record.message ?? ''}\n${record.trace ?? ''}`;
  if (/Expected:|Which:|TestFailure|Test failed/.test(message)) return 'failed';
  return 'broken';
}

function stepJson(step, attachmentsByScreenshot) {
  const start = step.startedAt ?? Date.now();
  const stop = step.stoppedAt ?? start + (step.durationMs ?? 0);
  const attachments = [];
  const name = step.screenshot ? attachmentsByScreenshot.get(step.screenshot) : undefined;
  if (name) attachments.push(name);

  return {
    name: step.name,
    status: step.status ?? 'passed',
    statusDetails: step.message ? { message: step.message } : {},
    stage: 'finished',
    start,
    stop,
    steps: [],
    attachments,
    parameters: [],
  };
}

async function main() {
  const tests = await readReport();
  await rm(results, { recursive: true, force: true });
  await mkdir(results, { recursive: true });
  await mkdir(screenshots, { recursive: true });

  const availableScreenshots = new Set(await readdir(screenshots));
  const resultFiles = [];
  const summary = {
    generatedAt: new Date().toISOString(),
    total: 0,
    passed: 0,
    failed: 0,
    broken: 0,
    skipped: 0,
    screenshots: 0,
    suites: {},
    tests: [],
  };

  for (const record of tests) {
    const uuid = randomUUID();
    const fullName = `${record.suite} › ${record.name}`;
    const historyId = stableId(fullName);
    const status = classify(record);
    const start = record.startedAt ?? Date.now();
    const stop = record.stoppedAt ?? start + (record.durationMs ?? 0);

    const attachmentsByScreenshot = new Map();
    const testAttachments = [];
    let screenshotCount = 0;

    let shotIndex = 0;
    for (const name of record.screenshots ?? []) {
      if (!availableScreenshots.has(`${name}.png`)) continue;
      shotIndex += 1;
      // Short sources keep the full path well under Windows' legacy path limit.
      const source = `${uuid}-shot-${String(shotIndex).padStart(2, '0')}.png`;
      await copyFile(path.join(screenshots, `${name}.png`), path.join(results, source));
      const attachment = {
        name: `Screenshot — ${humanize(name)}`,
        source,
        type: 'image/png',
      };
      attachmentsByScreenshot.set(name, attachment);
      screenshotCount += 1;
    }

    const stepScreenshots = new Set(
      (record.steps ?? []).map((step) => step.screenshot).filter(Boolean),
    );

    // Attach a screenshot once: on its step when there is one, otherwise on the
    // test itself. This avoids duplicate attachments in the report.
    for (const [name, attachment] of attachmentsByScreenshot) {
      if (!stepScreenshots.has(name)) {
        testAttachments.push(attachment);
      }
    }

    // The new app logo is evidence for the branding test.
    if (record.name === 'Home shows the branded dashboard') {
      const logoSource = `${uuid}-app-logo.png`;
      const logo = path.join(root, 'flutter_app', 'assets', 'branding', 'bloom_logo.jpg');
      await copyFile(logo, path.join(results, logoSource));
      testAttachments.push({
        name: 'App logo (new brand mark)',
        source: logoSource,
        type: 'image/png',
      });
    }

    const steps = (record.steps ?? []).map((step) =>
      stepJson(step, attachmentsByScreenshot),
    );

    const result = {
      uuid,
      historyId,
      testCaseId: historyId,
      fullName,
      name: record.name,
      description: record.description ?? '',
      status,
      statusDetails:
        status === 'passed'
          ? { known: false, muted: false, flaky: false }
          : {
              known: false,
              muted: false,
              flaky: false,
              message: record.message ?? 'Test failed',
              trace: record.trace ?? '',
            },
      stage: 'finished',
      start,
      stop,
      labels: [
        { name: 'suite', value: record.suite },
        { name: 'feature', value: record.suite },
        { name: 'story', value: record.name },
        { name: 'severity', value: record.severity ?? 'normal' },
        { name: 'owner', value: 'QA' },
        { name: 'language', value: 'dart' },
        { name: 'framework', value: 'Flutter integration_test' },
        { name: 'host', value: 'Pixel 7a emulator' },
        { name: 'package', value: `bloom.e2e.${slugify(record.suite ?? 'suite')}` },
        ...(record.tags ?? []).map((tag) => ({ name: 'tag', value: tag })),
      ],
      parameters: [],
      steps,
      attachments: testAttachments,
      links: [],
    };

    const file = path.join(results, `${uuid}-result.json`);
    await writeFile(file, JSON.stringify(result, null, 2));
    resultFiles.push(file);

    summary.total += 1;
    summary[status] = (summary[status] ?? 0) + 1;
    summary.screenshots += screenshotCount;
    summary.suites[record.suite] = (summary.suites[record.suite] ?? 0) + 1;
    summary.tests.push({
      suite: record.suite,
      name: record.name,
      status,
      durationMs: record.durationMs ?? 0,
      steps: (record.steps ?? []).length,
      screenshots: screenshotCount,
    });
  }

  const environment = [
    'app.name=bloom.',
    'app.version=0.1.0+1',
    'app.package=com.example.bloom',
    'app.platform=Android (native)',
    'device.name=Pixel 7a (Android emulator)',
    'device.resolution=1080x2400',
    'android.api=37',
    'test.framework=Flutter integration_test',
    'test.runner=flutter drive',
    'flutter.version=3.47.5',
    'dart.version=3.13.4',
    'suite.name=bloom native Android E2E',
    `run.date=${new Date().toISOString()}`,
  ].join('\n');

  await writeFile(path.join(results, 'environment.properties'), `${environment}\n`);

  await writeFile(
    path.join(results, 'executor.json'),
    JSON.stringify(
      {
        name: 'ZCode local runner',
        type: 'local',
        buildName: `bloom-native-e2e-${new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-')}`,
      },
      null,
      2,
    ),
  );

  await writeFile(
    path.join(results, 'categories.json'),
    JSON.stringify(
      [
        {
          name: 'Assertion failures',
          matchedStatuses: ['failed'],
          messageRegex: '.*(Expected:|Which:|TestFailure).*',
        },
        {
          name: 'Timeout or missing element',
          matchedStatuses: ['broken', 'failed'],
          messageRegex: '.*(TimeoutException|pumpAndSettle timed out|not found|No element).*',
        },
        {
          name: 'Unexpected app error',
          matchedStatuses: ['broken', 'failed'],
          messageRegex: '.*',
        },
      ],
      null,
      2,
    ),
  );

  await writeFile(
    path.join(results, 'history-trend.json'),
    JSON.stringify(
      [
        {
          buildOrder: 1,
          reportName: 'bloom. native Android E2E',
          reportUrl: '',
          data: {
            failed: summary.failed,
            broken: summary.broken,
            skipped: summary.skipped,
            passed: summary.passed,
            unknown: 0,
            total: summary.total,
          },
        },
      ],
      null,
      2,
    ),
  );

  await writeFile(summaryFile, JSON.stringify(summary, null, 2));

  console.log(
    `Allure results written: ${resultFiles.length} tests, ${summary.screenshots} screenshots.`,
  );
  console.log(
    `Status: ${summary.passed} passed, ${summary.failed} failed, ${summary.broken} broken, ${summary.skipped} skipped.`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
