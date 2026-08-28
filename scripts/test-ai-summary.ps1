param([int[]]$QuestionNumbers)
# Test AI Maintenance Summary and Grafana LLM Integration
. "$PSScriptRoot\db-common.ps1"
$config = Get-AtxDatabaseConfig

Write-Output "=== 1. Validating Grafana LLM Plugin Health ==="
try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:3001/api/plugins/grafana-llm-app/health" -Method Get
    Write-Output "Status: $($health.status)"
    Write-Output "Version: $($health.details.version)"
    Write-Output "OpenAI Configured: $($health.details.openAI.configured)"
    Write-Output "Base Model OK: $($health.details.openAI.models.base.ok)"
    Write-Output "Large Model OK: $($health.details.openAI.models.large.ok)"
    if (-not $health.details.openAI.configured -or -not $health.details.openAI.models.base.ok) {
        throw "Grafana LLM app is not properly configured or healthy."
    }
}
catch {
    Write-Warning "Could not reach Grafana LLM health endpoint: $_"
}

Write-Output ""
Write-Output "=== 2. Fetching Curated Context from PostgreSQL Views ==="

$contextQuery = @"
SELECT json_build_object(
    'plant_uptime', (SELECT json_agg(t) FROM v_plant_uptime t),
    'line_uptime', (SELECT json_agg(t) FROM v_line_uptime t),
    'downtime_by_asset', (SELECT json_agg(t) FROM (SELECT * FROM v_downtime_by_asset ORDER BY downtime_minutes DESC LIMIT 5) t),
    'repeat_failures', (SELECT json_agg(t) FROM v_repeat_failures t),
    'open_rca_actions', (SELECT json_agg(t) FROM v_open_rca_actions t),
    'rca_history', (SELECT json_agg(t) FROM (SELECT r.rca_number, a.asset_code, r.problem_statement, r.root_cause, r.status, c.action_description, c.completed_date FROM rca_events r JOIN work_orders w USING(work_order_id) JOIN assets a USING(asset_id) LEFT JOIN corrective_actions c USING(rca_event_id)) t),
    'filler_201_monthly_failures', (SELECT json_agg(t) FROM (SELECT date_trunc('month', failure_time)::date AS month, count(*) as failure_count FROM failure_events WHERE asset_id = (SELECT asset_id FROM assets WHERE asset_code = 'FILLER-201') GROUP BY 1 ORDER BY 1) t),
    'shared_asset_risk', (SELECT json_agg(t) FROM v_shared_asset_risk t),
    'pm_compliance', (SELECT json_agg(t) FROM v_pm_compliance t),
    'critical_spare_availability', (SELECT json_agg(t) FROM v_critical_spare_availability t),
    'sanitation_risk', (SELECT json_agg(t) FROM v_sanitation_maintenance_risk t),
    'air_comp_condition', (SELECT json_agg(t) FROM (SELECT measured_at, measurement_type, numeric_value, unit, warning_threshold, alarm_threshold, notes FROM condition_measurements WHERE asset_id = (SELECT asset_id FROM assets WHERE asset_code = 'AIR-COMP-001') ORDER BY measured_at ASC) t),
    'current_lots', (SELECT json_agg(t) FROM v_current_production_lots t),
    'upcoming_lots', (SELECT json_agg(t) FROM (SELECT * FROM v_upcoming_production_lots LIMIT 5) t),
    'legacy_line_oee_monthly_for_line1_history_only', (SELECT json_agg(t) FROM v_line_oee_monthly t),
    'oee_loss_by_category', (SELECT json_agg(t) FROM (SELECT * FROM v_oee_loss_by_category WHERE period = '2026-08-01') t),
    'filler201_oee_rca', (SELECT json_agg(t) FROM v_filler201_oee_before_after_rca t),
    'staffing_coverage', (SELECT json_agg(t) FROM v_shift_staffing_coverage t),
    'line2_oee', (SELECT json_agg(t) FROM v_line2_oee_summary t),
    'line2_equipment_oee', (SELECT json_agg(t) FROM v_equipment_oee_summary t),
    'line2_equipment_losses', (SELECT json_agg(t) FROM v_equipment_loss_summary t),
    'filler201_stop_loss_rca', (SELECT json_agg(t) FROM v_filler201_stop_loss_before_after_rca t),
    'filler201_stop_trace', (SELECT json_agg(t) FROM (SELECT primary_stop_reason_code,stop_reason,loss_category,responsible_function,maintenance_related,reason_source,reason_confidence,downtime_reason,work_order_number,failure_mode,rca_number,root_cause,action_description,pm_code,pm_revision FROM v_filler201_stop_loss_detail WHERE primary_stop_reason_code='PHOTOEYE_FAULT' LIMIT 20) t),
    'line2_sensor_definitions', (SELECT json_agg(t) FROM (SELECT a.asset_code,s.sensor_code,s.functional_class,s.engineering_unit,s.description FROM equipment_sensors s JOIN assets a USING(asset_id) ORDER BY a.asset_code,s.sensor_code) t),
    'plant_operations_rollup', (SELECT json_agg(t) FROM v_plant_operations_oee_rollup t)
)::text;
"@

$env:PGPASSWORD = $config.Password
$contextJson = & $config.Psql -X -t -A -h $config.Host -p $config.Port -U $config.User -d $config.Database -c $contextQuery
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if (-not $contextJson) {
    throw "Failed to retrieve context JSON from database views."
}
Write-Output "Context retrieved successfully ($( $contextJson.Length ) bytes)."

Write-Output ""
Write-Output "=== 3. Testing Curated AI Summary Questions ==="

