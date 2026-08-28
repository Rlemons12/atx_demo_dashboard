$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$baseUrl='http://127.0.0.1:3001'

$health=Invoke-RestMethod -Uri "$baseUrl/api/health"
if($health.database -ne 'ok'){throw "Grafana health failed: $($health.database)"}
Write-Output "Grafana health: OK (version $($health.version))"

$datasourceHealth=Invoke-RestMethod -Uri "$baseUrl/api/datasources/uid/atx-postgres/health"
if($datasourceHealth.status -ne 'OK'){throw "Datasource health failed: $($datasourceHealth.message)"}
Write-Output "Datasource health: $($datasourceHealth.message)"

$expected=@('atx-vp-operations','atx-maintenance-reliability','atx-operational-risk','atx-production-oee','atx-equipment-oee-detail')
$allowedLine2Assets=@('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201')
$provisioned=Invoke-RestMethod -Uri "$baseUrl/api/search?type=dash-db"
foreach($uid in $expected){
    if($uid -notin $provisioned.uid){throw "Dashboard $uid was not provisioned."}
    $null=Invoke-RestMethod -Uri "$baseUrl/api/dashboards/uid/$uid"
}
Write-Output "Dashboard provisioning: $($expected.Count)/$($expected.Count) loaded"

$queryCount=0;$frameCount=0;$failures=@()
$dashboardFiles=Get-ChildItem -LiteralPath (Join-Path $projectRoot 'grafana\dashboards') -Filter '*.json'
foreach($file in $dashboardFiles){
    $dashboard=Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    foreach($panel in $dashboard.panels){
        foreach($target in $panel.targets){
            if([string]::IsNullOrWhiteSpace($target.rawSql)){continue}
            $queryCount++
            $rawSql=$target.rawSql
            $sql=$rawSql.Replace('$asset','%').Replace('$line','%').Replace('$product','%')
            $body=@{
                from='1767247200000';to='1788238800000';
                queries=@(@{refId='A';datasource=@{uid='atx-postgres';type='grafana-postgresql-datasource'};rawSql=$sql;format=$target.format;intervalMs=3600000;maxDataPoints=2000})
            }|ConvertTo-Json -Depth 10
            try{
                $response=Invoke-RestMethod -Uri "$baseUrl/api/ds/query" -Method Post -ContentType 'application/json' -Body $body
                $result=$response.results.A
                if($result.status -ne 200 -or $result.error){throw "Query status $($result.status): $($result.error)"}
                $frameCount+=@($result.frames).Count
            }catch{$failures+="$($dashboard.title) / $($panel.title): $($_.Exception.Message)"}
            if($rawSql.Contains('$asset')){
                foreach($assetCode in $allowedLine2Assets){
                    $queryCount++
                    $drillSql=$rawSql.Replace('$asset',$assetCode).Replace('$line','%').Replace('$product','%')
                    $drillBody=@{from='1767247200000';to='1788238800000';queries=@(@{refId='A';datasource=@{uid='atx-postgres';type='grafana-postgresql-datasource'};rawSql=$drillSql;format=$target.format;intervalMs=3600000;maxDataPoints=2000})}|ConvertTo-Json -Depth 10
                    try{$drillResponse=Invoke-RestMethod -Uri "$baseUrl/api/ds/query" -Method Post -ContentType 'application/json' -Body $drillBody;$drillResult=$drillResponse.results.A;if($drillResult.status -ne 200 -or $drillResult.error){throw "Query status $($drillResult.status): $($drillResult.error)"};$frameCount+=@($drillResult.frames).Count}catch{$failures+="$($dashboard.title) / $($panel.title) $assetCode drill-down: $($_.Exception.Message)"}
                }
            }
        }
    }
    foreach($variable in $dashboard.templating.list){
        if([string]::IsNullOrWhiteSpace($variable.query)){continue}
        $queryCount++
        $varSql = $variable.query.Replace('$line','%').Replace('$asset','%').Replace('$product','%')
        $body=@{from='1767247200000';to='1788238800000';queries=@(@{refId='A';datasource=@{uid='atx-postgres';type='grafana-postgresql-datasource'};rawSql=$varSql;format='table';intervalMs=3600000;maxDataPoints=2000})}|ConvertTo-Json -Depth 10
        try{$response=Invoke-RestMethod -Uri "$baseUrl/api/ds/query" -Method Post -ContentType 'application/json' -Body $body;$frameCount+=@($response.results.A.frames).Count}catch{$failures+="$($dashboard.title) / variable $($variable.name): $($_.Exception.Message)"}
    }
    if($dashboard.uid -eq 'atx-equipment-oee-detail'){
        $assetVariable=@($dashboard.templating.list|Where-Object name -eq 'asset')
        if($assetVariable.Count -ne 1){$failures+='Equipment OEE Detail / required asset variable missing.'}
        foreach($assetCode in $allowedLine2Assets){if($assetVariable.query -notmatch [regex]::Escape($assetCode)){$failures+="Equipment OEE Detail / asset variable omits $assetCode."}}
    }
    if($dashboard.uid -eq 'atx-production-oee'){
        $linkText=($dashboard|ConvertTo-Json -Depth 100)
        foreach($assetCode in $allowedLine2Assets){if($linkText -notmatch 'atx-equipment-oee-detail'){$failures+="Production OEE / missing Equipment OEE Detail drill-down for $assetCode."}}
        if($linkText -match 'AIR-COMP-001[^\r\n]{0,160}(oee|OEE)' -and $linkText -notmatch 'No OEE'){$failures+='Production OEE / Air-Comp-001 may be included in OEE query.'}
    }
}
if($failures.Count){Write-Output "Grafana query/link validation: $queryCount checked, $($queryCount-$failures.Count) passed, $($failures.Count) failed";$failures|ForEach-Object{Write-Error $_};throw "$($failures.Count) Grafana validations failed."}
Write-Output "Grafana query/link validation: $queryCount checked, $queryCount passed, 0 failed, $frameCount data frames returned"
Write-Output 'GRAFANA VALIDATION PASSED'
