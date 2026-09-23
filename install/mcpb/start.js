// dist/index.js only boots when process.argv[1] resolves to its own module
// URL. Claude Desktop can launch an installed extension through a symlinked
// directory, which makes that comparison fail; the process then exits without
// serving anything and without printing an error, so the extension installs
// cleanly and contributes zero tools. Normalising argv[1] to the real path of
// index.js keeps the guard true however the extension directory is reached.
import { realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const entry = fileURLToPath(new URL('./index.js', import.meta.url));
process.argv[1] = realpathSync(entry);
await import('./index.js');
