#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [ValidateSet('change', 'repository')]
    [string]$Scope = 'change',
    [switch]$Verify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ContainedPath {
    param([string]$RelativePath, [switch]$Directory)

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath)) {
        throw 'Paths must be non-empty and relative to the project root.'
    }
    $path = [IO.Path]::GetFullPath((Join-Path $script:projectPath $RelativePath))
    $prefix = $script:projectPath.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $path.Equals($script:projectPath, $comparison) -and -not $path.StartsWith($prefix, $comparison)) {
        throw 'A configured path escapes the project root.'
    }
    $cursor = $path
    while (-not $cursor.Equals($script:projectPath, $comparison)) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -Force -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw 'Gate paths must not traverse symbolic links or junctions.'
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    if ($Directory -and -not (Test-Path -LiteralPath $path -PathType Container)) {
        throw 'A configured working directory does not exist.'
    }
    return $path
}

function Assert-Keys {
    param([System.Collections.IDictionary]$Object, [string[]]$Keys)
    foreach ($key in $Keys) {
        if (-not $Object.Contains($key)) { throw "Missing configuration field: $key" }
    }
    foreach ($key in $Object.Keys) {
        if ($Keys -notcontains $key) { throw "Unknown configuration field: $key" }
    }
}

function Invoke-GitText {
    param([string[]]$Arguments)
    $info = [Diagnostics.ProcessStartInfo]::new('git')
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.WorkingDirectory = $script:projectPath
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        if (-not $process.Start()) { throw 'Git did not start.' }
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            $process.Kill($true)
            throw 'Git metadata command timed out.'
        }
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($output, $errors), 5000)) {
            throw 'Git metadata output did not finish.'
        }
        if ($process.ExitCode -ne 0) { throw 'Git metadata is unavailable; a repository root is required.' }
        return $output.GetAwaiter().GetResult()
    } finally {
        $process.Dispose()
    }
}

function Get-CodeSnapshot {
    $gitRoot = (Invoke-GitText -Arguments @('rev-parse', '--show-toplevel')).Trim()
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not [IO.Path]::GetFullPath($gitRoot).Equals($script:projectPath, $comparison)) {
        throw 'ProjectRoot must be the Git repository root.'
    }
    $head = (Invoke-GitText -Arguments @('rev-parse', '--verify', 'HEAD')).Trim()
    $paths = (Invoke-GitText -Arguments @('ls-files', '--cached', '--others', '--exclude-standard', '-z')).Split([char]0)
    $paths = @($paths | Where-Object { $_ -and -not $_.StartsWith('.ai/', [StringComparison]::Ordinal) } |
        Sort-Object -Unique -CaseSensitive)
    $digest = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        $digest.AppendData([Text.Encoding]::UTF8.GetBytes($head + [char]0))
        foreach ($relative in $paths) {
            $path = Get-ContainedPath -RelativePath $relative
            $digest.AppendData([Text.Encoding]::UTF8.GetBytes($relative + [char]0))
            if (-not (Test-Path -LiteralPath $path)) {
                $digest.AppendData([Text.Encoding]::UTF8.GetBytes('deleted'))
                continue
            }
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw 'Submodule/directory entries need a separately configured gate; snapshot is blocked.'
            }
            $stream = [IO.File]::OpenRead($path)
            $hasher = [Security.Cryptography.SHA256]::Create()
            try { $digest.AppendData($hasher.ComputeHash($stream)) }
            finally { $stream.Dispose(); $hasher.Dispose() }
        }
        return [Convert]::ToHexString($digest.GetHashAndReset()).ToLowerInvariant()
    } finally {
        $digest.Dispose()
    }
}

function Invoke-RequiredCheck {
    param([System.Collections.IDictionary]$Check)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $result = [ordered]@{
        id = $Check.id
        category = $Check.category
        executable = $Check.executable
        arguments = @($Check.arguments)
        workingDirectory = $Check.workingDirectory
        timeoutSeconds = $Check.timeoutSeconds
        status = 'blocked'
        exitCode = $null
        durationSeconds = 0
        reason = ''
    }
    $process = [Diagnostics.Process]::new()
    try {
        $info = [Diagnostics.ProcessStartInfo]::new($Check.executable)
        $info.WorkingDirectory = Get-ContainedPath -RelativePath $Check.workingDirectory -Directory
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        foreach ($argument in $Check.arguments) { $info.ArgumentList.Add($argument) }
        $process.StartInfo = $info
        if (-not $process.Start()) { throw 'Check process did not start.' }
        # Drain without retaining raw scanner output or allocating unbounded log buffers.
        $output = $process.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null)
        $errors = $process.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
        if (-not $process.WaitForExit([int]$Check.timeoutSeconds * 1000)) {
            $process.Kill($true)
            $null = $process.WaitForExit(5000)
            $result.status = 'fail'
            $result.reason = 'timeout'
        } elseif (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($output, $errors), 5000)) {
            $result.reason = 'Check output streams did not close.'
        } else {
            $result.exitCode = $process.ExitCode
            $result.status = if ($process.ExitCode -eq 0) { 'pass' } else { 'fail' }
            $result.reason = if ($process.ExitCode -eq 0) { '' } else { 'nonzero exit code' }
        }
    } catch {
        $result.reason = 'Unable to execute required check; verify executable, arguments, and environment.'
    } finally {
        $process.Dispose()
        $timer.Stop()
        $result.durationSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 3)
    }
    return $result
}

