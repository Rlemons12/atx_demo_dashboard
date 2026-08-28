. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig
Write-Output "Host: $($config.Host)"
Write-Output "Port: $($config.Port)"
Write-Output "Target database: $($config.Database)"
Write-Output "Target schema: $($config.Schema)"
Invoke-AtxPsql -Config $config -Database 'postgres' -Command "SELECT 'Connection: success' AS result, version() AS server_version;"
