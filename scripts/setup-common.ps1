$ErrorActionPreference = 'Stop'

function Read-SetupEnvironment([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw 'Place the supplied .env in the project root first.' }
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $values
}

function Get-SetupNames([string]$Name) {
    # Stable names let preflight checks detect collisions without overwriting resources.
    $name = $Name.Trim()
    $slug = ($name.ToLowerInvariant() -replace '[^a-z0-9]+', '_').Trim('_')
    if (-not $slug -or $slug.Length -gt 40 -or $name.Length -gt 100) {
        throw 'Use a name with letters or numbers, up to 40 characters after normalization.'
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($slug)))).Replace('-', '').Substring(0, 8).ToLowerInvariant() }
    finally { $sha.Dispose() }
    [pscustomobject]@{ Title = $name; Database = "demo_$slug"; Prefix = "demo-$hash"; Folder = "demo-$hash"; Datasource = "demo-$hash-pg" }
}

function Convert-SetupDashboard($Dashboard, $Names, $UidMap) {
    # Replace UID tokens and link paths throughout nested panels and variables.
    $json = $Dashboard | ConvertTo-Json -Depth 100
    foreach ($oldUid in ($UidMap.Keys | Sort-Object Length -Descending)) {
        $json = $json.Replace($oldUid, $UidMap[$oldUid])
    }
    $json = $json.Replace('bfwp0qtw81z40a', $Names.Datasource)
    $copy = $json | ConvertFrom-Json
    $copy.id = $null
    $copy.version = 0
    return $copy
}
