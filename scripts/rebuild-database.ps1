param([switch]$ConfirmRebuild)
. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig
if (-not $ConfirmRebuild) { throw 'Rebuild deletes the project-owned database. Re-run with -ConfirmRebuild.' }
if ($config.Database -ne 'atx_demo_dashboard') { throw "Refusing to rebuild unexpected database '$($config.Database)'." }
$priorPassword = $env:PGPASSWORD
try {
    $env:PGPASSWORD = $config.Password
    & $config.Psql -X -v ON_ERROR_STOP=1 -h $config.Host -p $config.Port -U $config.User -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='atx_demo_dashboard' AND pid <> pg_backend_pid();"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to terminate project database sessions.' }
    & (Get-Command dropdb -ErrorAction Stop).Source -h $config.Host -p $config.Port -U $config.User --if-exists atx_demo_dashboard
    if ($LASTEXITCODE -ne 0) { throw 'Unable to drop project database.' }
}
finally {
    if ($null -eq $priorPassword) { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue } else { $env:PGPASSWORD = $priorPassword }
}
& "$PSScriptRoot\initialize-database.ps1"
& "$PSScriptRoot\seed-database.ps1"
& "$PSScriptRoot\validate-database.ps1"
& "$PSScriptRoot\seed-history.ps1"
& "$PSScriptRoot\validate-milestone2.ps1"
& "$PSScriptRoot\seed-production.ps1"
& "$PSScriptRoot\validate-milestone2_5.ps1"
& "$PSScriptRoot\seed-line2-equipment-inputs.ps1"
& "$PSScriptRoot\validate-milestone4.ps1"
& "$PSScriptRoot\seed-current-demo-state.ps1"
& "$PSScriptRoot\validate-current-demo-state.ps1"
