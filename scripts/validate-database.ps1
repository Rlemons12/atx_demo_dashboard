. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\validate.sql')
