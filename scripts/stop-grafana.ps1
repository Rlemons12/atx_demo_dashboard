$projectRoot=Split-Path -Parent $PSScriptRoot
$pidPath=Join-Path $projectRoot '.grafana\grafana.pid'
$grafanaPid=Get-Content -LiteralPath $pidPath -ErrorAction SilentlyContinue
if($grafanaPid){
    $process=Get-Process -Id $grafanaPid -ErrorAction SilentlyContinue
    if($process){Stop-Process -Id $grafanaPid -ErrorAction Stop; $process.WaitForExit(); Write-Output "Stopped project Grafana PID $grafanaPid."}
    Remove-Item -LiteralPath $pidPath -ErrorAction SilentlyContinue
}else{Write-Output 'Project Grafana is not running.'}
