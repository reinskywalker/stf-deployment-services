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

. .\Install-Chocolatey.ps1
. .\Install-Tool.ps1
. .\Prepare-Environment.ps1
. .\Run-Docker-Container.ps1

if (-not (Test-Path "env.ok")) {
    Prepare-Environment -ip $ip -dns $dns
}

try {
    Write-Host "Starting ADB server"
    Start-Process adb -ArgumentList "start-server" -Wait
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start ADB server."
    }
} catch {
    Write-Host "Failed to start ADB server. Ensure ADB is installed correctly."
    exit 1
}

Run-Docker-Container "rethinkdb" "rethinkdb rethinkdb --bind all --cache-size 8192 --http-port 8090"
Run-Docker-Container "nginx" "nginx -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro"
Run-Docker-Container "stf-migrate" "openstf/stf stf migrate"
Run-Docker-Container "storage-plugin-apk-3300" "openstf/stf stf storage-plugin-apk --port 3000 --storage-url http://$ip/"
Run-Docker-Container "storage-plugin-image-3400" "openstf/stf stf storage-plugin-image --port 3000 --storage-url http://$ip/"
Run-Docker-Container "storage-temp-3500" "openstf/stf stf storage-temp --port 3000 --save-dir /home/stf"

Write-Host "All components have been started successfully."
