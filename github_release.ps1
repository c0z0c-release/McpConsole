# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 c0z0c <c0z0c@hotmail.com>

<#
.SYNOPSIS
McpConsole GitHub Release를 생성하고 실행 파일을 업로드합니다.

.DESCRIPTION
release 폴더의 버전별 실행 파일을 찾아 GitHub CLI로 릴리스를 생성합니다.
기본 동작은 실제 배포이며 --dry-run을 지정하면 배포 계획만 출력합니다.

.PARAMETER Version
배포할 버전입니다. 생략하면 release 폴더에서 가장 높은 버전을 사용합니다.

.PARAMETER Repo
GitHub 저장소의 owner/name입니다.

.PARAMETER DryRun
GitHub CLI를 호출하지 않고 릴리스 정보를 미리 출력합니다.

.PARAMETER Draft
릴리스를 초안으로 생성합니다.

.PARAMETER Prerelease
릴리스를 시험판으로 표시합니다.

.EXAMPLE
./github_release.ps1

.EXAMPLE
./github_release.ps1 --dry-run
#>
[CmdletBinding()]
param(
    [string] $Version,
    [string] $Repo = 'c0z0c-release/McpConsole',
    [switch] $DryRun,
    [switch] $Draft,
    [switch] $Prerelease,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ExtraArgs
)

# Windows PowerShell 5.1에서 UTF-8 원본과 한글 출력을 유지합니다.
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

for ($index = 0; $index -lt $ExtraArgs.Count; $index++) {
    switch -Exact ($ExtraArgs[$index]) {
        '--dry-run' { $DryRun = $true }
        '--draft' { $Draft = $true }
        '--prerelease' { $Prerelease = $true }
        '--version' {
            $index++
            if ($index -ge $ExtraArgs.Count) { throw '--version 뒤에 버전을 지정해야 합니다.' }
            $Version = $ExtraArgs[$index]
        }
        '--repo' {
            $index++
            if ($index -ge $ExtraArgs.Count) { throw '--repo 뒤에 저장소를 지정해야 합니다.' }
            $Repo = $ExtraArgs[$index]
        }
        default { throw "알 수 없는 옵션입니다: $($ExtraArgs[$index])" }
    }
}

function Get-VersionParts {
    <# 버전 문자열을 정렬 가능한 숫자 배열로 변환합니다. #>
    param([Parameter(Mandatory)][string] $Value)

    return @([regex]::Matches($Value, '\d+') | ForEach-Object { [int]$_.Value })
}

function Compare-Version {
    <# 두 버전의 숫자 구성 요소를 순서대로 비교합니다. #>
    param([Parameter(Mandatory)][string] $Left, [Parameter(Mandatory)][string] $Right)

    $leftParts = Get-VersionParts $Left
    $rightParts = Get-VersionParts $Right
    for ($index = 0; $index -lt [Math]::Max($leftParts.Count, $rightParts.Count); $index++) {
        $leftPart = if ($index -lt $leftParts.Count) { $leftParts[$index] } else { 0 }
        $rightPart = if ($index -lt $rightParts.Count) { $rightParts[$index] } else { 0 }
        if ($leftPart -lt $rightPart) { return -1 }
        if ($leftPart -gt $rightPart) { return 1 }
    }
    return 0
}

function Get-LatestVersion {
    <# release 아래 버전 폴더 중 가장 높은 버전을 반환합니다. #>
    param([Parameter(Mandatory)][string] $ArtifactRoot)

    $directories = @(Get-ChildItem -LiteralPath $ArtifactRoot -Directory | Where-Object { $_.Name -match '^\d+(\.\d+)*$' })
    if ($directories.Count -eq 0) {
        throw "버전 폴더를 찾을 수 없습니다: $ArtifactRoot"
    }

    $latest = $directories[0].Name
    foreach ($directory in $directories | Select-Object -Skip 1) {
        if ((Compare-Version $directory.Name $latest) -gt 0) { $latest = $directory.Name }
    }
    return $latest
}

