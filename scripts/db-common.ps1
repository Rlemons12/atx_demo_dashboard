$ErrorActionPreference = 'Stop'

function Get-AtxDatabaseConfig {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $envPath = Join-Path $projectRoot '.env'
    if (-not (Test-Path -LiteralPath $envPath)) { throw "Environment file not found: $envPath" }

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $envPath) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $value = $Matches[2]
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $values[$Matches[1]] = $value
        }
    }

    foreach ($required in @('POSTGRES_USER', 'POSTGRES_PASSWORD')) {
        if (-not $values.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($values[$required])) {
            throw "Required environment variable $required is missing or empty."
        }
    }

    [pscustomobject]@{
        ProjectRoot = $projectRoot
        Host = if ($values.ContainsKey('POSTGRES_HOST')) { $values['POSTGRES_HOST'] } else { 'localhost' }
        Port = if ($values.ContainsKey('POSTGRES_PORT')) { $values['POSTGRES_PORT'] } else { '5432' }
        Database = if ($values.ContainsKey('POSTGRES_DB')) { $values['POSTGRES_DB'] } else { 'atx_demo_dashboard' }
        Schema = if ($values.ContainsKey('POSTGRES_SCHEMA')) { $values['POSTGRES_SCHEMA'] } else { 'public' }
        User = $values['POSTGRES_USER']
        Password = $values['POSTGRES_PASSWORD']
        OpenAiApiKey = if ($values.ContainsKey('OPENAI_API_KEY')) { $values['OPENAI_API_KEY'] } elseif ($values.ContainsKey('OPEMAI_API')) { $values['OPEMAI_API'] } else { '' }
        Psql = (Get-Command psql -ErrorAction Stop).Source
        Createdb = (Get-Command createdb -ErrorAction Stop).Source
    }
}

function Invoke-AtxPsql {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Database,
        [string]$File,
        [string]$Command
    )
    $priorPassword = $env:PGPASSWORD
    try {
        $env:PGPASSWORD = $Config.Password
        $arguments = @('-X', '-v', 'ON_ERROR_STOP=1', '-h', $Config.Host, '-p', $Config.Port, '-U', $Config.User, '-d', $Database)
        if ($File) { $arguments += @('-f', $File) }
        if ($Command) { $arguments += @('-c', $Command) }
        & $Config.Psql @arguments
        if ($LASTEXITCODE -ne 0) { throw "psql failed with exit code $LASTEXITCODE." }
    }
    finally {
        if ($null -eq $priorPassword) { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue } else { $env:PGPASSWORD = $priorPassword }
    }
}
