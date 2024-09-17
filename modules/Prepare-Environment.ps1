function Prepare-Environment {
    param(
        [string]$ip,
        [string]$dns
    )

    Install-Chocolatey

    Install-Tool "adb" "adb"
    Install-Tool "docker" "docker-desktop"

    if (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue)) {
        Write-Host "Starting Docker Desktop..."
        try {
            Start-Process -NoNewWindow -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            Start-Sleep -Seconds 30
        } catch {
            Write-Host "Failed to start Docker Desktop. Please ensure Docker is installed correctly."
            exit 1
        }
    } else {
        Write-Host "Docker Desktop is already running."
    }

    try {
        docker pull openstf/stf
        docker pull rethinkdb
        docker pull openstf/ambassador
        docker pull nginx
    } catch {
        Write-Host "Error pulling Docker images. Ensure Docker is running and retry."
        exit 1
    }

    try {
        Get-Content nginx.conf.template | ForEach-Object {
            $_ -replace '__IP_ADDRESS__', $ip -replace '__DNS_ADDRESS__', $dns
        } | Set-Content nginx.conf
    } catch {
        Write-Host "Failed to generate nginx configuration."
        exit 1
    }

    Out-File -FilePath "env.ok" -Force
}
