# Create only the selected components; Grafana-only mode connects to POSTGRES_DB.
# LOCAL_DATABASE_URL is not consumed here: use the POSTGRES_* settings in .env.
param(
    [string]$Name,
    [ValidateSet('Both', 'Grafana', 'Database')][string]$Mode,
    [switch]$Yes,
    [switch]$Plan,
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env')
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/setup-common.ps1"

if (-not $Yes -and -not $Plan) {
    if (-not $Mode) {
        do { $answer = Read-Host 'Set up: [1] Both, [2] Grafana only, [3] Database only, [Q] Cancel' } until ($answer -match '^[123qQ]$')
        switch ($answer) { '1' { $Mode = 'Both' } '2' { $Mode = 'Grafana' } '3' { $Mode = 'Database' } default { Write-Output 'Setup cancelled.'; return } }
    }
}
if (-not $Mode) { $Mode = 'Both' }
$setupDatabase = $Mode -in @('Both', 'Database')
$setupGrafana = $Mode -in @('Both', 'Grafana')
if (-not $Name) { $Name = Read-Host 'What would you like to call it?' }
$names = Get-SetupNames $Name
$values = Read-SetupEnvironment $EnvFile
$required = @('POSTGRES_HOST', 'POSTGRES_USER', 'POSTGRES_PASSWORD')
if ($setupGrafana) { $required += @('GRAFANA_URL', 'GRAFANA_SERVICE_ACCOUNT_TOKEN') }
if (-not $setupDatabase) { $required += 'POSTGRES_DB' }
foreach ($key in $required) {
    if (-not $values[$key] -or $values[$key] -eq 'replace_me') { throw "Supply $key in .env." }
}
if (-not $setupDatabase) { $names.Database = $values.POSTGRES_DB }
if ($setupGrafana) {
$grafana = [uri]$values.GRAFANA_URL
if (-not $grafana.IsAbsoluteUri -or ($grafana.Scheme -ne 'https' -and -not ($grafana.Scheme -eq 'http' -and $grafana.IsLoopback))) {
    throw 'GRAFANA_URL must use HTTPS, except for a local loopback server.'
}
}
$dbHost = $values.POSTGRES_HOST
$dbPort = if ($values.POSTGRES_PORT) { $values.POSTGRES_PORT } else { '5432' }
$dbUser = $values.POSTGRES_USER
$dbPassword = $values.POSTGRES_PASSWORD
$sslMode = if ($values.POSTGRES_SSLMODE) { $values.POSTGRES_SSLMODE } elseif ($dbHost -in @('localhost', '127.0.0.1', '::1')) { 'disable' } else { 'require' }
if ($sslMode -notin @('disable', 'require', 'verify-ca', 'verify-full')) { throw 'Unsupported POSTGRES_SSLMODE.' }
# Migrations should use the direct endpoint when a pooler URL is also supplied.
if ($setupDatabase -and $values.DATABASE_URL_UNPOOLED) {
    if ($values.DATABASE_URL_UNPOOLED -match 'user:password|replace_me') { throw 'Replace DATABASE_URL_UNPOOLED placeholders or remove that optional entry.' }
    $direct = [uri]$values.DATABASE_URL_UNPOOLED
    if ($direct.Scheme -notin @('postgres', 'postgresql')) { throw 'Invalid DATABASE_URL_UNPOOLED.' }
    $dbHost = $direct.Host
    $dbPort = if ($direct.Port -gt 0) { [string]$direct.Port } else { '5432' }
    $parts = $direct.UserInfo -split ':', 2
    if ($parts.Count -ne 2) { throw 'DATABASE_URL_UNPOOLED must include a user and password.' }
    $dbUser = [uri]::UnescapeDataString($parts[0])
    $dbPassword = [uri]::UnescapeDataString($parts[1])
    if ($direct.Query -match '(?:\?|&)sslmode=([^&]+)') { $sslMode = [uri]::UnescapeDataString($matches[1]) }
}
if ($sslMode -notin @('disable', 'require', 'verify-ca', 'verify-full')) { throw 'Unsupported database SSL mode.' }
$dashboards = @()
$uidMap = @{}
if ($setupGrafana) {
$files = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'grafana/dashboards') -Filter '*.json')
$uidMap = @{}
$templates = @()
foreach ($file in $files) {
    $dashboard = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    if ($dashboard.uid -notlike 'atx-*') { continue }
    if ($uidMap.ContainsKey($dashboard.uid)) { throw 'Duplicate dashboard UID.' }
    $uidMap[$dashboard.uid] = "$($names.Prefix)-$($dashboard.uid.Substring(4))"
    $templates += $dashboard
}
if ($templates.Count -ne 5) { throw 'Expected the five ATX dashboard templates.' }
$dashboards = @($templates | ForEach-Object { Convert-SetupDashboard $_ $names $uidMap })
}
$steps = @('001_schema.sql','002_seed_master.sql','003_views.sql','validate.sql',
    '004_history_schema.sql','005_seed_history.sql','006_history_views.sql','validate_milestone2.sql',
    '007_production_schema.sql','008_seed_production.sql','009_production_views.sql','validate_milestone2_5.sql',
    '010_line2_equipment_inputs.sql','011_seed_line2_equipment_inputs.sql','012_line2_oee_views.sql','validate_milestone4.sql',
    '013_demo_context_and_current_state.sql','014_seed_current_demo_state.sql','015_finalize_prior_lots.sql','validate_current_demo_state.sql')