$apiKey = $config.OpenAiApiKey
if (-not $apiKey) {
    throw "OpenAI API key is missing from environment."
}

$questions = @(
    @{
        Number = 1
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "What is keeping plant uptime below target?"
    },
    @{
        Number = 2
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "Why is Line 2 OEE lower than Line 1?"
    },
    @{
        Number = 3
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "Which OEE component is driving the largest loss?"
    },
    @{
        Number = 4
        ModelType = "LARGE"
        Model = "gpt-4o"
        Question = "Did Filler-201 improve after RCA and PM revision?"
    },
    @{
        Number = 5
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "What lot is currently running on Line 1?"
    },
    @{
        Number = 6
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "What lot runs next on Line 2?"
    },
    @{
        Number = 7
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "Is staffing coverage adequate for the current shift?"
    },
    @{
        Number = 8
        ModelType = "LARGE"
        Model = "gpt-4o"
        Question = "Is Blender-001 creating future production risk?"
    },
    @{
        Number = 9
        ModelType = "BASE"
        Model = "gpt-4o-mini"
        Question = "Why is Air-Comp-001 a predictive maintenance concern?"
    },
    @{
        Number = 10
        ModelType = "LARGE"
        Model = "gpt-4o"
        Question = "What should Operations focus on this week?"
    },
    @{ Number = 11; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "What is Line 2 OEE?"; ExpectedPattern = "74\.34" },
    @{ Number = 12; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "Which Line 2 machine has the worst Equipment OEE?"; ExpectedPattern = "Mixer-201|MIXER-201" },
    @{ Number = 13; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "What is driving Filler-201 stop loss? Rank primary stop reasons by total minutes and distinguish unclassified loss from confirmed photoeye maintenance loss."; ExpectedPattern = "Unclassified" },
    @{ Number = 14; ModelType = "LARGE"; Model = "gpt-4o"; Question = "Across all Filler-201 unscheduled stop reasons combined, how much total production opportunity was lost? Copy the exact stop_loss_opportunity_units field from FILLER-201 in line2_equipment_oee. Do not calculate, round, include planned changeover, or substitute a single reason."; ExpectedPattern = "1,?907,?173(\.49)?" },
    @{ Number = 15; ModelType = "LARGE"; Model = "gpt-4o"; Question = "Is Filler-201 losing more through downtime, speed, or quality?" },
    @{ Number = 16; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "What sensors support the Filler-201 Equipment OEE calculation?" },
    @{ Number = 17; ModelType = "LARGE"; Model = "gpt-4o"; Question = "Did Filler-201 unscheduled stop loss improve after the RCA? Keep planned changeover separate."; ExpectedPattern = "14,?550" },
    @{ Number = 18; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "What is Conveyor-201's largest current loss?" },
    @{ Number = 19; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "What is the difference between Asset Utilization and OEE in this demo?" },
    @{ Number = 20; ModelType = "BASE"; Model = "gpt-4o-mini"; Question = "Why is Air-Comp-001 excluded from OEE?"; ExpectedPattern = "shared utility|utility" }
)

if ($QuestionNumbers) {
    $questions = @($questions | Where-Object { $_.Number -in $QuestionNumbers })
    if (-not $questions.Count) { throw 'No requested AI question numbers were found.' }
}

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$systemPrompt = @"
You are the ATX Plant Maintenance & Reliability AI Assistant integrated into Grafana.
Your role is to interpret maintenance KPIs, downtime history, PM compliance, RCA findings, and operational risk.
STRICT SAFETY & DATA RULES:
1. Base all statements strictly on the provided JSON context from PostgreSQL views.
2. Distinguish fact from inference.
3. NEVER invent KPI values, work orders, failures, RCA findings, or spare shortages.
4. Do NOT issue unsafe maintenance instructions or suggest altering database records.
5. Provide concise, executive-level summaries suitable for operations and maintenance leaders.
6. Use the terms Asset Utilization, Equipment OEE, Line OEE, and Loss Analysis. Do not call them OEE1, OEE2, or OEE3.
7. Asset Utilization is Scheduled Production Time / Total Calendar Time. OEE is Availability x Performance x Quality. Loss Analysis is explanatory and is not multiplied into OEE.
8. Air-Comp-001 is a shared utility and must never be assigned piece-rate OEE.
9. For Line 2 and its four detailed machines, use only line2_oee and line2_equipment_oee as the authoritative KPI values. Legacy views are historical context and must not override Milestone 4 values.
"@

$aiFailures = @()
foreach ($q in $questions) {
    Write-Output "--- Question $($q.Number) ($($q.ModelType) model: $($q.Model)) ---"
    Write-Output "Q: $($q.Question)"

    $body = @{
        model = $q.Model
        messages = @(
            @{ role = "system"; content = $systemPrompt },
            @{ role = "user"; content = "Database Context:`n$contextJson`n`nQuestion: $($q.Question)" }
        )
        temperature = 0.2
        max_tokens = 500
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
    $answer = $response.choices[0].message.content
    Write-Output "A: $answer"
    Write-Output ""
    if ($q.ExpectedPattern -and $answer -notmatch $q.ExpectedPattern) {
        $aiFailures += "Question $($q.Number) did not contain required curated evidence pattern '$($q.ExpectedPattern)'."
    }
}

if ($aiFailures.Count) {
    $aiFailures | ForEach-Object { Write-Error $_ }
    throw "AI validation: $($questions.Count) checked, $($questions.Count-$aiFailures.Count) passed, $($aiFailures.Count) failed."
}
Write-Output "AI validation: $($questions.Count) checked, $($questions.Count) passed, 0 failed."
