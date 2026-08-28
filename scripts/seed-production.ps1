. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

$schemaMarker = Invoke-AtxPsql -Config $config -Database $config.Database -Command "SELECT to_regclass('public.products') AS production_schema_marker;"
if (($schemaMarker -join "`n") -notmatch 'products') {
    Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\007_production_schema.sql')
    Write-Output 'Milestone 2.5 production schema migration applied.'
}
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\008_seed_production.sql')
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\009_production_views.sql')
Write-Output 'Milestone 2.5 deterministic production data and OEE views applied.'
