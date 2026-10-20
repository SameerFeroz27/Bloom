import sharp from 'sharp';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const app = path.join(root, 'flutter_app');
const source = path.join(app, 'assets', 'branding', 'bloom_logo_master.jpg');

// The supplied artwork is a gold emblem on a dark-green field. Crop a square
// around the emblem so the same source drives the app mark and every launcher
// density.
const crop = { left: 380, top: 90, width: 640, height: 640 };
const background = { r: 40, g: 73, b: 54, alpha: 1 };

const render = (size) => sharp(source).extract(crop).resize(size, size);

async function write(file, image) {
  await mkdir(path.dirname(file), { recursive: true });
  const output = file.endsWith('.jpg')
    ? image.jpeg({ quality: 90, mozjpeg: true })
    : image.png({ compressionLevel: 9 });
  await output.toFile(file);
  console.log('wrote', path.relative(root, file));
}

/// Adaptive icons are masked and cropped by the launcher, so keep the emblem
/// inside the safe zone on a matching green field.
async function adaptiveForeground(size) {
  const inner = Math.round(size * 0.70);
  const logo = await render(inner).png().toBuffer();
  const mask = Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${inner}" height="${inner}">
       <circle cx="${inner / 2}" cy="${inner / 2}" r="${inner / 2}" fill="#fff"/>
     </svg>`,
  );
  const circle = await sharp(logo)
    .composite([{ input: mask, blend: 'dest-in' }])
    .png()
    .toBuffer();

  return sharp({
    create: { width: size, height: size, channels: 4, background },
  }).composite([{ input: circle, gravity: 'center' }]);
}

// 512 px covers the largest in-app use (the welcome medallion) even at 3x.
await write(path.join(app, 'assets', 'branding', 'bloom_logo.jpg'), render(512));

const mipmaps = [
  ['mipmap-mdpi', 48, 108],
  ['mipmap-hdpi', 72, 162],
  ['mipmap-xhdpi', 96, 216],
  ['mipmap-xxhdpi', 144, 324],
  ['mipmap-xxxhdpi', 192, 432],
];

for (const [folder, legacy, foreground] of mipmaps) {
  const res = path.join(app, 'android', 'app', 'src', 'main', 'res', folder);
  await write(path.join(res, 'ic_launcher.png'), render(legacy));
  await write(path.join(res, 'ic_launcher_round.png'), render(legacy));
  await write(path.join(res, 'ic_launcher_foreground.png'), await adaptiveForeground(foreground));
}
