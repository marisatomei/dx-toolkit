# bootstrap.ps1 - Smart installer for dx-toolkit (Windows / PowerShell)
# -----------------------------------------------------------------------
# Detects your editor, project type, and installs only the
# agents, skills, instructions, and prompts that apply.
#
# Usage:
#   .\scripts\bootstrap.ps1 C:\Code\my-project          # interactive
#   .\scripts\bootstrap.ps1 C:\Code\my-project -All     # install everything
#   .\scripts\bootstrap.ps1 -Help                       # show help
# -----------------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    [switch]$All,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -- Resolve paths --
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Split-Path -Parent $ScriptDir

# -- Color helpers --
function Write-Info    { param([string]$Msg) Write-Host "i  $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "v  $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "!  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "x  $Msg" -ForegroundColor Red }
function Write-Header  { param([string]$Msg) Write-Host "`n-- $Msg --" -ForegroundColor Cyan }

# -- Interactive prompt helpers --
function Ask-YN {
    param([string]$Prompt, [string]$Default = 'y')
    $hint = if ($Default -eq 'y') { '[Y/n]' } else { '[y/N]' }
    $yn = Read-Host "$Prompt $hint"
    if ([string]::IsNullOrWhiteSpace($yn)) { $yn = $Default }
    return $yn -match '^[Yy]'
}

function Ask-Text {
    param([string]$Prompt, [string]$Default)
    $val = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($val)) { return $Default }
    return $val
}

function Ask-Choice {
    param([string]$Prompt, [string[]]$Options)
    Write-Host "`n$Prompt" -ForegroundColor White
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "  $($i + 1)) $($Options[$i])" -ForegroundColor Cyan
    }
    while ($true) {
        $raw = Read-Host "Pick a number [1-$($Options.Length)]"
        if ($raw -match '^\d+$') {
            $n = [int]$raw
            if ($n -ge 1 -and $n -le $Options.Length) { return $n - 1 }
        }
        Write-Warn "Enter a number between 1 and $($Options.Length)"
    }
}

function Ask-Multi {
    param([string]$Prompt, [string[]]$Options)
    Write-Host "`n$Prompt (comma-separated, e.g. 1,3,5 - or press Enter to skip)" -ForegroundColor White
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "  $($i + 1)) $($Options[$i])" -ForegroundColor Cyan
    }
    $raw = Read-Host 'Your choices'
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $result = @()
    foreach ($part in ($raw -split ',')) {
        $part = $part.Trim()
        if ($part -match '^\d+$') {
            $n = [int]$part
            if ($n -ge 1 -and $n -le $Options.Length) { $result += ($n - 1) }
        }
    }
    return $result
}

# -- File copy helpers --
function Copy-DirRecurse {
    param([string]$Src, [string]$Dest, [string]$Label)
    if (-not (Test-Path $Src)) { Write-Warn "Not found: $Src"; return }
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    Copy-Item -Path "$Src\*" -Destination $Dest -Recurse -Force
    $count = (Get-ChildItem -Path $Src -Recurse -File).Count
    Write-Success "$Label ($count files)"
}

