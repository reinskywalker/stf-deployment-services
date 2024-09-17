function Run-Docker-Container {
    param (
        [string]$name,
        [string]$command
    )

    try {
        docker rm -f $name
        docker run -d --name $name --net host $command
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to run Docker container: $name"
        }
    } catch {
        Write-Host "Failed to run Docker container: $name"
        exit 1
    }
}
