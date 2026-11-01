#!/usr/bin/env node
// Portable required-check gate. Check output is drained and never persisted.
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const categories = new Set(['format', 'lint', 'types', 'tests', 'build', 'secrets', 'dependencies', 'static', 'integration', 'performance', 'docs', 'config']);
const scopes = new Set(['change', 'repository']);

function argumentsOf(argv) {
  const result = new Map();
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i].replace(/^-+/, '').replace(/-/g, '').toLowerCase();
    if (!key) throw new Error('Invalid command-line argument.');
    if (key === 'verify') result.set(key, true);
    else if (key === 'projectroot' || key === 'scope') result.set(key, argv[++i] ?? '');
    else throw new Error(`Unknown argument: ${argv[i]}`);
  }
  return result;
}

function containedPath(root, relative, { directory = false, allowMissing = false } = {}) {
  if (typeof relative !== 'string' || !relative || path.isAbsolute(relative) || relative.includes('\0')) throw new Error('Paths must be non-empty and relative to the project root.');
  const full = path.resolve(root, relative);
  const rel = path.relative(root, full);
  if (rel === '..' || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel)) throw new Error('A configured path escapes the project root.');
  let cursor = root;
  for (const segment of rel.split(path.sep).filter(Boolean)) {
    cursor = path.join(cursor, segment);
    try {
      if (fs.lstatSync(cursor).isSymbolicLink()) throw new Error('Gate paths must not traverse symbolic links.');
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }
  if (directory && (!fs.existsSync(full) || !fs.statSync(full).isDirectory())) throw new Error('A configured working directory does not exist.');
  if (!allowMissing && !directory && fs.existsSync(full) && !fs.statSync(full).isFile()) throw new Error('Gate path must be a regular file.');
  return full;
}