if ($setupDatabase) { foreach ($step in $steps) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "sql/$step"))) { throw "Missing SQL file: $step" }
}
}
Write-Output "Setup mode: $Mode"
Write-Output "Database: $($names.Database)"
if ($setupGrafana) {
Write-Output "Grafana folder: $($names.Title) ($($names.Folder))"
Write-Output "Dashboards: $($dashboards.Count)"
}
if ($Plan) { Write-Output 'Plan validated. No connections or changes made.'; return }
if ($setupDatabase) { $psql = (Get-Command psql -ErrorAction Stop).Source }
$headers = @{ Authorization = 'Bearer ' + $values.GRAFANA_SERVICE_ACCOUNT_TOKEN }
function Invoke-SetupGrafana([string]$Method, [string]$Path, $Body, [switch]$AllowMissing) {
    $request = @{ Uri = $grafana.AbsoluteUri.TrimEnd('/') + $Path; Method = $Method; Headers = $headers; MaximumRedirection = 0; TimeoutSec = 60 }
    if ($null -ne $Body) { $request.ContentType = 'application/json'; $request.Body = [Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 100)) }
    try { return Invoke-RestMethod @request }
    catch {
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        if ($AllowMissing -and $status -eq 404) { return $null }
        throw "Grafana $Method $Path failed (HTTP $status). Check token permissions and connectivity."
    }
}
function Invoke-SetupSql([string]$Database, [string]$Command, [string]$File) {
    $arguments = @('-X', '-w', '-At', '-v', 'ON_ERROR_STOP=1', '-v', "expected_database=$($names.Database)", '-h', $dbHost, '-p', $dbPort, '-U', $dbUser, '-d', $Database)
    if ($Command) { $arguments += @('-c', $Command) }
    if ($File) { $arguments += @('-f', $File) }
    & $psql @arguments
    if ($LASTEXITCODE -ne 0) { throw "Database step failed for $Database. Setup stopped; no resources were deleted." }
}
$prior = @{ PGPASSWORD = $env:PGPASSWORD; PGSSLMODE = $env:PGSSLMODE; PGCONNECT_TIMEOUT = $env:PGCONNECT_TIMEOUT }
try {
    $env:PGPASSWORD = $dbPassword
    $env:PGSSLMODE = $sslMode
    $env:PGCONNECT_TIMEOUT = '15'
    if ($setupGrafana) {
    $null = Invoke-SetupGrafana GET '/api/user'
    foreach ($path in @("/api/folders/$($names.Folder)", "/api/datasources/uid/$($names.Datasource)")) {
        if ($null -ne (Invoke-SetupGrafana GET $path -AllowMissing)) { throw 'A Grafana target already exists. Choose another setup name.' }
    }
    foreach ($dashboard in $dashboards) {
        if ($null -ne (Invoke-SetupGrafana GET "/api/dashboards/uid/$($dashboard.uid)" -AllowMissing)) { throw 'A dashboard target already exists. Choose another setup name.' }
    }
    }
    if ($setupDatabase) {
    $exists = Invoke-SetupSql postgres "SELECT 1 FROM pg_database WHERE datname = '$($names.Database)'"
    if ($exists -eq '1') { throw 'That database already exists. Choose another setup name; existing databases are never overwritten.' }
    Write-Output 'Creating database and loading demo tables, data, and views...'
    $null = Invoke-SetupSql postgres "CREATE DATABASE $($names.Database)"
    foreach ($step in $steps) {
        Write-Output "Applying $step"
        $null = Invoke-SetupSql $names.Database -File (Join-Path $PSScriptRoot "sql/$step")
    }
    }
    if ($setupGrafana) {
    $null = Invoke-SetupGrafana POST '/api/folders' @{ uid = $names.Folder; title = $names.Title }
    $datasource = @{
        uid = $names.Datasource; name = "$($names.Title) PostgreSQL"; type = 'grafana-postgresql-datasource'; access = 'proxy'
        url = "$($values.POSTGRES_HOST):$(if ($values.POSTGRES_PORT) { $values.POSTGRES_PORT } else { '5432' })"
        user = $values.POSTGRES_USER; database = $names.Database; isDefault = $false
        jsonData = @{ database = $names.Database; sslmode = $sslMode; postgresVersion = 1700; timescaledb = $false }
        secureJsonData = @{ password = $values.POSTGRES_PASSWORD }
    }
    $null = Invoke-SetupGrafana POST '/api/datasources' $datasource
    $health = Invoke-SetupGrafana GET "/api/datasources/uid/$($names.Datasource)/health"
    if ($health.status -ne 'OK') { throw 'Grafana cannot query the database. Check database network access and datasource permissions.' }
    foreach ($dashboard in $dashboards) {
        $null = Invoke-SetupGrafana POST '/api/dashboards/db' @{ dashboard = $dashboard; folderUid = $names.Folder; overwrite = $false; message = 'Initial guided demo setup' }
    }
    Write-Output "Setup complete: $($grafana.AbsoluteUri.TrimEnd('/'))/d/$($uidMap['atx-vp-operations'])"
    } else {
        Write-Output "Database setup complete: $($names.Database). To connect Grafana later, set POSTGRES_DB=$($names.Database) in its .env and run setup with -Mode Grafana."
    }
} catch {
    Write-Output 'Setup stopped. Any resources already created were preserved for inspection. Resolve the failure or use a new name for a fresh setup.'
    throw
} finally {
    foreach ($key in $prior.Keys) {
        if ($null -eq $prior[$key]) { Remove-Item "Env:$key" -ErrorAction SilentlyContinue } else { Set-Item "Env:$key" $prior[$key] }
    }
}
