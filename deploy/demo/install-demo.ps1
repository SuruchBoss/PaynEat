# PaynEat demo for Windows + Docker Desktop -- no git, no Node, no Flutter, no build.
#
# Paste this one line into PowerShell and press Enter:
#
#   [Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object Net.WebClient).DownloadString('https://github.com/SuruchBoss/PaynEat/releases/download/demo/install-demo.ps1'))
#
# It downloads the images that .github/workflows/demo-images.yml built from main, loads them into
# Docker Desktop, starts PaynEat and opens http://localhost:8080. Paste it again later to update.
# Keep this file ASCII-only: Windows PowerShell 5.1 decodes the downloaded script with the ANSI
# code page, so any Thai text here would turn into garbage.

function Install-PaynEatDemo {
  $release = 'https://github.com/SuruchBoss/PaynEat/releases/download/demo'
  if ($env:PAYNEAT_DEMO_RELEASE) { $release = $env:PAYNEAT_DEMO_RELEASE }
  $root = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
  $dir = Join-Path $root 'PaynEat-Demo'
  $ProgressPreference = 'SilentlyContinue'
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
  } catch { }

  Write-Host ''
  Write-Host '=== PaynEat demo ===' -ForegroundColor Cyan

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host 'Docker Desktop is not installed (the "docker" command was not found).' -ForegroundColor Red
    Write-Host 'Install it from https://www.docker.com/products/docker-desktop/ and try again.'
    return
  }
  docker info *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker Desktop is not running.' -ForegroundColor Yellow
    Write-Host 'Open Docker Desktop, wait until the bottom-left says "Engine running", then paste the command again.'
    return
  }

  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $compose = Join-Path $dir 'docker-compose.yml'
  $images = Join-Path $dir 'payneat-demo-images.tar.gz'

  Write-Host '[1/4] Downloading PaynEat (about 200 MB) ...'
  try {
    Invoke-WebRequest -UseBasicParsing -Uri "$release/docker-compose.demo.yml" -OutFile $compose
    Invoke-WebRequest -UseBasicParsing -Uri "$release/payneat-demo-images.tar.gz" -OutFile $images
  } catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Check the internet connection and paste the command again.'
    return
  }

  Write-Host '[2/4] Loading it into Docker Desktop ...'
  docker load -i $images
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker could not load the images (see the message above).' -ForegroundColor Red
    return
  }
  Remove-Item -Force $images -ErrorAction SilentlyContinue

  Write-Host '[3/4] Starting PaynEat ...'
  # Old PaynEat containers from "docker compose up" in a source folder use the same names.
  docker rm -f payneat-api payneat-web *> $null
  docker compose -f $compose up -d
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'PaynEat could not start (see the message above).' -ForegroundColor Red
    Write-Host 'If it says "port is already allocated": close whatever uses port 3000 or 8080'
    Write-Host '(for example a window running "npm run dev") and paste the command again.'
    return
  }

  $cmd = @{
    'Start PaynEat.cmd' = "@echo off`r`ndocker compose -f `"%~dp0docker-compose.yml`" up -d`r`nstart http://localhost:8080`r`n"
    'Stop PaynEat.cmd' = "@echo off`r`ndocker compose -f `"%~dp0docker-compose.yml`" stop`r`npause`r`n"
    'Reset PaynEat data.cmd' = "@echo off`r`necho This erases every order/bill made in the demo and restores the sample data.`r`npause`r`ndocker compose -f `"%~dp0docker-compose.yml`" down -v`r`ndocker compose -f `"%~dp0docker-compose.yml`" up -d`r`nstart http://localhost:8080`r`n"
  }
  foreach ($name in $cmd.Keys) {
    Set-Content -Path (Join-Path $dir $name) -Value $cmd[$name] -Encoding ASCII -NoNewline
  }

  Write-Host '[4/4] Waiting for PaynEat to be ready ...'
  $ready = $false
  for ($i = 0; $i -lt 60 -and -not $ready; $i++) {
    try {
      $api = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:3000/health' -TimeoutSec 3
      $web = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8080/' -TimeoutSec 3
      if ($api.StatusCode -eq 200 -and $web.StatusCode -eq 200) { $ready = $true }
    } catch { }
    if (-not $ready) { Start-Sleep -Seconds 2 }
  }
  if (-not $ready) {
    Write-Host 'PaynEat started but is not answering yet. Open Docker Desktop > Containers > payneat to see its logs.' -ForegroundColor Yellow
    return
  }

  Write-Host ''
  Write-Host 'PaynEat is ready:  http://localhost:8080' -ForegroundColor Green
  Write-Host 'Log in with:  admin / admin123   manager / manager123   cashier / cashier123'
  Write-Host "Start / Stop / Reset shortcuts are in: $dir"
  try { Start-Process 'http://localhost:8080' } catch { }
}

Install-PaynEatDemo
