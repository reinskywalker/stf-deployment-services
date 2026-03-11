function Run-Docker-Container {
    param (
        [string]$name,
        [string]$image,
        [string[]]$options = @(),
        [string[]]$cmdArgs = @()
    )

    try {
        $exists = (& docker ps -a --filter "name=$name" --format "{{.Names}}") -ne ''
        if ($exists) {
            Write-Host "Removing existing Docker container: $name"
            & docker rm -f $name | Out-Null
        } else {
            Write-Host "No existing container named $name."
        }

        Write-Host "Running Docker container: $name"
        $args = @('run','-d','--name',$name) + $options + @($image) + $cmdArgs
        & docker @args
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to run Docker container: $name"
        }
    } catch {
        Write-Host "Failed to run Docker container: $name - $($_.Exception.Message)"
        exit 1
    }
}
