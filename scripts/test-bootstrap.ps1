# test-bootstrap.ps1 - Tests for bootstrap.ps1
# -----------------------------------------------------------------------
# Validates interactive flows, -All mode, and per-project type
# installations work correctly on Windows PowerShell 5.1+.
#
# Usage: .\scripts\test-bootstrap.ps1
# -----------------------------------------------------------------------
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Bootstrap = Join-Path $ScriptDir 'bootstrap.ps1'
$Pass      = 0
$Fail      = 0
$Errors    = @()

# -- Test helpers --
function New-TempDir {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    return $tmp
}

function Remove-TempDir {
    param([string]$Path)
    if ($Path -and (Test-Path $Path)) {
        Remove-Item -Recurse -Force -Path $Path -ErrorAction SilentlyContinue
    }
}

function Assert-Pass {
    param([string]$Label)
    $script:Pass++
    Write-Host "  v $Label" -ForegroundColor Green
}

function Assert-Fail {
    param([string]$Label, [string]$Reason)
    $script:Fail++
    $script:Errors += "${Label}: $Reason"
    Write-Host "  x $Label" -ForegroundColor Red
    Write-Host "    $Reason" -ForegroundColor Red
}

function Assert-Eq {
    param($Actual, $Expected, [string]$Label)
    if ($Actual -eq $Expected) { Assert-Pass $Label }
    else { Assert-Fail $Label "expected '$Expected', got '$Actual'" }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Label)
    if ($Haystack -like "*$Needle*") { Assert-Pass $Label }
    else { Assert-Fail $Label "expected to contain '$Needle'" }
}

function Assert-FileExists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path -PathType Leaf) { Assert-Pass $Label }
    else { Assert-Fail $Label "file not found: $Path" }
}

function Assert-DirExists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path -PathType Container) { Assert-Pass $Label }
    else { Assert-Fail $Label "directory not found: $Path" }
}

function Assert-FileNotExists {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) { Assert-Pass $Label }
    else { Assert-Fail $Label "file should not exist: $Path" }
}

