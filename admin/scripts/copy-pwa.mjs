import { cpSync, existsSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const adminDir = dirname(fileURLToPath(new URL('.', import.meta.url)));
const repoRoot = dirname(adminDir);
const webBuild = join(repoRoot, 'mobile', 'build', 'web');
const appDir = join(adminDir, 'dist', 'app');
const htaccessSrc = join(repoRoot, 'mobile', 'web', '.htaccess');

if (!existsSync(webBuild)) {
  console.warn(
    '[copy-pwa] No Flutter web build at mobile/build/web.\n' +
      '  /app/ will 404 until you run: flutter build web --release --base-href /app/\n' +
      '  Then re-run npm run build (or scripts/build-pwa.ps1).',
  );
  process.exit(0);
}

if (existsSync(appDir)) {
  rmSync(appDir, { recursive: true, force: true });
}
mkdirSync(appDir, { recursive: true });
cpSync(webBuild, appDir, { recursive: true });
if (existsSync(htaccessSrc)) {
  copyFileSync(htaccessSrc, join(appDir, '.htaccess'));
}
console.log('[copy-pwa] Copied Flutter PWA into dist/app');
