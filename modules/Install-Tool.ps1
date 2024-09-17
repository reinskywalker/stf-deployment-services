function Install-Tool {
    param(
        [string]$toolName,
        [string]$chocoPackageName
    )
    Write-Host "Checking for $toolName installation..."
    if (-not (Get-Command $toolName -ErrorAction SilentlyContinue)) {
        Write-Host "$toolName not found. Installing $toolName..."
        try {
            choco install -y $chocoPackageName
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install $toolName."
            }
        } catch {
            Write-Host "An error occurred during $toolName installation."
            exit 1
        }
    } else {
        Write-Host "$toolName is already installed."
    }
}
