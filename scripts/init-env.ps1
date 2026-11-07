$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $projectRoot '.env.docker.example'
$targetPath = Join-Path $projectRoot '.env.docker'

if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    throw 'Template .env.docker.example tidak ditemukan.'
}

if (Test-Path -LiteralPath $targetPath) {
    throw '.env.docker sudah ada; script tidak menimpa file yang ada.'
}

Copy-Item -LiteralPath $templatePath -Destination $targetPath
Write-Host '.env.docker dibuat. Lengkapi nilai lokal secara manual; isi file tidak ditampilkan.'
