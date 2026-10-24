#!/usr/bin/env node
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

function parseArguments(argv) {
  const args = new Map();
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i].replace(/^-+/, '').replace(/-/g, '').toLowerCase();
    if (['projectroot', 'phase', 'prompt', 'agent'].includes(key)) args.set(key, argv[++i] ?? '');
    else if (key === 'whatif') args.set(key, true);
    else throw new Error(`Unknown argument: ${argv[i]}`);
  }
  return args;
}

function policyValue(policy, phase) {
  const provider = policy.match(/^provider:\s*([^\s#]+)\s*$/m)?.[1];
  const section = policy.match(new RegExp(`^  ${phase}:\\s*\\r?\\n((?:    .*\\r?\\n?)+)`, 'm'))?.[1];
  const model = section?.match(/^    model:\s*([^\s#]+)\s*$/m)?.[1];
  if (!provider || !model) throw new Error(`Invalid model policy: provider and ${phase}.model are required.`);
  return { provider, model };
}

function quoteDisplay(value) { return JSON.stringify(value); }

async function main() {
  const args = parseArguments(process.argv.slice(2));
  const rootArg = args.get('projectroot');
  const phase = args.get('phase');
  const prompt = args.get('prompt');
  if (!rootArg || !['plan', 'execute', 'validate'].includes(phase) || !prompt) throw new Error('ProjectRoot, a valid Phase, and Prompt are required.');
  const root = fs.realpathSync(rootArg);
  const policyPath = path.join(root, 'loops', 'model-policy.yaml');
  if (!fs.existsSync(policyPath)) throw new Error(`Missing model policy: ${policyPath}`);
  const { provider, model } = policyValue(fs.readFileSync(policyPath, 'utf8'), phase);
  const agent = args.get('agent') ?? 'auto';
  const selected = agent === 'auto' ? provider : agent;
  const phasePrompt = `Run the ${phase} phase of the repository agent loop.\n\nRead loops/agent-development-loop.md, loops/quality-gate.md, and the selected loop.\nApply the quality gate to correctness, security, and efficiency. Validate all existing\ncode with quality-audit-loop.md when the requested scope is repository-wide.\nMissing required checks or unresolved blocking findings prevent completion.\n\nRequired policy: loops/model-policy.yaml\nSelected provider: ${provider}\nSelected model: ${model}\n\n${prompt}\n\nRecord the provider, phase, model, commands, results, skipped checks, and residual risk\nin .ai/progress.md or the completion report. Do not claim completion without evidence.`;
  let executable; let cliArgs; let display;
  if (selected === 'print') { console.log(`Provider: ${provider}\nModel: ${model}\nPhase: ${phase}\nProject: ${root}\nPrompt:\n${phasePrompt}`); return; }
  if (selected !== provider || !['codex', 'claude', 'opencode'].includes(selected)) throw new Error(`Policy provider '${provider}' cannot be launched with '${selected}'. Update model-policy.yaml first.`);
  if (selected === 'codex') { executable = 'codex'; cliArgs = ['exec', '-C', root, '-m', model, phasePrompt]; display = `codex exec -C ${quoteDisplay(root)} -m ${model} "<phase prompt>"`; }
  else if (selected === 'claude') { executable = 'claude'; cliArgs = ['--model', model, '--append-system-prompt', 'Use the repository agent loop and model policy exactly.', '-p', phasePrompt]; display = `claude --model ${model} -p "<phase prompt>"`; }
  else { executable = 'opencode'; const modelName = model.includes('/') ? model : `${provider}/${model}`; cliArgs = ['run', '--dir', root, '-m', modelName, phasePrompt]; display = `opencode run --dir ${quoteDisplay(root)} -m ${modelName} "<phase prompt>"`; }
  if (args.has('whatif')) { console.log(`Would launch ${display}`); return; }
  console.log(`Launching ${selected} with ${model} for ${phase}`);
  const child = spawn(executable, cliArgs, { cwd: root, stdio: 'inherit', windowsHide: true, shell: false });
  child.once('error', error => { console.error(`Unable to launch ${selected}: ${error.message}`); process.exitCode = 2; });
  child.once('close', code => { process.exitCode = code ?? 1; });
}

main().catch(error => { console.error(`Phase launcher blocked: ${error.message}`); process.exitCode = 2; });