function runGit(root, args, encoding = 'utf8') {
  const result = spawnSync('git', ['-c', 'core.quotepath=false', ...args], { cwd: root, encoding, windowsHide: true, maxBuffer: 64 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error('Git metadata is unavailable; a repository root is required.');
  return result.stdout;
}

function sha256(value) { return createHash('sha256').update(value).digest('hex'); }

function codeSnapshot(root) {
  const gitRoot = String(runGit(root, ['rev-parse', '--show-toplevel'])).trim();
  if (path.resolve(gitRoot) !== root) throw new Error('ProjectRoot must be the Git repository root.');
  const head = String(runGit(root, ['rev-parse', '--verify', 'HEAD'])).trim();
  const paths = [...new Set(String(runGit(root, ['ls-files', '--cached', '--others', '--exclude-standard', '-z'])).split('\0').filter(p => p && !p.startsWith('.ai/')))].sort();
  const hash = createHash('sha256');
  hash.update(`${head}\0`);
  for (const relative of paths) {
    const file = containedPath(root, relative, { allowMissing: true });
    hash.update(`${relative}\0`);
    if (!fs.existsSync(file)) { hash.update('deleted'); continue; }
    const stat = fs.lstatSync(file);
    if (stat.isSymbolicLink() || !stat.isFile()) throw new Error('Symlink, submodule, or directory entries need a separately configured gate; snapshot is blocked.');
    hash.update(fs.readFileSync(file));
  }
  return hash.digest('hex');
}

function validatePolicy(policy, root) {
  if (!policy || Array.isArray(policy) || typeof policy !== 'object' || Object.keys(policy).sort().join(',') !== 'checks,version') throw new Error('Gate configuration must contain only version and checks.');
  if (policy.version !== 1 || !Array.isArray(policy.checks) || policy.checks.length === 0) throw new Error('Gate configuration needs version 1 and at least one required check.');
  const ids = new Set();
  for (const check of policy.checks) {
    const keys = ['arguments', 'category', 'executable', 'id', 'scopes', 'timeoutSeconds', 'workingDirectory'];
    if (!check || Array.isArray(check) || typeof check !== 'object' || Object.keys(check).sort().join(',') !== keys.sort().join(',')) throw new Error('Each check must contain exactly the documented fields.');
    if (typeof check.id !== 'string' || !/^[a-z][a-z0-9-]{0,63}$/.test(check.id) || ids.has(check.id.toLowerCase())) throw new Error('Check IDs must be unique lowercase names.');
    ids.add(check.id.toLowerCase());
    if (!categories.has(check.category)) throw new Error('Invalid check category.');
    if (!Array.isArray(check.scopes) || !check.scopes.length || check.scopes.some(s => !scopes.has(s))) throw new Error('Each check needs valid scopes.');
    if (typeof check.executable !== 'string' || !check.executable.trim() || check.executable.includes('\0')) throw new Error('A check executable is required.');
    if (!Array.isArray(check.arguments) || check.arguments.some(a => typeof a !== 'string' || a.includes('\0'))) throw new Error('Arguments must be strings without null characters.');
    if (!Number.isInteger(check.timeoutSeconds) || check.timeoutSeconds < 1 || check.timeoutSeconds > 3600) throw new Error('Check timeoutSeconds must be an integer between 1 and 3600.');
    containedPath(root, check.workingDirectory, { directory: true });
  }
}

function invokeCheck(root, check) {
  const started = Date.now();
  return new Promise(resolve => {
    const result = { id: check.id, category: check.category, executable: check.executable, arguments: check.arguments, workingDirectory: check.workingDirectory, timeoutSeconds: check.timeoutSeconds, status: 'blocked', exitCode: null, durationSeconds: 0, reason: '' };
    let child;
    let settled = false;
    const finish = (status, code, reason = '') => {
      if (settled) return;
      settled = true; clearTimeout(timer);
      result.status = status; result.exitCode = code; result.reason = reason;
      result.durationSeconds = Math.round((Date.now() - started) / 10) / 100;
      resolve(result);
    };
    const timer = setTimeout(() => { child?.kill(); finish('fail', null, 'timeout'); }, check.timeoutSeconds * 1000);
    try {
      child = spawn(check.executable, check.arguments, { cwd: containedPath(root, check.workingDirectory, { directory: true }), stdio: 'ignore', windowsHide: true, shell: false });
      child.once('error', () => finish('blocked', null, 'Unable to execute required check; verify executable, arguments, and environment.'));
      child.once('close', code => finish(code === 0 ? 'pass' : 'fail', code, code === 0 ? '' : 'nonzero exit code'));
    } catch {
      finish('blocked', null, 'Unable to execute required check; verify executable, arguments, and environment.');
    }
  });
}

async function main() {
  const args = argumentsOf(process.argv.slice(2));
  if (!args.has('projectroot')) throw new Error('ProjectRoot is required.');
  const scope = args.get('scope') ?? 'change';
  if (!scopes.has(scope)) throw new Error('Scope must be change or repository.');
  const root = fs.realpathSync(args.get('projectroot'));
  const policyPath = containedPath(root, 'loops/quality-gate.json');
  const reportPath = containedPath(root, '.ai/quality-gate-result.json', { allowMissing: true });
  let policy;
  try { policy = JSON.parse(fs.readFileSync(policyPath, 'utf8')); } catch { throw new Error('Gate configuration is missing or not valid JSON.'); }
  validatePolicy(policy, root);
  const selected = policy.checks.filter(check => check.scopes.includes(scope));
  if (!selected.length) throw new Error('No required checks are configured for the requested scope.');
  const policyHash = sha256(fs.readFileSync(policyPath));
  const snapshot = codeSnapshot(root);
  if (args.has('verify')) {
    let report;
    try { report = JSON.parse(fs.readFileSync(reportPath, 'utf8')); } catch { throw new Error('No valid gate evidence exists; run the gate first.'); }
    if (report.version !== 1 || report.project !== root || report.scope !== scope || report.snapshot !== snapshot || report.policyHash !== policyHash) {
      console.log('Gate evidence is stale or belongs to another scope/project; rerun required checks.'); process.exitCode = 3; return;
    }
    if (report.status !== 'pass') { console.log('Recorded automated gate did not pass.'); process.exitCode = 1; return; }
    if (!Array.isArray(report.checks) || report.checks.length !== selected.length || selected.some(check => report.checks.filter(e => e.id === check.id && e.status === 'pass' && e.exitCode === 0).length !== 1)) throw new Error('Recorded check evidence is incomplete or failed.');
    console.log(`Automated gate evidence matches the current ${scope} snapshot. Manual review is still required.`); return;
  }
  const startedAt = new Date().toISOString();
  const results = [];
  for (const check of selected) {
    const result = await invokeCheck(root, check);
    results.push(result); console.log(`${result.id}: ${result.status}`);
  }
  let status = results.some(result => result.status === 'blocked') ? 'blocked' : results.some(result => result.status === 'fail') ? 'fail' : 'pass';
  let exitCode = status === 'blocked' ? 2 : status === 'fail' ? 1 : 0;
  if (codeSnapshot(root) !== snapshot || sha256(fs.readFileSync(policyPath)) !== policyHash) { status = 'stale'; exitCode = 3; }
  const report = { version: 1, project: root, scope, snapshot, policyHash, startedAt, finishedAt: new Date().toISOString(), status, checks: results };
  const statePath = containedPath(root, '.ai', { allowMissing: true });
  fs.mkdirSync(statePath, { recursive: true });
  const temporaryPath = path.join(statePath, `${process.pid}-${Date.now()}.tmp`);
  try { fs.writeFileSync(temporaryPath, `${JSON.stringify(report, null, 2)}\n`, { encoding: 'utf8', flag: 'wx' }); fs.renameSync(temporaryPath, reportPath); }
  finally { try { fs.unlinkSync(temporaryPath); } catch {} }
  console.log(`Automated gate: ${status}. Evidence: .ai/quality-gate-result.json`);
  process.exitCode = exitCode;
}

main().catch(error => { console.log(`Quality gate blocked: ${error.message}`); process.exitCode = 2; });
