function Install-Chocolatey {
    Write-Host "Checking for Chocolatey installation..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey not found. Installing Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            if ($LASTEXITCODE -ne 0) {
                throw "Error installing Chocolatey."
            }
        } catch {
            Write-Host "Error installing Chocolatey. Please check permissions or retry manually."
            exit 1
        }
    } else {
        Write-Host "Chocolatey is already installed."
    }
}
