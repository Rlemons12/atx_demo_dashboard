. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

$priorPassword = $env:PGPASSWORD
try {
    $env:PGPASSWORD = $config.Password
    $exists = & $config.Psql -X -At -v ON_ERROR_STOP=1 -h $config.Host -p $config.Port -U $config.User -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$($config.Database.Replace("'", "''"))';"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect target database.' }
    if ($exists -ne '1') {
        & $config.Createdb -h $config.Host -p $config.Port -U $config.User -O $config.User $config.Database
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create target database.' }
        Write-Output "Created dedicated database $($config.Database)."
    } else {
        Write-Output "Database $($config.Database) already exists."
    }
}
finally {
    if ($null -eq $priorPassword) { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue } else { $env:PGPASSWORD = $priorPassword }
}

$tableExists = Invoke-AtxPsql -Config $config -Database $config.Database -Command "SELECT to_regclass('public.sites') AS existing_schema_marker;"
if ($tableExists -match 'sites') {
    throw 'Schema already exists. Use the rebuild command only when intentionally replacing this project-owned database.'
}
Invoke-AtxPsql -Config $config -Database $config.Database -File (Join-Path $config.ProjectRoot 'sql\001_schema.sql')
Write-Output 'Schema migration applied.'
