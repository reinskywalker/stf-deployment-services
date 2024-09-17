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

[System.Environment]::SetEnvironmentVariable("DEPLOY_STF_IP", $ip, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("DEPLOY_STF_DNS", $dns, [System.EnvironmentVariableTarget]::User)

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
        [string]$command
    )

    try {
        if (Test-DockerContainerExists -containerName $name) {
            Write-Host "Removing existing Docker container: $name"
            docker rm -f $name
        } else {
            Write-Host "No existing container named $name. Skipping removal."
        }

        Write-Host "Running Docker container: $name"
        docker run -d --name $name --net host $command
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to run Docker container: $name"
        }
    } catch {
        Write-Host $_.Exception.Message
        exit 1
    }
}

Write-Host "Starting Docker containers..."
Run-Docker-Container "rethinkdb" "rethinkdb rethinkdb --bind all --cache-size 8192 --http-port 8090"
Run-Docker-Container "nginx" "nginx -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro"
Run-Docker-Container "stf-migrate" "openstf/stf stf migrate"
Run-Docker-Container "storage-plugin-apk-3300" "openstf/stf stf storage-plugin-apk --port 3000 --storage-url http://$ip/"
Run-Docker-Container "storage-plugin-image-3400" "openstf/stf stf storage-plugin-image --port 3000 --storage-url http://$ip/"
Run-Docker-Container "storage-temp-3500" "openstf/stf stf storage-temp --port 3000 --save-dir /home/stf"

Write-Host "All components have been started successfully."