function Invoke-Bootstrap {
    param([string]$WorkDir, [string]$InputText)
    $tmpInput = Join-Path ([System.IO.Path]::GetTempPath()) "bs-in-$([System.IO.Path]::GetRandomFileName()).txt"
    [System.IO.File]::WriteAllText($tmpInput, $InputText, [System.Text.Encoding]::UTF8)
    try {
        # Note: do NOT use -NonInteractive — it blocks Read-Host from reading stdin
        $output = Get-Content $tmpInput | & powershell.exe -File $Bootstrap $WorkDir 2>&1
        return @{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    } finally {
        Remove-Item -Force -Path $tmpInput -ErrorAction SilentlyContinue
    }
}

# ======================================================================
Write-Host "`nBootstrap.ps1 Tests`n" -ForegroundColor White
# ======================================================================

# -- Test 1: -All mode installs everything ----------------------------
Write-Host '** Test: -All mode **' -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'all-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

& powershell.exe -File $Bootstrap $dir -All 2>&1 | Out-Null
Assert-Eq $LASTEXITCODE 0 '-All exits cleanly'
Assert-DirExists  (Join-Path $dir '.github\agents')       '-All creates agents dir'
Assert-DirExists  (Join-Path $dir '.github\skills')       '-All creates skills dir'
Assert-DirExists  (Join-Path $dir '.github\prompts')      '-All creates prompts dir'
Assert-DirExists  (Join-Path $dir '.github\instructions') '-All creates instructions dir'
Assert-DirExists  (Join-Path $dir '.github\hooks')        '-All creates hooks dir'
Assert-DirExists  (Join-Path $dir '.github\references')   '-All creates references dir'
Assert-DirExists  (Join-Path $dir '.github\workflows')    '-All creates workflows dir'
Assert-FileExists (Join-Path $dir '.github\copilot-instructions.md') '-All creates copilot-instructions'
Assert-FileExists (Join-Path $dir 'CLAUDE.md')                       '-All creates CLAUDE.md'
Assert-FileExists (Join-Path $dir 'AGENTS.md')                       '-All creates AGENTS.md'
Assert-FileExists (Join-Path $dir '.github\PULL_REQUEST_TEMPLATE.md') '-All creates PR template'

$installedAgents = (Get-ChildItem -Path (Join-Path $dir '.github\agents') -Filter '*.agent.md' -ErrorAction SilentlyContinue).Count
$sourceAgents    = (Get-ChildItem -Path (Join-Path $ScriptDir '..\templates\agents') -Filter '*.agent.md').Count
Assert-Eq $installedAgents $sourceAgents "-All installs all $sourceAgents agents"

$installedWf = (Get-ChildItem -Path (Join-Path $dir '.github\workflows') -Filter '*.yml' -ErrorAction SilentlyContinue).Count
$sourceWf    = (Get-ChildItem -Path (Join-Path $ScriptDir '..\templates\workflows') -Filter '*.yml').Count
Assert-Eq $installedWf $sourceWf "-All installs all $sourceWf workflows"

Remove-TempDir $tmp

# -- Test 2: Interactive - Copilot + Next.js --------------------------
Write-Host "`n** Test: Interactive - Copilot + Next.js **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'nextjs-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 4 (Next.js), Enter (no extras), y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n4`n`ny`n" | Out-Null

Assert-DirExists  (Join-Path $dir '.github\agents')  'Copilot+Next.js creates agents dir'
Assert-DirExists  (Join-Path $dir '.github\skills')  'Copilot+Next.js creates skills dir'
Assert-DirExists  (Join-Path $dir '.github\prompts') 'Copilot+Next.js creates prompts dir'
Assert-FileExists (Join-Path $dir '.github\agents\bug-fixer.agent.md')        'core agent: bug-fixer'
Assert-FileExists (Join-Path $dir '.github\agents\test-writer.agent.md')      'core agent: test-writer'
Assert-FileExists (Join-Path $dir '.github\agents\nextjs-expert.agent.md')    'tech agent: nextjs-expert'
Assert-FileExists (Join-Path $dir '.github\agents\react-expert.agent.md')     'tech agent: react-expert'
Assert-FileExists (Join-Path $dir '.github\agents\typescript-expert.agent.md') 'tech agent: typescript-expert'
Assert-FileNotExists (Join-Path $dir '.github\agents\elixir-expert.agent.md') 'no elixir-expert for Next.js'
Assert-FileNotExists (Join-Path $dir '.github\agents\rails-expert.agent.md')  'no rails-expert for Next.js'
Assert-FileExists (Join-Path $dir '.github\copilot-instructions.md')           'copilot-instructions.md installed'
Assert-FileExists (Join-Path $dir '.github\instructions\typescript.instructions.md') 'typescript instruction'
Assert-FileExists (Join-Path $dir '.github\instructions\react.instructions.md')      'react instruction'
Assert-FileNotExists (Join-Path $dir '.github\workflows') 'no workflows without extras'

Remove-TempDir $tmp

# -- Test 3: Interactive - Claude + Elixir/Phoenix -------------------
Write-Host "`n** Test: Interactive - Claude + Elixir/Phoenix **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'elixir-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 2 (Claude), 1 (Elixir/Phoenix), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n2`n1`n`ny`n" | Out-Null

Assert-DirExists  (Join-Path $dir '.claude\agents')    'Claude uses .claude/ config dir'
Assert-FileExists (Join-Path $dir '.claude\agents\elixir-expert.agent.md')     'elixir-expert installed'
Assert-FileExists (Join-Path $dir '.claude\agents\phoenix-expert.agent.md')    'phoenix-expert installed'
Assert-FileExists (Join-Path $dir '.claude\agents\postgresql-expert.agent.md') 'postgresql auto-added for Elixir'
Assert-FileExists (Join-Path $dir 'CLAUDE.md')         'CLAUDE.md installed'
Assert-FileExists (Join-Path $dir '.claude\instructions\elixir.instructions.md') 'elixir instruction'
Assert-FileNotExists (Join-Path $dir '.github\copilot-instructions.md') 'no copilot-instructions for Claude'

Remove-TempDir $tmp

# -- Test 4: Interactive - Copilot + C# ASP.NET Core ----------------
Write-Host "`n** Test: Interactive - Copilot + C# ASP.NET Core **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'csharp-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 17 (C# ASP.NET Core), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n17`n`ny`n" | Out-Null

Assert-FileExists (Join-Path $dir '.github\agents\csharp-expert.agent.md')     'csharp-expert installed'
Assert-FileExists (Join-Path $dir '.github\agents\aspnetcore-expert.agent.md') 'aspnetcore-expert installed'
Assert-FileExists (Join-Path $dir '.github\agents\backend-expert.agent.md')    'backend-expert for C#'
Assert-FileExists (Join-Path $dir '.github\agents\postgresql-expert.agent.md') 'postgresql auto-added for C#'
Assert-FileExists (Join-Path $dir '.github\instructions\csharp.instructions.md') 'csharp instruction'
Assert-FileNotExists (Join-Path $dir '.github\agents\blazor-expert.agent.md')  'no blazor-expert for backend-only C#'

Remove-TempDir $tmp

# -- Test 5: Interactive - Copilot + Blazor --------------------------
Write-Host "`n** Test: Interactive - Copilot + Blazor **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'blazor-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 18 (Blazor), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n18`n`ny`n" | Out-Null

Assert-FileExists (Join-Path $dir '.github\agents\csharp-expert.agent.md')     'csharp-expert installed'
Assert-FileExists (Join-Path $dir '.github\agents\blazor-expert.agent.md')     'blazor-expert installed'
Assert-FileExists (Join-Path $dir '.github\agents\aspnetcore-expert.agent.md') 'aspnetcore-expert installed'
Assert-FileExists (Join-Path $dir '.github\instructions\csharp.instructions.md') 'csharp instruction'

Remove-TempDir $tmp

# -- Test 6: Interactive - Copilot + C# Full-stack -------------------
Write-Host "`n** Test: Interactive - Copilot + C# Full-stack **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'csharp-fullstack-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 19 (C# Full-stack), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n19`n`ny`n" | Out-Null

Assert-FileExists (Join-Path $dir '.github\agents\csharp-expert.agent.md')     'csharp-expert for fullstack'
Assert-FileExists (Join-Path $dir '.github\agents\aspnetcore-expert.agent.md') 'aspnetcore-expert for fullstack'
Assert-FileExists (Join-Path $dir '.github\agents\blazor-expert.agent.md')     'blazor-expert for fullstack'
Assert-FileExists (Join-Path $dir '.github\agents\docker-expert.agent.md')     'docker auto-added for C# fullstack'
Assert-FileExists (Join-Path $dir '.github\agents\postgresql-expert.agent.md') 'postgresql auto-added for C# fullstack'

Remove-TempDir $tmp

# -- Test 7: Extras - Docker -----------------------------------------
Write-Host "`n** Test: Docker extra **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'docker-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 21 (Generic), 1 (Docker), y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n21`n1`ny`n" | Out-Null

Assert-FileExists (Join-Path $dir '.github\agents\docker-expert.agent.md')    'docker-expert added via extras'
Assert-FileExists (Join-Path $dir '.github\instructions\docker.instructions.md') 'docker instruction added'

Remove-TempDir $tmp

# -- Test 8: Extras - workflows + templates --------------------------
Write-Host "`n** Test: Workflows + templates extras **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'extras-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 1 (Copilot), 21 (Generic), 7,8 (workflows+templates), y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n21`n7,8`ny`n" | Out-Null

Assert-DirExists  (Join-Path $dir '.github\workflows')          'workflows installed via extras'
Assert-DirExists  (Join-Path $dir '.github\ISSUE_TEMPLATE')     'issue templates via extras'
Assert-FileExists (Join-Path $dir '.github\PULL_REQUEST_TEMPLATE.md') 'PR template via extras'

$wfCount = (Get-ChildItem -Path (Join-Path $dir '.github\workflows') -Filter '*.yml' -ErrorAction SilentlyContinue).Count
if ($wfCount -gt 0) { Assert-Pass "workflows installed ($wfCount files)" }
else                { Assert-Fail 'workflows installed' 'no workflow files found' }

Remove-TempDir $tmp

# -- Test 9: Cursor editor config ------------------------------------
Write-Host "`n** Test: Cursor editor **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'cursor-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 3 (Cursor), 21 (Generic), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n3`n21`n`ny`n" | Out-Null

Assert-DirExists  (Join-Path $dir '.cursor\agents') 'Cursor uses .cursor/ config dir'
Assert-FileExists (Join-Path $dir '.cursorrules')   '.cursorrules installed for Cursor'

Remove-TempDir $tmp

# -- Test 10: Windsurf editor config ---------------------------------
Write-Host "`n** Test: Windsurf editor **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'windsurf-test'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 4 (Windsurf), 21 (Generic), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n4`n21`n`ny`n" | Out-Null

Assert-DirExists  (Join-Path $dir '.windsurf\agents') 'Windsurf uses .windsurf/ config dir'
Assert-FileExists (Join-Path $dir '.windsurfrules')   '.windsurfrules installed for Windsurf'

Remove-TempDir $tmp

# -- Test 11: All editors --------------------------------------------
Write-Host "`n** Test: All editors **" -ForegroundColor White
$tmp = New-TempDir
$dir = Join-Path $tmp 'all-editors'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Input: project-name, 5 (All), 21 (Generic), Enter, y
Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n5`n21`n`ny`n" | Out-Null

Assert-FileExists (Join-Path $dir '.github\copilot-instructions.md') 'copilot-instructions for All'
Assert-FileExists (Join-Path $dir 'CLAUDE.md')     'CLAUDE.md for All'
Assert-FileExists (Join-Path $dir '.cursorrules')  '.cursorrules for All'
Assert-FileExists (Join-Path $dir '.windsurfrules') '.windsurfrules for All'

Remove-TempDir $tmp

# -- Test 12: All project types run without error --------------------
Write-Host "`n** Test: All 22 project types run without error **" -ForegroundColor White
for ($i = 1; $i -le 22; $i++) {
    $tmp = New-TempDir
    $dir = Join-Path $tmp "proj-$i"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $result = Invoke-Bootstrap -WorkDir $dir -InputText "my-app`n1`n$i`n`ny`n"
    if ($result.ExitCode -eq 0) { Assert-Pass "project type $i" }
    else                        { Assert-Fail "project type $i" "exited with code $($result.ExitCode)" }
    Remove-TempDir $tmp
}

# -- Test 13: -Help --------------------------------------------------
Write-Host "`n** Test: -Help **" -ForegroundColor White
$helpOutput = & powershell.exe -File $Bootstrap -Help 2>&1 | Out-String
Assert-Contains $helpOutput 'Usage:'         '-Help shows Usage'
Assert-Contains $helpOutput 'Agents (52+)'   '-Help shows agent count'
Assert-Contains $helpOutput 'Workflows (27)' '-Help shows workflow count'

# -- Test 14: No arguments shows usage -------------------------------
Write-Host "`n** Test: No arguments **" -ForegroundColor White
$noArgsOutput = & powershell.exe -File $Bootstrap 2>&1 | Out-String
Assert-Contains $noArgsOutput 'Usage:' 'no args shows usage'

# -- Test 15: Rejects self as target ---------------------------------
Write-Host "`n** Test: Self-target rejection **" -ForegroundColor White
$selfPath     = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$selfOutput   = & powershell.exe -File $Bootstrap $selfPath 2>&1 | Out-String
Assert-Contains $selfOutput 'Target cannot be the dx-toolkit itself' 'rejects self as target'

# ======================================================================
# Summary
# ======================================================================

Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host "  Passed: $Pass" -ForegroundColor Green
if ($Fail -gt 0) {
    Write-Host "  Failed: $Fail" -ForegroundColor Red
    Write-Host ''
    foreach ($err in $Errors) {
        Write-Host "  x $err" -ForegroundColor Red
    }
}
Write-Host '==========================================' -ForegroundColor Cyan

exit $Fail
