// Export separate icon roles: rectangular Explorer/desktop and square-W window/tray.
// Requires Node.js and sharp; optional --brand-dir exports a separate local size library.
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'assets/images/wof_logo_full.png');
const iconSizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256];
const exportSizes = [...iconSizes, 512, 1024];

function makeIco(images) {
  const header = Buffer.alloc(6 + images.length * 16);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = header.length;
  images.forEach(({ size, png }, index) => {
    const entry = 6 + index * 16;
    header.writeUInt8(size === 256 ? 0 : size, entry);
    header.writeUInt8(size === 256 ? 0 : size, entry + 1);
    header.writeUInt16LE(1, entry + 4);
    header.writeUInt16LE(32, entry + 6);
    header.writeUInt32LE(png.length, entry + 8);
    header.writeUInt32LE(offset, entry + 12);
    offset += png.length;
  });
  return Buffer.concat([header, ...images.map(({ png }) => png)]);
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 2 || args[0] !== '--brand-dir')) {
    throw new Error('Usage: node generate_windows_icons.cjs [--brand-dir <directory>]');
  }
  const brandDir = args.length ? path.resolve(args[1]) : null;
  const logo = await fs.readFile(source);
  const squareW = await fs.readFile(path.join(root, 'assets/icons/wof_icon.svg'));
  const windowImages = new Map();
  const images = new Map();
  for (const size of exportSizes) {
    const png = await sharp(logo).resize(size, size, {
      fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 }, kernel: 'lanczos3',
    }).png().toBuffer();
    images.set(size, png);
    const oversampled = await sharp(squareW).resize(size * 4, size * 4).png().toBuffer();
    windowImages.set(size, await sharp(oversampled).resize(size, size, { kernel: 'lanczos3' }).png().toBuffer());
  }
  const ico = makeIco(iconSizes.map(size => ({ size, png: images.get(size) })));
  for (const target of ['assets/icons/app_icon.ico', 'windows/runner/resources/app_icon.ico']) {
    await fs.writeFile(path.join(root, target), ico);
  }
  const windowIco = makeIco(iconSizes.map(size => ({ size, png: windowImages.get(size) })));
  for (const target of ['assets/icons/window_icon.ico', 'windows/runner/resources/window_icon.ico']) {
    await fs.writeFile(path.join(root, target), windowIco);
  }
  if (brandDir) {
    const sizeDir = path.join(brandDir, 'Windows完整Logo尺寸');
    await fs.mkdir(sizeDir, { recursive: true });
    await fs.writeFile(path.join(brandDir, 'wof_full_icon_1024.png'), images.get(1024));
    await fs.writeFile(path.join(brandDir, 'app_icon.ico'), ico);
    await fs.writeFile(path.join(brandDir, 'window_icon.ico'), windowIco);
    for (const size of exportSizes.filter(size => size !== 1024)) {
      await fs.writeFile(path.join(sizeDir, `wof_full_icon_${size}.png`), images.get(size));
    }
  }
  console.log(`Generated desktop ICO: ${iconSizes.join(', ')}px; ${ico.length} bytes`);
  console.log(`Generated window/tray W ICO: ${windowIco.length} bytes`);
  if (brandDir) console.log(`Brand exports: ${brandDir}`);
}

main().catch(error => { console.error(error); process.exitCode = 1; });
