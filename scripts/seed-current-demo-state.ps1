. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\013_demo_context_and_current_state.sql')
Write-Output 'Fixed demo context and current-state semantic views applied.'

Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\014_seed_current_demo_state.sql')
Write-Output 'Deterministic current demo operating state seeded.'
