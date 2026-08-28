. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig
$grafanaHome = 'C:\Program Files\GrafanaLabs\grafana'
$grafanaExe = Join-Path $grafanaHome 'bin\grafana.exe'
if (-not (Test-Path -LiteralPath $grafanaExe)) { throw "Grafana executable not found at $grafanaExe" }

$runtimeRoot = Join-Path $config.ProjectRoot '.grafana'
$dataPath = Join-Path $runtimeRoot 'data'
$logPath = Join-Path $runtimeRoot 'logs'
$pluginPath = Join-Path $runtimeRoot 'plugins'
New-Item -ItemType Directory -Force -Path $dataPath,$logPath,$pluginPath | Out-Null

$defaultPlugins = Join-Path $grafanaHome 'data\plugins'
if (Test-Path -LiteralPath $defaultPlugins) {
    Get-ChildItem -LiteralPath $defaultPlugins -Directory | ForEach-Object {
        $targetDir = Join-Path $pluginPath $_.Name
        if (-not (Test-Path -LiteralPath $targetDir)) {
            Copy-Item -LiteralPath $_.FullName -Destination $targetDir -Recurse -Force
        }
    }
}

$existing = Get-Content -LiteralPath (Join-Path $runtimeRoot 'grafana.pid') -ErrorAction SilentlyContinue
if ($existing -and (Get-Process -Id $existing -ErrorAction SilentlyContinue)) {
    Write-Output "Project Grafana is already running at http://127.0.0.1:3001 (PID $existing)."
    exit 0
}

$prior = @{
    PGPASSWORD=$env:PGPASSWORD; POSTGRES_HOST=$env:POSTGRES_HOST; POSTGRES_PORT=$env:POSTGRES_PORT;
    POSTGRES_USER=$env:POSTGRES_USER; POSTGRES_PASSWORD=$env:POSTGRES_PASSWORD;
    OPENAI_API_KEY=$env:OPENAI_API_KEY;
    GF_PATHS_DATA=$env:GF_PATHS_DATA; GF_PATHS_LOGS=$env:GF_PATHS_LOGS; GF_PATHS_PLUGINS=$env:GF_PATHS_PLUGINS;
    GF_PATHS_PROVISIONING=$env:GF_PATHS_PROVISIONING; ATX_GRAFANA_DASHBOARDS_PATH=$env:ATX_GRAFANA_DASHBOARDS_PATH
}
try {
    $env:POSTGRES_HOST=$config.Host; $env:POSTGRES_PORT=$config.Port; $env:POSTGRES_USER=$config.User; $env:POSTGRES_PASSWORD=$config.Password
    if ($config.OpenAiApiKey) { $env:OPENAI_API_KEY = $config.OpenAiApiKey }
    $env:GF_PATHS_DATA=$dataPath; $env:GF_PATHS_LOGS=$logPath; $env:GF_PATHS_PLUGINS=$pluginPath
    $env:GF_PATHS_PROVISIONING=Join-Path $config.ProjectRoot 'grafana\provisioning'
    $env:ATX_GRAFANA_DASHBOARDS_PATH=Join-Path $config.ProjectRoot 'grafana\dashboards'
    $grafanaConfig=Join-Path $config.ProjectRoot 'grafana\grafana.ini'
    $process=Start-Process -FilePath $grafanaExe -ArgumentList @('server',"--homepath=`"$grafanaHome`"","--config=`"$grafanaConfig`"") -WindowStyle Hidden -PassThru
    Set-Content -LiteralPath (Join-Path $runtimeRoot 'grafana.pid') -Value $process.Id
    Write-Output "Started project Grafana at http://127.0.0.1:3001 (PID $($process.Id))."
}

finally {
    foreach($key in $prior.Keys){if($null -eq $prior[$key]){Remove-Item "Env:$key" -ErrorAction SilentlyContinue}else{Set-Item "Env:$key" $prior[$key]}}
}