function Get-ReleaseNotes {
    <# README에서 버전 변경 내역을 찾아 GitHub 릴리스 노트를 만듭니다. #>
    param([Parameter(Mandatory)][string] $ReadmePath, [Parameter(Mandatory)][string] $ReleaseVersion)

    if (-not (Test-Path -LiteralPath $ReadmePath -PathType Leaf)) {
        return "### McpConsole v$ReleaseVersion`n`nMcpConsole v$ReleaseVersion release build."
    }

    $content = Get-Content -LiteralPath $ReadmePath -Raw -Encoding UTF8
    $escapedVersion = [regex]::Escape($ReleaseVersion)
    $pattern = "(?ms)^#{2,3}\s+v?$escapedVersion(?:\s+[^\r\n]*)?\s*\r?\n(.*?)(?=^#{2,3}\s+|\z)"
    $match = [regex]::Match($content, $pattern)
    if ($match.Success -and -not [string]::IsNullOrWhiteSpace($match.Groups[1].Value)) {
        return "### What's Changed`n`n$($match.Groups[1].Value.Trim())"
    }

    return "### Release v$ReleaseVersion`n`nMcpConsole v$ReleaseVersion release build."
}

$releaseRoot = $PSScriptRoot
$artifactRoot = Join-Path $releaseRoot 'release'
if (-not $Version) { $Version = Get-LatestVersion -ArtifactRoot $artifactRoot }
$rawVersion = $Version -replace '^v', ''
if ($rawVersion -notmatch '^\d+(\.\d+)*$') { throw "올바르지 않은 버전입니다: $Version" }
$tag = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
$asset = Join-Path (Join-Path $artifactRoot $rawVersion) 'McpConsole.exe'
if (-not (Test-Path -LiteralPath $asset -PathType Leaf)) { throw "실행 파일을 찾을 수 없습니다: $asset" }

$notes = Get-ReleaseNotes -ReadmePath (Join-Path $releaseRoot 'README.md') -ReleaseVersion $rawVersion
$assetInfo = Get-Item -LiteralPath $asset
$sizeMb = [Math]::Round($assetInfo.Length / 1MB, 2)

Write-Host "[INFO] 기준 디렉터리: $releaseRoot"
Write-Host "[INFO] 릴리스 태그: $tag (버전: $rawVersion)"
Write-Host "[INFO] 대상 저장소: $Repo"
Write-Host "[INFO] 업로드 파일: $($assetInfo.Name) ($sizeMb MB)"
Write-Host "`n[PREVIEW] 릴리스 노트:`n$notes"

if ($DryRun) {
    Write-Host "`n[DRY-RUN] 실제 GitHub 변경 없이 미리보기만 완료했습니다."
    return
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI(gh)를 찾을 수 없습니다. https://cli.github.com/ 에서 설치하세요."
}
& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI 인증이 필요합니다. 먼저 gh auth login을 실행하세요.' }

$notesFile = Join-Path ([IO.Path]::GetTempPath()) ("mcpconsole-release-" + [guid]::NewGuid().ToString('N') + '.md')
try {
    [IO.File]::WriteAllText($notesFile, $notes, [Text.UTF8Encoding]::new($false))
    $ghArgs = @('release', 'create', $tag, $asset, '--repo', $Repo, '--title', $tag, '--notes-file', $notesFile)
    if ($Draft) { $ghArgs += '--draft' }
    if ($Prerelease) { $ghArgs += '--prerelease' }

    Write-Host "`n[EXEC] GitHub Release를 생성하고 파일을 업로드합니다."
    & gh @ghArgs
    if ($LASTEXITCODE -ne 0) { throw "릴리스 생성 실패 (종료 코드 $LASTEXITCODE)" }
    Write-Host "[SUCCESS] 릴리스 배포를 완료했습니다."
}
finally {
    Remove-Item -LiteralPath $notesFile -Force -ErrorAction SilentlyContinue
}
