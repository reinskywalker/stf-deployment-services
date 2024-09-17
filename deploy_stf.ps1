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

[System.Environment]::SetEnvironmentVariable("STF_IP", $ip, [System.EnvironmentVariableTarget]::Process)
[System.Environment]::SetEnvironmentVariable("DNS_ADDRESS", $dns, [System.EnvironmentVariableTarget]::Process)

. .\modules\Install-Chocolatey.ps1
. .\modules\Install-Tool.ps1
. .\modules\Prepare-Environment.ps1
. .\modules\Run-Docker-Container.ps1

if (-not (Test-Path "env.ok")) {
    Prepare-Environment -ip $ip -dns $dns
}

try {
    Write-Host "Starting ADB server..."
    Start-Process adb -ArgumentList "start-server" -NoNewWindow -Wait
    Start-Sleep -Seconds 5
    $adbStatus = Get-Process adb -ErrorAction SilentlyContinue

    if ($adbStatus) {
        Write-Host "ADB server started successfully."
    } else {
        throw "Failed to verify ADB server start."
    }
} catch {
    Write-Host "Failed to start ADB server. Ensure ADB is installed correctly."
    Write-Host $_.Exception.Message
    exit 1
}

function Test-DockerContainerExists {
    param (
        [string]$containerName
    )
    $result = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
    return $result -ne ""
}

function Run-Docker-Container {
    param (
        [string]$name,
        [string]$image,
        [string[]]$options,
        [string[]]$cmdArgs = @()
    )

    try {
        if (Test-DockerContainerExists -containerName $name) {
            Write-Host "Removing existing Docker container: $name"
            docker rm -f $name
        } else {
            Write-Host "No existing container named $name. Skipping removal."
        }

        Write-Host "Running Docker container: $name"
        docker run -d --name $name @options $image @cmdArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to run Docker container: $name"
        }
    } catch {
        Write-Host $_.Exception.Message
        exit 1
    }
}

Write-Host "Starting Docker containers..."

Run-Docker-Container "rethinkdb" "rethinkdb" @("--net=host") @("rethinkdb", "--bind", "all", "--cache-size", "8192", "--http-port", "8090")

$currentLocation = Get-Location

$nginxConfigPath = (Resolve-Path "$PSScriptRoot\nginx.conf").Path
$nginxConfigPath = $nginxConfigPath -replace '\\', '/' 
$nginxConfigPath = $nginxConfigPath -replace '^[A-Za-z]:', { "/$($matches[0].Substring(0, 1).ToLower())" }
$nginxConfigPath = $nginxConfigPath.Trim()
$nginxConfigPath = $nginxConfigPath.ToLower()

if ($nginxConfigPath -match '^\s') {
    Write-Host "Invalid characters detected in the path: '$nginxConfigPath'" -ForegroundColor Red
    exit 1
}

Write-Host "Using nginx config path: '$nginxConfigPath'"
$nginxVolumeOption = "-v ${nginxConfigPath}:/etc/nginx/nginx.conf:ro"
Write-Host "Constructed Docker volume option: '$nginxVolumeOption'"
Run-Docker-Container "nginx" "nginx" @($nginxVolumeOption, "--net=host")
Run-Docker-Container "stf-migrate" "openstf/stf" @("--net=host") @("stf", "migrate")
Run-Docker-Container "storage-plugin-apk-3300" "openstf/stf" @("--net=host") @("stf", "storage-plugin-apk", "--port", "3000", "--storage-url", "http://$ip/")
Run-Docker-Container "storage-plugin-image-3400" "openstf/stf" @("--net=host") @("stf", "storage-plugin-image", "--port", "3000", "--storage-url", "http://$ip/")
Run-Docker-Container "storage-temp-3500" "openstf/stf" @("--net=host") @("stf", "storage-temp", "--port", "3000", "--save-dir", "/home/stf")
Write-Host "All components have been started successfully."