function Copy-OneFile {
    param([string]$Src, [string]$Dest, [string]$Label = '')
    if (-not (Test-Path $Src)) { return $false }
    $dir = Split-Path -Parent $Dest
    if (-not [string]::IsNullOrEmpty($dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Copy-Item -Path $Src -Destination $Dest -Force
    if ($Label) { Write-Success $Label }
    return $true
}

function Copy-Template {
    param(
        [string]$Src,
        [string]$Dest,
        [string]$Label = '',
        [string]$ProjectName,
        [string]$ConfigDir
    )
    if (-not (Test-Path $Src)) { return $false }
    $dir = Split-Path -Parent $Dest
    if (-not [string]::IsNullOrEmpty($dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $content = Get-Content -Path $Src -Raw -Encoding UTF8
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $content = $content -replace '\{\{CONFIG_DIR\}\}',   $ConfigDir
    [System.IO.File]::WriteAllText($Dest, $content, [System.Text.Encoding]::UTF8)
    if ($Label) { Write-Success $Label }
    return $true
}

function Copy-Agent {
    param([string]$Name)
    $src  = Join-Path $SourceDir "templates\agents\$Name.agent.md"
    $dest = Join-Path $Target "$ConfigDir\agents\$Name.agent.md"
    Copy-OneFile -Src $src -Dest $dest | Out-Null
}

function Copy-Instruction {
    param([string]$Name)
    $src  = Join-Path $SourceDir "templates\instructions\$Name.instructions.md"
    $dest = Join-Path $Target "$ConfigDir\instructions\$Name.instructions.md"
    Copy-OneFile -Src $src -Dest $dest | Out-Null
}

function Get-Unique-Sorted {
    param([string[]]$Items)
    return @($Items | Sort-Object -Unique)
}

# -- Help --
if ($Help) {
    Write-Host @'
Usage: bootstrap.ps1 <target-directory> [-All] [-Help]

Interactive mode asks about your editor, project type, and tech stack
to install only the relevant components.

Options:
  -All    Install everything without prompting
  -Help   Show this help

Components:
  Agents (52+)       Specialized AI coding agents
  Skills (48+)       Multi-step structured workflows
  Prompts (27+)      One-shot task templates
  Instructions (26+) Auto-attached coding rules
  Hooks (10)         Commit validation, secret scanning, auto-format, guard files
  References (10)    Testing, security, performance, accessibility, mobile, API, error handling, observability, monorepo, architecture checklists
  Templates (3)      Issue forms + PR template
  Workflows (27)     CI/CD GitHub Actions
'@
    exit 0
}

# -- Validate target --
if ([string]::IsNullOrWhiteSpace($Target)) {
    Write-Host 'Usage: bootstrap.ps1 <target-directory> [-All]'
    Write-Host ''
    Write-Host 'Example: .\scripts\bootstrap.ps1 C:\Code\my-project'
    exit 1
}

# Resolve tilde
if ($Target.StartsWith('~')) {
    $Target = $Target -replace '^~', $HOME
}

# Normalize path
if (Test-Path $Target) {
    $Target = (Resolve-Path $Target).Path
}

# Reject self as target
$NormalizedSource = (Resolve-Path $SourceDir).Path
if ($Target -eq $NormalizedSource) {
    Write-Err 'Target cannot be the dx-toolkit itself'
    exit 1
}

# Create target if missing
if (-not (Test-Path $Target)) {
    if (Ask-YN "Directory $Target does not exist. Create it?") {
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
    } else {
        exit 1
    }
}

# -----------------------------------------------------------------------
# -All mode: install everything and exit
# -----------------------------------------------------------------------

if ($All) {
    Write-Host ''
    Write-Host 'DX Toolkit -- Installing Everything' -ForegroundColor Cyan
    Write-Host "Target: $Target" -ForegroundColor Blue
    Write-Host ''

    $ConfigDir   = '.github'
    $ProjectName = Split-Path -Leaf $Target

    Write-Header 'Agents'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\agents')       (Join-Path $Target "$ConfigDir\agents")       'All agents'

    Write-Header 'Skills'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\skills')       (Join-Path $Target "$ConfigDir\skills")       'All skills'

    Write-Header 'Prompts'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\prompts')      (Join-Path $Target "$ConfigDir\prompts")      'All prompts'

    Write-Header 'Instructions'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\instructions') (Join-Path $Target "$ConfigDir\instructions") 'All instructions'
    Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') `
                  (Join-Path $Target "$ConfigDir\copilot-instructions.md") `
                  'copilot-instructions.md' -ProjectName $ProjectName -ConfigDir $ConfigDir

    Write-Header 'Hooks'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\hooks') (Join-Path $Target "$ConfigDir\hooks") 'Hooks'

    Write-Header 'References'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\references') (Join-Path $Target "$ConfigDir\references") 'Reference checklists'

    Write-Header 'Templates'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\ISSUE_TEMPLATE') (Join-Path $Target '.github\ISSUE_TEMPLATE') 'Issue templates'
    Copy-OneFile (Join-Path $SourceDir 'templates\PULL_REQUEST_TEMPLATE.md') `
                 (Join-Path $Target '.github\PULL_REQUEST_TEMPLATE.md') 'PR template'

    Write-Header 'Workflows'
    $wfDest = Join-Path $Target '.github\workflows'
    New-Item -ItemType Directory -Force -Path $wfDest | Out-Null
    Get-ChildItem -Path (Join-Path $SourceDir 'templates\workflows') -Filter '*.yml' | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $wfDest $_.Name) -Force
    }
    Write-Success 'Workflows'

    Write-Header 'Entry Points'
    Copy-Template (Join-Path $SourceDir 'templates\CLAUDE.md') (Join-Path $Target 'CLAUDE.md') 'CLAUDE.md' -ProjectName $ProjectName -ConfigDir $ConfigDir
    Copy-Template (Join-Path $SourceDir 'templates\AGENTS.md') (Join-Path $Target 'AGENTS.md') 'AGENTS.md' -ProjectName $ProjectName -ConfigDir $ConfigDir

    Write-Host ''
    Write-Host "Done! All components installed to $Target" -ForegroundColor Green
    Write-Host ''
    Write-Warn 'Review and customize these files with your project details:'
    Write-Host "  * $Target\$ConfigDir\copilot-instructions.md  -- replace TODO sections" -ForegroundColor DarkGray
    Write-Host "  * $Target\CLAUDE.md                           -- add project description" -ForegroundColor DarkGray
    Write-Host "  * $Target\AGENTS.md                           -- verify agent list"       -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

# -----------------------------------------------------------------------
# Interactive mode -- smart setup
# -----------------------------------------------------------------------

Write-Host ''
Write-Host 'DX Toolkit -- Smart Setup' -ForegroundColor Cyan
Write-Host 'A few questions to install only what your project needs.' -ForegroundColor DarkGray

# --- Step 0: Project Name ---
Write-Host ''
$DefaultProjectName = Split-Path -Leaf $Target
$ProjectName = Ask-Text -Prompt "What's your project name?" -Default $DefaultProjectName

# --- Binary Detection ---
$CopilotCliDetected = $false
if (Get-Command copilot -ErrorAction SilentlyContinue) {
    $CopilotCliDetected = $true
    Write-Info 'GitHub Copilot CLI detected — project and personal skill install will be offered'
}

# --- Step 1: Editor / AI Tool ---
$EditorChoices = @(
    'GitHub Copilot (VS Code)'
    'GitHub Copilot CLI (terminal)'
    'Claude Code (terminal)'
    'Cursor'
    'Windsurf'
    'Multiple / All of them'
)
$EditorIdx = Ask-Choice -Prompt 'Which AI coding tool do you use?' -Options $EditorChoices

$InstallCopilot    = $false
$InstallCopilotCli = $false
$InstallClaude     = $false
$InstallCursor     = $false
$InstallWindsurf   = $false

switch ($EditorIdx) {
    0 { $InstallCopilot    = $true }
    1 { $InstallCopilotCli = $true }
    2 { $InstallClaude     = $true }
    3 { $InstallCursor     = $true }
    4 { $InstallWindsurf   = $true }
    5 { $InstallCopilot = $true; $InstallCopilotCli = $true; $InstallClaude = $true; $InstallCursor = $true; $InstallWindsurf = $true }
}

$ConfigDir = '.github'
switch ($EditorIdx) {
    1 { $ConfigDir = '.copilot'  }
    2 { $ConfigDir = '.claude'   }
    3 { $ConfigDir = '.cursor'   }
    4 { $ConfigDir = '.windsurf' }
}

# --- Step 2: Project Type ---
$ProjectChoices = @(
    'Elixir / Phoenix'
    'Ruby on Rails'
    'TypeScript / Node.js (backend)'
    'Next.js (fullstack)'
    'React (frontend SPA)'
    'React Native / Expo'
    'Python (Django / FastAPI / Flask)'
    'WordPress'
    'Go'
    'Rust'
    'Swift / iOS'
    'Kotlin / Android'
    'Flutter'
    'Vue / Nuxt'
    'Angular'
    'Svelte / SvelteKit'
    'C# / ASP.NET Core (backend API)'
    'Blazor (frontend / fullstack)'
    'C# Full-stack (ASP.NET Core + Blazor)'
    'Full-stack (multiple technologies)'
    'Other / Generic'
    'NVIDIA DeepStream (video analytics)'
)
$ProjectIdx = Ask-Choice -Prompt 'What type of project are you building?' -Options $ProjectChoices

# --- Step 3: Extras ---
$ExtraChoices = @(
    'Docker / Containers'
    'PostgreSQL'
    'Supabase'
    'GraphQL'
    'Terraform / IaC'
    'Observability'
    'CI/CD Workflows (GitHub Actions)'
    'GitHub Templates (issues, PRs)'
    'Editor Tooling (Prettier, EditorConfig)'
)
$ExtraPicks = Ask-Multi -Prompt 'Any extras?' -Options $ExtraChoices

$InstallDocker        = $false
$InstallPostgres      = $false
$InstallSupabase      = $false
$InstallGraphQL       = $false
$InstallTerraform     = $false
$InstallObservability = $false
$InstallWorkflows     = $false
$InstallTemplates     = $false
$InstallTooling       = $false

foreach ($pick in $ExtraPicks) {
    switch ($pick) {
        0 { $InstallDocker        = $true }
        1 { $InstallPostgres      = $true }
        2 { $InstallSupabase      = $true }
        3 { $InstallGraphQL       = $true }
        4 { $InstallTerraform     = $true }
        5 { $InstallObservability = $true }
        6 { $InstallWorkflows     = $true }
        7 { $InstallTemplates     = $true }
        8 { $InstallTooling       = $true }
    }
}

# -----------------------------------------------------------------------
# Build installation plan based on choices
# -----------------------------------------------------------------------

$AgentsCore = @(
    'bug-fixer', 'feature-implementer', 'refactorer', 'test-writer',
    'docs-updater', 'docs-humanizer', 'security-fixer',
    'performance-optimizer', 'dependency-updater'
)

$AgentsTech = @()
$InstrCore  = @('writing-style', 'git-workflow', 'accessibility', 'api-design', 'testing', 'migrations')
$InstrTech  = @()

switch ($ProjectIdx) {
    0  { # Elixir / Phoenix
        $AgentsTech += @('elixir-expert', 'phoenix-expert', 'backend-expert', 'tdd-expert', 'bdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('elixir')
        $InstallPostgres = $true
    }
    1  { # Ruby on Rails
        $AgentsTech += @('rails-expert', 'backend-expert', 'frontend-expert', 'web-development-expert', 'tdd-expert', 'bdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('ruby')
        $InstallPostgres = $true
    }
    2  { # TypeScript / Node.js
        $AgentsTech += @('typescript-expert', 'backend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript')
    }
    3  { # Next.js
        $AgentsTech += @('nextjs-expert', 'react-expert', 'typescript-expert', 'frontend-expert', 'backend-expert', 'web-development-expert', 'design-systems-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'react', 'css')
    }
    4  { # React SPA
        $AgentsTech += @('react-expert', 'typescript-expert', 'frontend-expert', 'design-systems-expert', 'web-development-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'react', 'css')
    }
    5  { # React Native / Expo
        $AgentsTech += @('react-native-expert', 'expo-expert', 'react-expert', 'typescript-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'react')
    }
    6  { # Python
        $AgentsTech += @('python-expert', 'backend-expert', 'web-development-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('python')
    }
    7  { # WordPress
        $AgentsTech += @('wordpress-expert', 'frontend-expert', 'web-development-expert', 'conventional-commits-expert')
        $InstrTech  += @('css')
    }
    8  { # Go
        $AgentsTech += @('go-expert', 'backend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('go')
    }
    9  { # Rust
        $AgentsTech += @('rust-expert', 'backend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('rust')
    }
    10 { # Swift / iOS
        $AgentsTech += @('swift-expert', 'conventional-commits-expert')
        $InstrTech  += @('swift')
    }
    11 { # Kotlin / Android
        $AgentsTech += @('kotlin-expert', 'conventional-commits-expert')
        $InstrTech  += @('kotlin')
    }
    12 { # Flutter
        $AgentsTech += @('flutter-expert', 'conventional-commits-expert')
    }
    13 { # Vue / Nuxt
        $AgentsTech += @('vue-expert', 'typescript-expert', 'frontend-expert', 'web-development-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'vue', 'css')
    }
    14 { # Angular
        $AgentsTech += @('angular-expert', 'typescript-expert', 'frontend-expert', 'web-development-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'css')
    }
    15 { # Svelte / SvelteKit
        $AgentsTech += @('svelte-expert', 'typescript-expert', 'frontend-expert', 'web-development-expert', 'conventional-commits-expert')
        $InstrTech  += @('typescript', 'css')
    }
    16 { # C# / ASP.NET Core
        $AgentsTech += @('csharp-expert', 'aspnetcore-expert', 'backend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('csharp')
        $InstallPostgres = $true
    }
    17 { # Blazor
        $AgentsTech += @('csharp-expert', 'blazor-expert', 'aspnetcore-expert', 'frontend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('csharp')
    }
    18 { # C# Full-stack
        $AgentsTech += @('csharp-expert', 'aspnetcore-expert', 'blazor-expert', 'backend-expert', 'frontend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('csharp')
        $InstallDocker   = $true
        $InstallPostgres = $true
    }
    19 { # Full-stack
        $AgentsTech += @('typescript-expert', 'react-expert', 'nextjs-expert', 'frontend-expert', 'backend-expert', 'web-development-expert', 'design-systems-expert', 'conventional-commits-expert', 'tdd-expert')
        $InstrTech  += @('typescript', 'react', 'css')
        $InstallDocker = $true
    }
    20 { # Generic
        $AgentsTech += @('backend-expert', 'frontend-expert', 'web-development-expert', 'conventional-commits-expert')
    }
    21 { # NVIDIA DeepStream
        $AgentsTech += @('deepstream-expert', 'deepstream-plugin-expert', 'deepstream-inference-expert', 'tao-toolkit-expert', 'backend-expert', 'tdd-expert', 'conventional-commits-expert')
        $InstrTech  += @('deepstream')
        $InstallDocker = $true
    }
}

# Add extras
if ($InstallDocker)    { $AgentsTech += 'docker-expert';                          $InstrTech += 'docker' }
if ($InstallPostgres)  { $AgentsTech += 'postgresql-expert' }
if ($InstallSupabase)  { $AgentsTech += @('supabase-expert', 'postgresql-expert') }
if ($InstallGraphQL)   { $AgentsTech += 'graphql-expert';                         $InstrTech += 'graphql' }
if ($InstallTerraform) { $AgentsTech += 'terraform-expert' }

# Deduplicate
if ($AgentsTech.Count -gt 0) { $AgentsTech = @(Get-Unique-Sorted $AgentsTech) }
if ($InstrTech.Count  -gt 0) { $InstrTech  = @(Get-Unique-Sorted $InstrTech)  }

# -----------------------------------------------------------------------
# Show plan
# -----------------------------------------------------------------------

Write-Header 'Installation Plan'
Write-Host ''
Write-Host "  Target:       $Target"
Write-Host "  Editor:       $($EditorChoices[$EditorIdx])"
Write-Host "  Config dir:   $ConfigDir/"
Write-Host "  Project:      $($ProjectChoices[$ProjectIdx])"
Write-Host "  Agents:       $($AgentsCore.Count) core + $($AgentsTech.Count) specialized"
Write-Host "  Instructions: $($InstrCore.Count) universal + $($InstrTech.Count) tech-specific"
Write-Host '  Skills:       48+ (language-agnostic)'
Write-Host '  Prompts:      27+ (language-agnostic)'

$extrasSummary = @()
if ($InstallWorkflows)     { $extrasSummary += 'workflows' }
if ($InstallTemplates)     { $extrasSummary += 'templates' }
if ($InstallTooling)       { $extrasSummary += 'tooling' }
if ($InstallDocker)        { $extrasSummary += 'docker' }
if ($InstallPostgres)      { $extrasSummary += 'postgresql' }
if ($InstallSupabase)      { $extrasSummary += 'supabase' }
if ($InstallGraphQL)       { $extrasSummary += 'graphql' }
if ($InstallTerraform)     { $extrasSummary += 'terraform' }
if ($InstallObservability) { $extrasSummary += 'observability' }
if ($extrasSummary.Count -gt 0) {
    Write-Host "  Extras:       $($extrasSummary -join ', ')"
}
Write-Host ''

if (-not (Ask-YN 'Proceed?')) {
    Write-Info 'Cancelled.'
    exit 0
}

# -----------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------

$Total = 0

# -- Agents --
Write-Header 'Agents'
New-Item -ItemType Directory -Force -Path (Join-Path $Target "$ConfigDir\agents") | Out-Null

foreach ($agent in $AgentsCore) { Copy-Agent $agent; $Total++ }
foreach ($agent in $AgentsTech) { Copy-Agent $agent; $Total++ }
Write-Success "Installed $($AgentsCore.Count) core + $($AgentsTech.Count) specialized agents"

# -- Skills --
Write-Header 'Skills'
Copy-DirRecurse (Join-Path $SourceDir 'templates\skills') (Join-Path $Target "$ConfigDir\skills") 'All skills'
$Total += 34

# -- Prompts --
Write-Header 'Prompts'
Copy-DirRecurse (Join-Path $SourceDir 'templates\prompts') (Join-Path $Target "$ConfigDir\prompts") 'All prompts'
$Total += 27

# -- Instructions --
Write-Header 'Instructions'
New-Item -ItemType Directory -Force -Path (Join-Path $Target "$ConfigDir\instructions") | Out-Null

foreach ($inst in $InstrCore) { Copy-Instruction $inst; $Total++ }
foreach ($inst in $InstrTech) { Copy-Instruction $inst; $Total++ }
Write-Success "Installed $($InstrCore.Count) universal + $($InstrTech.Count) tech-specific instructions"

# -- Hooks --
Write-Header 'Hooks'
Copy-DirRecurse (Join-Path $SourceDir 'templates\hooks') (Join-Path $Target "$ConfigDir\hooks") 'Hooks'
$Total += 4

# -- References --
Write-Header 'References'
Copy-DirRecurse (Join-Path $SourceDir 'templates\references') (Join-Path $Target "$ConfigDir\references") 'Reference checklists'
$Total += 8

# -- Editor-specific files --
Write-Header 'Editor Setup'

if ($InstallCopilot) {
    Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') `
                  (Join-Path $Target '.github\copilot-instructions.md') `
                  'copilot-instructions.md' -ProjectName $ProjectName -ConfigDir $ConfigDir
    $Total++
}
if ($InstallCopilotCli) {
    Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') `
                  (Join-Path $Target '.copilot\copilot-instructions.md') `
                  'copilot-instructions.md (.copilot/)' -ProjectName $ProjectName -ConfigDir $ConfigDir
    $Total++
}
if ($InstallClaude) {
    Copy-Template (Join-Path $SourceDir 'templates\CLAUDE.md') (Join-Path $Target 'CLAUDE.md') 'CLAUDE.md' -ProjectName $ProjectName -ConfigDir $ConfigDir
    $Total++
}
if ($InstallCursor) {
    Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') (Join-Path $Target '.cursorrules') '.cursorrules' -ProjectName $ProjectName -ConfigDir $ConfigDir
    $Total++
}
if ($InstallWindsurf) {
    Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') (Join-Path $Target '.windsurfrules') '.windsurfrules' -ProjectName $ProjectName -ConfigDir $ConfigDir
    $Total++
}

Copy-Template (Join-Path $SourceDir 'templates\AGENTS.md') (Join-Path $Target 'AGENTS.md') 'AGENTS.md' -ProjectName $ProjectName -ConfigDir $ConfigDir
$Total++

# -- Templates --
if ($InstallTemplates) {
    Write-Header 'Templates'
    Copy-DirRecurse (Join-Path $SourceDir 'templates\ISSUE_TEMPLATE') (Join-Path $Target '.github\ISSUE_TEMPLATE') 'Issue templates'
    Copy-OneFile (Join-Path $SourceDir 'templates\PULL_REQUEST_TEMPLATE.md') `
                 (Join-Path $Target '.github\PULL_REQUEST_TEMPLATE.md') 'PR template'
    $Total += 4
}

# -- Workflows --
if ($InstallWorkflows) {
    Write-Header 'Workflows'
    $wfDest = Join-Path $Target '.github\workflows'
    New-Item -ItemType Directory -Force -Path $wfDest | Out-Null
    $wfCount = 0
    Get-ChildItem -Path (Join-Path $SourceDir 'templates\workflows') -Filter '*.yml' | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $wfDest $_.Name) -Force
        $wfCount++
    }
    Write-Success "Workflows ($wfCount)"
    $Total += $wfCount
}

# -- Tooling --
if ($InstallTooling) {
    Write-Header 'Editor Tooling'
    foreach ($f in @('.editorconfig', '.prettierrc', '.prettierignore', '.gitattributes')) {
        $src = Join-Path $SourceDir $f
        if (Copy-OneFile $src (Join-Path $Target $f) $f) { $Total++ }
    }
}

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------

Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host "  Done! ~$Total files installed." -ForegroundColor Green
Write-Host "  $Target"                        -ForegroundColor Blue
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ''
Write-Info 'Next steps:'
Write-Host "  1. cd $Target"
Write-Host "  2. Review installed files in $ConfigDir\"
if ($InstallCopilot)    { Write-Host '  3. Open in VS Code -- agents and prompts are ready via Copilot Chat' }
if ($InstallCopilotCli) {
    Write-Host "  3. Run 'copilot' in your project -- skills are in $ConfigDir\skills\"
    if ($CopilotCliDetected) {
        $yn = Read-Host '  Also install skills as personal (global) skills to ~/.copilot/skills/? [Y/n]'
        if ([string]::IsNullOrWhiteSpace($yn) -or $yn -match '^[Yy]') {
            $personalSkillsDir = Join-Path $HOME '.copilot\skills'
            New-Item -ItemType Directory -Force -Path $personalSkillsDir | Out-Null
            Copy-Item -Path (Join-Path $Target "$ConfigDir\skills\*") -Destination $personalSkillsDir -Recurse -Force
            Copy-Template (Join-Path $SourceDir 'templates\copilot-instructions.md') `
                          (Join-Path $HOME '.copilot\copilot-instructions.md') `
                          '~/.copilot/copilot-instructions.md (global)' -ProjectName $ProjectName -ConfigDir $ConfigDir
            Write-Success 'Personal skills installed to ~/.copilot/skills/'
        }
    }
}
if ($InstallClaude)   { Write-Host "  3. Run 'claude' -- CLAUDE.md provides context automatically" }
if ($InstallCursor)   { Write-Host '  3. Open in Cursor -- .cursorrules is configured' }
if ($InstallWindsurf) { Write-Host '  3. Open in Windsurf -- .windsurfrules is configured' }
Write-Host ''
Write-Warn 'Customize these files with your project details (look for TODO comments):'
if ($InstallCopilot)    { Write-Host "  * $ConfigDir\copilot-instructions.md" -ForegroundColor DarkGray }
if ($InstallCopilotCli) { Write-Host "  * $ConfigDir\copilot-instructions.md" -ForegroundColor DarkGray }
if ($InstallClaude)   { Write-Host '  * CLAUDE.md'                           -ForegroundColor DarkGray }
if ($InstallCursor)   { Write-Host '  * .cursorrules'                        -ForegroundColor DarkGray }
if ($InstallWindsurf) { Write-Host '  * .windsurfrules'                      -ForegroundColor DarkGray }
Write-Host '  * AGENTS.md'                                                   -ForegroundColor DarkGray
Write-Host ''
Write-Host "  git add . && git commit -m 'feat: add dx-toolkit for AI-assisted development'" -ForegroundColor DarkGray
Write-Host ''
