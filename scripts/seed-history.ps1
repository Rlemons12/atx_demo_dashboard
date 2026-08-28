. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

$schemaMarker = Invoke-AtxPsql -Config $config -Database $config.Database -Command "SELECT to_regclass('public.condition_measurements') AS history_schema_marker;"
if (($schemaMarker -join "`n") -notmatch 'condition_measurements') {
    Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\004_history_schema.sql')
    Write-Output 'Milestone 2 schema migration applied.'
}
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\005_seed_history.sql')
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\006_history_views.sql')
Write-Output 'Deterministic historical data and trend views applied.'
