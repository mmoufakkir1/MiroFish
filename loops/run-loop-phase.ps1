#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][ValidateSet('plan', 'execute', 'validate')][string]$Phase,
    [Parameter(Mandatory = $true)][string]$Prompt,
    [ValidateSet('auto', 'codex', 'claude', 'opencode', 'print')][string]$Agent = 'auto',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command node -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Error 'Node.js is required to run the portable phase launcher.'
    exit 2
}
$runner = Join-Path $PSScriptRoot 'run-loop-phase.mjs'
$arguments = @($runner, '--project-root', $ProjectRoot, '--phase', $Phase, '--prompt', $Prompt, '--agent', $Agent)
if ($WhatIf) { $arguments += '--what-if' }
& node @arguments
exit $LASTEXITCODE
