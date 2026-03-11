param (
    [string]$ip = $env:DEPLOY_STF_IP,
    [string]$dns = $env:DEPLOY_STF_DNS
)

if (-not $ip) {
    Write-Host "IP address not provided, using default: 192.168.18.27"
    $ip = "192.168.18.27"
} else {
    Write-Host "Using provided IP address: $ip"
}

if (-not $dns) {
    Write-Host "DNS address not provided, using default: 192.168.18.1"
    $dns = "192.168.18.1"
} else {
    Write-Host "Using provided DNS address: $dns"
}

[System.Environment]::SetEnvironmentVariable("DEPLOY_STF_IP", $ip, [System.EnvironmentVariableTarget]::Process)
[System.Environment]::SetEnvironmentVariable("DEPLOY_STF_DNS", $dns, [System.EnvironmentVariableTarget]::Process)
[System.Environment]::SetEnvironmentVariable("PUBLIC_IP", $ip, [System.EnvironmentVariableTarget]::Process)

. .\modules\Install-Chocolatey.ps1
. .\modules\Install-Tool.ps1
. .\modules\Prepare-Environment.ps1
. .\modules\Run-Docker-Container.ps1

if ($env:OS -eq 'Windows_NT') {
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        Write-Host "Windows detected and docker-compose is available — using docker-compose up -d"
        & docker-compose up -d
        exit 0
    } else {
        Write-Host "Windows detected but docker-compose not found; continuing with docker run flow (may require manual adjustments)."
    }
}

if (-not (Test-Path "env.ok")) {
    Prepare-Environment -ip $ip -dns $dns
}

try {
    Write-Host "Ensuring ADB is available..."
    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        Write-Host "ADB not found in PATH. Ensure it is installed and available."
    } else {
        Start-Process adb -ArgumentList "start-server" -NoNewWindow -Wait
        Start-Sleep -Seconds 2
        Write-Host "ADB server started (or already running)."
    }
} catch {
    Write-Host "ADB start failed: $($_.Exception.Message)"
}

function Test-DockerContainerExists {
    param (
        [string]$containerName
    )
    $result = (& docker ps -a --filter "name=$containerName" --format "{{.Names}}")
    return $result -ne ""
}

function Convert-PathForDocker {
    param([string]$path)
    if (-not $path) { return $path }
    $p = $path -replace '\\','/'
    if ($p -match '^[A-Za-z]:') {
        $drive = $p.Substring(0,1).ToLower()
        $p = "/$drive" + $p.Substring(2)
    }
    return $p
}

Write-Host "Starting Docker containers..."

Run-Docker-Container "rethinkdb" "rethinkdb" @() @("rethinkdb", "--bind", "all", "--cache-size", "8192", "--http-port", "8090")

$nginxWindowsPath = (Resolve-Path (Join-Path $PSScriptRoot 'nginx\nginx.conf')).Path
$nginxConfigPathForDocker = Convert-PathForDocker $nginxWindowsPath
if ($nginxWindowsPath -match '^\s') {
    Write-Host "Invalid characters detected in the path: '$nginxWindowsPath'" -ForegroundColor Red
    exit 1
}
Write-Host "Using nginx config path: '$nginxWindowsPath'"
$nginxVolumeOption = "-v `"$nginxConfigPathForDocker`":/etc/nginx/nginx.conf:ro"
Run-Docker-Container "nginx" "nginx" @($nginxVolumeOption) @()

Run-Docker-Container "stf-migrate" "openstf/stf" @() @("stf", "migrate")
Run-Docker-Container "storage-plugin-apk-3300" "openstf/stf" @() @("stf", "storage-plugin-apk", "--port", "3000", "--storage-url", "http://$ip/")
Run-Docker-Container "storage-plugin-image-3400" "openstf/stf" @() @("stf", "storage-plugin-image", "--port", "3000", "--storage-url", "http://$ip/")
Run-Docker-Container "storage-temp-3500" "openstf/stf" @() @("stf", "storage-temp", "--port", "3000", "--save-dir", "/home/stf")

Write-Host "All components have been started (or attempted)."
