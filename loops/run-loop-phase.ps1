[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [Parameter(Mandatory = $true)]
    [ValidateSet('plan', 'execute', 'validate')]
    [string]$Phase,
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [ValidateSet('auto', 'codex', 'claude', 'opencode', 'print')]
    [string]$Agent = 'auto',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
$policyPath = Join-Path $projectPath 'loops\model-policy.yaml'
if (-not (Test-Path -LiteralPath $policyPath)) { throw "Missing model policy: $policyPath" }

$policy = Get-Content -Raw -LiteralPath $policyPath
$providerMatch = [regex]::Match($policy, '(?m)^provider:\s*(?<value>[^\s#]+)\s*$')
$phaseMatch = [regex]::Match($policy, "(?ms)^\s{2}${Phase}:\s*\r?\n(?<block>(?:\s{4}.*\r?\n?)+?)(?=^\S|^\s{2}\w+:|\z)")
$modelMatch = if ($phaseMatch.Success) { [regex]::Match($phaseMatch.Groups['block'].Value, '(?m)^\s{4}model:\s*(?<value>[^\s#]+)\s*$') } else { $null }

if (-not $providerMatch.Success -or -not $phaseMatch.Success -or -not $modelMatch.Success) {
    throw "Invalid model policy: provider and $Phase.model are required in $policyPath"
}

$provider = $providerMatch.Groups['value'].Value
$model = $modelMatch.Groups['value'].Value
if ($Agent -eq 'auto') { $Agent = $provider }

$phasePrompt = @"
Run the $Phase phase of the repository agent loop.

Read loops/agent-development-loop.md, loops/quality-gate.md, and the selected loop.
Apply the quality gate to correctness, security, and efficiency. Validate all existing
code with quality-audit-loop.md when the requested scope is repository-wide.
Missing required checks or unresolved blocking findings prevent completion.

Required policy: loops/model-policy.yaml
Selected provider: $provider
Selected model: $model

$Prompt

Record the provider, phase, model, commands, results, skipped checks, and residual risk
in .ai/progress.md or the completion report. Do not claim completion without evidence.
"@.Trim()

switch ($Agent) {
    'codex' {
        if ($provider -ne 'codex') { throw "Policy provider '$provider' cannot be launched with Codex. Update model-policy.yaml first." }
        $arguments = @('exec', '-C', $projectPath, '-m', $model, $phasePrompt)
        $display = "codex exec -C `"$projectPath`" -m $model `"<phase prompt>`""
        $command = { & codex @arguments }
    }
    'claude' {
        if ($provider -ne 'claude') { throw "Policy provider '$provider' cannot be launched with Claude. Update model-policy.yaml first." }
        $arguments = @('--model', $model, '--append-system-prompt', 'Use the repository agent loop and model policy exactly.', '-p', $phasePrompt)
        $display = "claude --model $model -p `"<phase prompt>`""
        $command = { Push-Location $projectPath; try { & claude @arguments } finally { Pop-Location } }
    }
    'opencode' {
        if ($provider -ne 'opencode') { throw "Policy provider '$provider' cannot be launched with OpenCode. Update model-policy.yaml first." }
        $modelName = if ($model.Contains('/')) { $model } else { "$provider/$model" }
        $arguments = @('run', '--dir', $projectPath, '-m', $modelName, $phasePrompt)
        $display = "opencode run --dir `"$projectPath`" -m $modelName `"<phase prompt>`""
        $command = { & opencode @arguments }
    }
    'print' {
        $display = "Provider: $provider`nModel: $model`nPhase: $Phase`nProject: $projectPath`nPrompt:`n$phasePrompt"
        $command = { Write-Output $display }
    }
    default {
        throw "Unsupported agent '$Agent'. Use auto, codex, claude, opencode, or print."
    }
}

if ($WhatIf) {
    Write-Output "Would launch $display"
} else {
    Write-Output "Launching $Agent with $model for $Phase"
    & $command
    if ($Agent -ne 'print') { exit $LASTEXITCODE }
}