try {
    $script:projectPath = [IO.Path]::TrimEndingDirectorySeparator((Resolve-Path -LiteralPath $ProjectRoot).Path)
    $policyPath = Get-ContainedPath -RelativePath 'loops/quality-gate.json'
    $reportPath = Get-ContainedPath -RelativePath '.ai/quality-gate-result.json'
    if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) { throw 'Missing loops/quality-gate.json.' }
    try { $policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json -AsHashtable }
    catch { throw 'Gate configuration is not valid JSON.' }
    if ($policy -isnot [System.Collections.IDictionary]) { throw 'Gate configuration must be an object.' }
    Assert-Keys -Object $policy -Keys @('version', 'checks')
    if ($policy.version -isnot [long] -or $policy.version -ne 1) { throw 'Gate configuration version must be integer 1.' }
    if ($policy.checks -isnot [array] -or $policy.checks.Count -eq 0) { throw 'At least one required check must be configured.' }
    $ids = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $categories = @('format', 'lint', 'types', 'tests', 'build', 'secrets', 'dependencies', 'static', 'integration', 'performance', 'docs', 'config')
    foreach ($check in $policy.checks) {
        if ($check -isnot [System.Collections.IDictionary]) { throw 'Each check must be an object.' }
        Assert-Keys -Object $check -Keys @('id', 'category', 'scopes', 'executable', 'arguments', 'workingDirectory', 'timeoutSeconds')
        if ($check.id -isnot [string] -or $check.id -cnotmatch '^[a-z][a-z0-9-]{0,63}$' -or -not $ids.Add($check.id)) {
            throw 'Check IDs must be unique lowercase names.'
        }
        if ($check.category -isnot [string] -or $categories -cnotcontains $check.category) { throw 'Invalid check category.' }
        if ($check.scopes -isnot [array] -or $check.scopes.Count -eq 0) { throw 'Each check needs at least one scope.' }
        foreach ($checkScope in $check.scopes) {
            if ($checkScope -isnot [string] -or @('change', 'repository') -cnotcontains $checkScope) { throw 'Invalid check scope.' }
        }
        if ($check.executable -isnot [string] -or [string]::IsNullOrWhiteSpace($check.executable) -or $check.executable.Contains([char]0)) {
            throw 'A check executable is required.'
        }
        if ($check.arguments -isnot [array]) { throw 'Check arguments must be a string array.' }
        foreach ($argument in $check.arguments) {
            if ($argument -isnot [string] -or $argument.Contains([char]0)) { throw 'Arguments must be strings without null characters.' }
        }
        if ($check.workingDirectory -isnot [string]) { throw 'Working directory must be a string.' }
        $null = Get-ContainedPath -RelativePath $check.workingDirectory -Directory
        if ($check.timeoutSeconds -isnot [long] -or $check.timeoutSeconds -lt 1 -or $check.timeoutSeconds -gt 3600) {
            throw 'Check timeoutSeconds must be an integer between 1 and 3600.'
        }
    }
    $selected = @($policy.checks | Where-Object { $_.scopes -ccontains $Scope })
    if ($selected.Count -eq 0) { throw 'No required checks are configured for the requested scope.' }
    $policyHash = (Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $snapshot = Get-CodeSnapshot

    if ($Verify) {
        if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw 'No gate evidence exists; run the gate first.' }
        try { $report = Get-Content -Raw -LiteralPath $reportPath | ConvertFrom-Json -AsHashtable }
        catch { throw 'Gate evidence is not valid JSON; rerun required checks.' }
        if ($report.version -ne 1 -or $report.project -ne $script:projectPath -or $report.scope -cne $Scope -or
            $report.snapshot -cne $snapshot -or $report.policyHash -cne $policyHash) {
            Write-Output 'Gate evidence is stale or belongs to another scope/project; rerun required checks.'
            exit 3
        }
        if ($report.status -cne 'pass') { Write-Output 'Recorded automated gate did not pass.'; exit 1 }
        if ($report.checks.Count -ne $selected.Count) { throw 'Recorded check evidence is incomplete.' }
        foreach ($check in $selected) {
            $evidence = @($report.checks | Where-Object { $_.id -ceq $check.id })
            if ($evidence.Count -ne 1 -or $evidence[0].status -cne 'pass' -or $evidence[0].exitCode -ne 0) {
                throw 'Recorded check evidence is incomplete or failed.'
            }
        }
        Write-Output "Automated gate evidence matches the current $Scope snapshot. Manual review is still required."
        exit 0
    }

    $startedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $results = @(
        foreach ($check in $selected) {
            $result = Invoke-RequiredCheck -Check $check
            Write-Output "$($result.id): $($result.status)" | Out-Host
            $result
        }
    )
    $status = if (@($results | Where-Object { $_.status -eq 'blocked' }).Count) { 'blocked' }
              elseif (@($results | Where-Object { $_.status -eq 'fail' }).Count) { 'fail' }
              else { 'pass' }
    $exitCode = if ($status -eq 'blocked') { 2 } elseif ($status -eq 'fail') { 1 } else { 0 }
    if ((Get-CodeSnapshot) -cne $snapshot -or (Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $policyHash) {
        $status = 'stale'
        $exitCode = 3
    }
    $report = [ordered]@{
        version = 1
        project = $script:projectPath
        scope = $Scope
        snapshot = $snapshot
        policyHash = $policyHash
        startedAt = $startedAt
        finishedAt = [DateTimeOffset]::UtcNow.ToString('o')
        status = $status
        checks = $results
    }
    $statePath = Get-ContainedPath -RelativePath '.ai'
    $null = New-Item -ItemType Directory -Force -Path $statePath
    $temporaryPath = Join-Path $statePath ([Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($temporaryPath, ($report | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temporaryPath, $reportPath, $true)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath }
    }
    Write-Output "Automated gate: $status. Evidence: .ai/quality-gate-result.json"
    exit $exitCode
} catch {
    # Configuration errors are safe to report; command output is never included.
    Write-Output ("Quality gate blocked: " + $_.Exception.Message)
    exit 2
}
