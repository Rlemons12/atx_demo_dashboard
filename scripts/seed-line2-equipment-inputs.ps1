. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

$schemaMarker = Invoke-AtxPsql -Config $config -Database $config.Database -Command "SELECT to_regclass('public.equipment_sensors') AS milestone4_schema_marker;"
if (($schemaMarker -join "`n") -notmatch 'equipment_sensors') {
    Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\010_line2_equipment_inputs.sql')
    Write-Output 'Milestone 4 Line 2 equipment-input schema applied.'
}

$seedMarker = Invoke-AtxPsql -Config $config -Database $config.Database -Command "SELECT CASE WHEN count(*)=0 THEN 'MILESTONE4_EMPTY' ELSE 'MILESTONE4_SEEDED' END FROM equipment_state_events;"
if (($seedMarker -join "`n") -match 'MILESTONE4_EMPTY') {
    Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\011_seed_line2_equipment_inputs.sql')
    Write-Output 'Milestone 4 deterministic Line 2 telemetry and state events seeded.'
}
else {
    Write-Output 'Milestone 4 deterministic seed already present; preserving existing records.'
}

Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\012_line2_oee_views.sql')
Write-Output 'Milestone 4 curated OEE and loss-analysis views applied.'
