$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = @{}
Get-Content -LiteralPath (Join-Path $projectRoot '.env') | ForEach-Object {
    if ($_ -match '^\s*(GRAFANA_URL|GRAFANA_SERVICE_ACCOUNT_TOKEN)\s*=\s*(.*?)\s*$') {
        $config[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}
if (-not $config.GRAFANA_URL -or -not $config.GRAFANA_SERVICE_ACCOUNT_TOKEN) {
    throw 'Set GRAFANA_URL and GRAFANA_SERVICE_ACCOUNT_TOKEN in .env.'
}
$base = [uri]$config.GRAFANA_URL
if ($base.Scheme -ne 'https' -and -not $base.IsLoopback) {
    throw 'Remote Grafana connections require HTTPS.'
}
$headers = @{ Authorization = 'Bearer ' + $config.GRAFANA_SERVICE_ACCOUNT_TOKEN }
function Get-GrafanaJson([string]$Path) {
    try {
        Invoke-RestMethod -Uri ($base.AbsoluteUri.TrimEnd('/') + $Path) -Headers $headers -Method Get -MaximumRedirection 0 -TimeoutSec 60
    } catch {
        # Do not include request headers or response bodies in errors.
        throw "Grafana GET $Path failed; check connectivity and token permissions."
    }
}
$directory = Join-Path $projectRoot 'grafana/dashboards'
$existing = @{}
Get-ChildItem -LiteralPath $directory -Filter '*.json' | ForEach-Object {
    $dashboard = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
    if ($existing.ContainsKey($dashboard.uid)) { throw 'Duplicate local dashboard UID.' }
    $existing[$dashboard.uid] = $_.Name
}
$found = @{}
for ($page = 1; ; $page++) {
    $batch = @(Get-GrafanaJson "/api/search?type=dash-db&limit=1000&page=$page")
    foreach ($item in $batch) {
        if ($found.ContainsKey($item.uid)) { throw 'Search returned a duplicate UID; export stopped.' }
        $found[$item.uid] = $item
    }
    if ($batch.Count -lt 1000) { break }
}
if ($found.Count -eq 0) { throw 'No accessible dashboards found; local files unchanged.' }
$exports = @()
$manifest = @()
$filenames = @{}
foreach ($uid in ($found.Keys | Sort-Object)) {
    # Grafana Cloud installs account-monitoring dashboards unrelated to this demo.
    # Only ATX dashboards belong in the project's file provisioning directory.
    if ($uid -notlike 'atx-*') { continue }
    $response = Get-GrafanaJson ('/api/dashboards/uid/' + [uri]::EscapeDataString($uid))
    if ($response.dashboard.uid -ne $uid -or -not $response.dashboard.title) { throw 'Invalid dashboard response.' }
    $filename = $existing[$uid]
    if (-not $filename) {
        if ($uid -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Dashboard UID is unsafe as a filename.' }
        $filename = "remote-$uid.json"
        if (Test-Path -LiteralPath (Join-Path $directory $filename)) { throw "Filename collision: $filename" }
    }
    if ($filenames.ContainsKey($filename)) { throw "Filename collision: $filename" }
    $filenames[$filename] = $true
    # Instance-specific numeric IDs must not be reused by local provisioning.
    $response.dashboard.id = $null
    $json = $response.dashboard | ConvertTo-Json -Depth 100
    $null = $json | ConvertFrom-Json
    $exports += @{ Filename = $filename; Json = $json }
    $manifest += [ordered]@{ uid = $uid; title = $response.dashboard.title; file = "dashboards/$filename"; folderUid = $response.meta.folderUid; folderTitle = $response.meta.folderTitle; version = $response.dashboard.version }
}
# Fetch and validate every dashboard before replacing any local configuration.
if ($exports.Count -eq 0) { throw 'No accessible ATX dashboards found; local files unchanged.' }
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($export in $exports) {
    [IO.File]::WriteAllText((Join-Path $directory $export.Filename), $export.Json + "`n", $utf8)
}
$record = [ordered]@{ source = $base.GetLeftPart([System.UriPartial]::Authority); exportedAt = [DateTime]::UtcNow.ToString('o'); dashboards = @($manifest) }
[IO.File]::WriteAllText((Join-Path $projectRoot 'grafana/dashboard-export.json'), ($record | ConvertTo-Json -Depth 10) + "`n", $utf8)
Write-Output "Exported $($exports.Count) dashboards. Existing local dashboards absent from the remote listing were retained."
