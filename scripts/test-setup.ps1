$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot/setup-common.ps1"
function Assert-Setup($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$names = Get-SetupNames 'Interview Demo'
Assert-Setup ($names.Database -eq 'demo_interview_demo') 'Name normalization failed.'
Assert-Setup ($names.Prefix -eq (Get-SetupNames 'INTERVIEW DEMO').Prefix) 'Names must map deterministically.'
Assert-Setup ($names.Prefix -ne (Get-SetupNames 'Another Demo').Prefix) 'Named setups must have separate UIDs.'
foreach ($invalid in @('', '!!!', ('x' * 41))) {
    $rejected = $false
    try { $null = Get-SetupNames $invalid } catch { $rejected = $true }
    Assert-Setup $rejected 'Invalid setup name was accepted.'
}
$map = @{}
$templates = @(Get-ChildItem (Join-Path $root 'grafana/dashboards') -Filter '*.json' | ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json })
foreach ($template in $templates) { $map[$template.uid] = "$($names.Prefix)-$($template.uid.Substring(4))" }
foreach ($template in $templates) {
    $original = $template | ConvertTo-Json -Depth 100
    $copy = Convert-SetupDashboard $template $names $map
    $json = $copy | ConvertTo-Json -Depth 100
    Assert-Setup ($copy.uid -eq $map[$template.uid] -and $copy.uid.Length -le 40) 'Invalid remapped dashboard UID.'
    Assert-Setup ($null -eq $copy.id -and $copy.version -eq 0) 'Instance-specific identity was retained.'
    Assert-Setup (-not $json.Contains('bfwp0qtw81z40a')) 'Original datasource reference remains.'
    foreach ($uid in $map.Keys) { Assert-Setup (-not $json.Contains($uid)) 'Original dashboard UID or drill-down link remains.' }
    Assert-Setup (($template | ConvertTo-Json -Depth 100) -eq $original) 'Source template was mutated.'
    Assert-Setup (@($copy.panels).Count -eq @($template.panels).Count) 'Panels were lost.'
}
foreach ($path in @('setup.ps1', 'scripts/setup-common.ps1', 'scripts/test-setup.ps1')) {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root $path), [ref]$tokens, [ref]$errors)
    Assert-Setup ($errors.Count -eq 0) "PowerShell parse error in $path"
}
$fixture = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($fixture, "GRAFANA_URL=https://example.invalid`nGRAFANA_SERVICE_ACCOUNT_TOKEN=test-only`nPOSTGRES_HOST=localhost`nPOSTGRES_USER=tester`nPOSTGRES_PASSWORD=test-only`n")
    $result = & "$root/setup.ps1" -Name 'Fixture Demo' -Plan -EnvFile $fixture
    Assert-Setup (($result -join "`n").Contains('Plan validated. No connections or changes made.')) 'Offline plan failed.'
    # Exercise orchestration with in-process fakes: no network or database access.
    $fakePsql = [IO.Path]::Combine([IO.Path]::GetTempPath(), ([guid]::NewGuid().ToString() + '.ps1'))
    [IO.File]::WriteAllText($fakePsql, @'
$global:setupSqlCalls += ,@($args)
$global:LASTEXITCODE = 0
if ($args -contains 'SELECT 1 FROM pg_database WHERE datname = ''demo_fixture_demo''') {
    if ($global:setupDatabaseExists) { '1' }
}
'@)
    function Get-Command { param($Name, $ErrorAction) if ($Name -eq 'psql') { [pscustomobject]@{ Source = $fakePsql } } else { throw 'Unexpected command lookup.' } }
    function Invoke-RestMethod {
        param($Uri, $Method, $Headers, $MaximumRedirection, $TimeoutSec, $ContentType, $Body)
        $global:setupApiCalls += [pscustomobject]@{ Uri = $Uri; Method = $Method; Body = $Body }
        if ($Method -eq 'GET' -and ($Uri -match '/api/user$')) { return @{ login = 'test-service-account' } }
        if ($Method -eq 'GET' -and ($Uri -match '/health$')) { return @{ status = 'OK' } }
        if ($Method -eq 'GET') { return $null }
        return @{ status = 'success' }
    }
    try {
        $global:setupSqlCalls = @(); $global:setupApiCalls = @(); $global:setupDatabaseExists = $false
        $passwordBefore = $env:PGPASSWORD
        $result = & "$root/setup.ps1" -Name 'Fixture Demo' -Yes -EnvFile $fixture
        Assert-Setup (($result -join "`n").Contains('Setup complete:')) 'Mocked setup did not complete.'
        Assert-Setup (@($global:setupSqlCalls | Where-Object { $_ -contains '-f' }).Count -eq 20) 'Not all migrations and validations ran.'
        Assert-Setup (@($global:setupApiCalls | Where-Object Method -eq POST).Count -eq 7) 'Expected one folder, one datasource, and five dashboard creates.'
        Assert-Setup ($env:PGPASSWORD -eq $passwordBefore) 'Password environment was not restored.'
        $global:setupSqlCalls = @(); $global:setupApiCalls = @(); $global:setupDatabaseExists = $true
        $rejected = $false
        try { $null = & "$root/setup.ps1" -Name 'Fixture Demo' -Yes -EnvFile $fixture } catch { $rejected = $_.Exception.Message -match 'already exists' }
        Assert-Setup $rejected 'Existing database was not refused.'
        Assert-Setup ($global:setupSqlCalls.Count -eq 1) 'SQL mutation occurred after collision.'
        Assert-Setup (@($global:setupApiCalls | Where-Object Method -eq POST).Count -eq 0) 'Grafana mutation occurred after collision.'
        # Database-only setup must work without any Grafana credentials or calls.
        [IO.File]::WriteAllText($fixture, "POSTGRES_HOST=localhost`nPOSTGRES_USER=tester`nPOSTGRES_PASSWORD=test-only`n")
        $global:setupSqlCalls = @(); $global:setupApiCalls = @(); $global:setupDatabaseExists = $false
        $result = & "$root/setup.ps1" -Name 'Fixture Demo' -Mode Database -Yes -EnvFile $fixture
        Assert-Setup (($result -join "`n").Contains('Database setup complete:')) 'Database-only setup failed.'
        Assert-Setup ($global:setupApiCalls.Count -eq 0) 'Database-only setup contacted Grafana.'
        Assert-Setup (@($global:setupSqlCalls | Where-Object { $_ -contains '-f' }).Count -eq 20) 'Database-only setup missed SQL steps.'
        # Grafana-only setup must use POSTGRES_DB and require no psql installation.
        [IO.File]::WriteAllText($fixture, "GRAFANA_URL=https://example.invalid`nGRAFANA_SERVICE_ACCOUNT_TOKEN=test-only`nPOSTGRES_HOST=localhost`nPOSTGRES_USER=tester`nPOSTGRES_PASSWORD=test-only`nPOSTGRES_DB=existing_demo`nDATABASE_URL_UNPOOLED=replace_me`n")
        function Get-Command { throw 'Grafana-only setup must not look up psql.' }
        $global:setupSqlCalls = @(); $global:setupApiCalls = @()
        $result = & "$root/setup.ps1" -Name 'Fixture Demo' -Mode Grafana -Yes -EnvFile $fixture
        Assert-Setup (($result -join "`n").Contains('Setup complete:')) 'Grafana-only setup failed.'
        Assert-Setup ($global:setupSqlCalls.Count -eq 0) 'Grafana-only setup executed SQL.'
        Assert-Setup (@($global:setupApiCalls | Where-Object Method -eq POST).Count -eq 7) 'Grafana-only setup missed resources.'
        $dsCall = $global:setupApiCalls | Where-Object { $_.Method -eq 'POST' -and $_.Uri -match '/api/datasources$' }
        $dsBody = [Text.Encoding]::UTF8.GetString($dsCall.Body) | ConvertFrom-Json
        Assert-Setup ($dsBody.database -eq 'existing_demo' -and $dsBody.jsonData.database -eq 'existing_demo') 'Grafana did not use the supplied existing database.'
    } finally {
        Remove-Item -LiteralPath $fakePsql
        Remove-Item Function:Get-Command, Function:Invoke-RestMethod
        Remove-Variable setupSqlCalls, setupApiCalls, setupDatabaseExists -Scope Global
    }
} finally { Remove-Item -LiteralPath $fixture }
Write-Output 'SETUP TESTS PASSED: naming, dashboard remaps, template preservation, syntax, offline plan, mocked full setup, environment restoration, and existing-database refusal.'
