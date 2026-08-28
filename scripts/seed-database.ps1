. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\002_seed_master.sql')
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\003_views.sql')
Write-Output 'Master data and Grafana views applied.'
