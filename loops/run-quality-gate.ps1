#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [ValidateSet('change', 'repository')][string]$Scope = 'change',
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'run-quality-gate.mjs'
if (-not (Get-Command node -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Error 'Node.js is required to run the portable quality gate.'
    exit 2
}
$arguments = @($runner, '--project-root', $ProjectRoot, '--scope', $Scope)
if ($Verify) { $arguments += '--verify' }
& node @arguments
exit $LASTEXITCODE
