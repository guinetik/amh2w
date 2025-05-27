<#
.SYNOPSIS
Windows Event Log viewer that generates interactive HTML reports.

.DESCRIPTION
Analyzes Windows Event Logs and generates a comprehensive HTML report with filtering options.
Supports multiple log types and customizable time ranges.

.NOTES
File: all/my/homies/hate/windows/eventlog.ps1
CommandPath: all my homies hate windows eventlog [logname] [hours]

.EXAMPLE
all my homies hate windows eventlog
Displays latest events from all major logs in HTML format.

.EXAMPLE
all my homies hate windows eventlog System 24
Shows System log events from the last 24 hours.

.EXAMPLE
all my homies hate windows eventlog Application 168
Shows Application log events from the last week (168 hours).
#>

<#
.SYNOPSIS
Generates an interactive HTML report of Windows Event Logs.

.DESCRIPTION
Analyzes specified Windows Event Logs and creates a comprehensive HTML report
with filtering, sorting, and summary statistics. Opens automatically in browser.

.PARAMETER LogName
The event log to analyze: 'All', 'System', 'Application', 'Security', or 'Setup'.
Default: 'All' (combines System, Application, and Security logs)

.PARAMETER Hours
Number of hours to look back from current time. Default: 24 hours.
Use 0 to get all available events (warning: may be slow).

.OUTPUTS
Returns an Ok or Err object according to the AMH2W result pattern.

.EXAMPLE
eventlog
eventlog System 48
eventlog Application 0
eventlog All 72
#>
function eventlog {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("All", "System", "Application", "Security", "Setup")]
        [string]$LogName = "All",
        
        [Parameter(Position = 1)]
        [ValidateRange(0, 8760)]
        [int]$Hours = 24
    )

    try {
        Log-Info "Starting Windows Event Log analysis..."
        Log-Info "Log: $LogName | Time range: $(if($Hours -eq 0) { 'All events' } else { "Last $Hours hours" })"

        # Calculate start time
        $startTime = if ($Hours -eq 0) {
            [DateTime]::MinValue
        } else {
            (Get-Date).AddHours(-$Hours)
        }

        # Determine which logs to query
        $logsToQuery = switch ($LogName) {
            "All" { @("System", "Application", "Security") }
            default { @($LogName) }
        }

        # Initialize results container
        $eventData = [PSCustomObject]@{
            LogsAnalyzed = $logsToQuery -join ", "
            TimeRange = if ($Hours -eq 0) { "All available events" } else { "Last $Hours hours" }
            StartTime = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
            EndTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            TotalEvents = 0
            CriticalCount = 0
            ErrorCount = 0
            WarningCount = 0
            InformationCount = 0
            VerboseCount = 0
            Events = @()
            TopSources = @()
            EventsByHour = @()
        }

        # Collect events from each log
        $allEvents = @()
        $totalProcessed = 0
        
        foreach ($log in $logsToQuery) {
            Write-Progress -Activity "Analyzing Event Logs" -Status "Processing $log log..." -PercentComplete (($logsToQuery.IndexOf($log) / $logsToQuery.Count) * 100)
            
            try {
                Log-Info "Querying $log event log..."
                
                # Build filter
                $filterHash = @{
                    LogName = $log
                }
                
                if ($Hours -gt 0) {
                    $filterHash.StartTime = $startTime
                }
                
                # Get events
                $events = Get-WinEvent -FilterHashtable $filterHash -ErrorAction Stop
                
                if ($events) {
                    $allEvents += $events
                    $totalProcessed += $events.Count
                    Log-Success "Retrieved $($events.Count) events from $log"
                } else {
                    Log-Info "No events found in $log for the specified time range"
                }
            }
            catch [System.Exception] {
                if ($_.Exception.Message -like "*access is denied*") {
                    Log-Warning "Access denied to $log log. Try running as Administrator."
                } elseif ($_.Exception.Message -like "*No events were found*") {
                    Log-Info "No events found in $log log"
                } else {
                    Log-Warning "Could not read $log log: $_"
                }
            }
        }

        if ($allEvents.Count -eq 0) {
            Log-Warning "No events found in the specified time range"
            $eventData.Events = @([PSCustomObject]@{
                TimeCreated = "N/A"
                Id = 0
                Level = "Info"
                LevelDisplayName = "Information"
                LogName = "N/A"
                Source = "Event Log Analyzer"
                Message = "No events found in the specified time range"
                MachineName = $env:COMPUTERNAME
            })
        } else {
            Log-Info "Processing $($allEvents.Count) total events..."
            
            # Sort events by time (newest first)
            $sortedEvents = $allEvents | Sort-Object TimeCreated -Descending
            
            # Process events and gather statistics
            $eventList = @()
            $sourceCount = @{}
            $hourlyCount = @{}
            
            foreach ($event in $sortedEvents) {
                # Add to event list (limit to 1000 for performance)
                if ($eventList.Count -lt 10000) {
                    $eventList += [PSCustomObject]@{
                        TimeCreated = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                        Id = $event.Id
                        Level = $event.Level
                        LevelDisplayName = $event.LevelDisplayName
                        LogName = $event.LogName
                        Source = $event.ProviderName
                        Message = if ($event.Message) { 
                            ($event.Message -split "`n")[0].Trim().Substring(0, [Math]::Min(200, ($event.Message -split "`n")[0].Trim().Length)) 
                        } else { 
                            "No message available" 
                        }
                        MachineName = $event.MachineName
                    }
                }
                
                # Count by level
                switch ($event.Level) {
                    1 { $eventData.CriticalCount++ }
                    2 { $eventData.ErrorCount++ }
                    3 { $eventData.WarningCount++ }
                    4 { $eventData.InformationCount++ }
                    5 { $eventData.VerboseCount++ }
                }
                
                # Count by source
                if ($sourceCount.ContainsKey($event.ProviderName)) {
                    $sourceCount[$event.ProviderName]++
                } else {
                    $sourceCount[$event.ProviderName] = 1
                }
                
                # Count by hour
                $hourKey = $event.TimeCreated.ToString("yyyy-MM-dd HH:00")
                if ($hourlyCount.ContainsKey($hourKey)) {
                    $hourlyCount[$hourKey]++
                } else {
                    $hourlyCount[$hourKey] = 1
                }
            }
            
            $eventData.Events = $eventList
            $eventData.TotalEvents = $allEvents.Count
            
            # Get top 10 event sources
            $eventData.TopSources = $sourceCount.GetEnumerator() | 
                Sort-Object Value -Descending | 
                Select-Object -First 10 | 
                ForEach-Object {
                    [PSCustomObject]@{
                        Source = $_.Key
                        Count = $_.Value
                    }
                }
            
            # Prepare hourly data for chart
            $eventData.EventsByHour = $hourlyCount.GetEnumerator() | 
                Sort-Object Key | 
                ForEach-Object {
                    [PSCustomObject]@{
                        Hour = $_.Key
                        Count = $_.Value
                    }
                }
            
            Log-Success "Event analysis complete: $($eventData.TotalEvents) events processed"
        }

        Write-Progress -Activity "Analyzing Event Logs" -Status "Generating HTML report..." -PercentComplete 90

        # Generate HTML report
        Log-Info "Generating HTML report..."
        $htmlFile = "$HOME\Desktop\EventLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $htmlContent = Generate-EventLogHtml -EventData $eventData
        $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8
        
        Write-Host "`n📋 Windows Event Log Analysis Complete!" -ForegroundColor Green
        Write-Host "HTML report saved to: $htmlFile" -ForegroundColor Yellow
        
        # Open in browser using AMH2W browser command
        try {
            $fileUri = "file:///" + $htmlFile.Replace("\", "/")
            Log-Info "Opening HTML report in browser: $fileUri"
            
            # Call the AMH2W browser command
            $browserResult = & "all" "my" "browser" $fileUri
            
            if ($browserResult -and $browserResult.ok) {
                Log-Success "HTML report opened in browser using AMH2W"
            } else {
                # Fallback to traditional method
                Start-Process $htmlFile
                Log-Success "HTML report opened using system default"
            }
        }
        catch {
            Log-Warning "Could not open HTML report automatically: $_"
            Write-Host "You can manually open the report at: $htmlFile" -ForegroundColor Yellow
        }
        
        Write-Progress -Activity "Analyzing Event Logs" -Completed
        
        return Ok -Value $eventData -Message "Event log analysis completed - HTML report saved to $htmlFile and opened in browser"
    }
    catch {
        Log-Error "Event log analysis failed: $_"
        return Err -Message "Event log analysis failed: $_"
    }
}

<#
.SYNOPSIS
Generates an HTML report for event log analysis.

.DESCRIPTION
Internal function to generate a comprehensive HTML report with interactive features.

.PARAMETER EventData
The event data object containing all analysis results.

.OUTPUTS
HTML content as a string.
#>
function Generate-EventLogHtml {
    param([PSCustomObject]$EventData)
    
    # Prepare chart data
    $chartLabels = ($EventData.EventsByHour | ForEach-Object { "'$($_.Hour)'" }) -join ", "
    $chartData = ($EventData.EventsByHour | ForEach-Object { $_.Count }) -join ", "
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Windows Event Log Analysis - $($EventData.GeneratedAt)</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: #333;
            min-height: 100vh;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(45deg, #2c3e50, #34495e);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        .content {
            padding: 30px;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-top: 3px solid #007bff;
        }
        .summary-card.critical {
            border-top-color: #dc3545;
        }
        .summary-card.error {
            border-top-color: #fd7e14;
        }
        .summary-card.warning {
            border-top-color: #ffc107;
        }
        .summary-card.info {
            border-top-color: #17a2b8;
        }
        .summary-card.success {
            border-top-color: #28a745;
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            color: #2c3e50;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .summary-card .value {
            font-size: 2em;
            font-weight: bold;
        }
        .summary-card.critical .value {
            color: #dc3545;
        }
        .summary-card.error .value {
            color: #fd7e14;
        }
        .summary-card.warning .value {
            color: #ffc107;
        }
        .summary-card.info .value {
            color: #17a2b8;
        }
        .summary-card.success .value {
            color: #28a745;
        }
        .section {
            margin-bottom: 40px;
            background: #f8f9fa;
            border-radius: 8px;
            padding: 25px;
            border-left: 5px solid #007bff;
        }
        .section h2 {
            color: #2c3e50;
            margin-top: 0;
            font-size: 1.5em;
            display: flex;
            align-items: center;
        }
        .section h2::before {
            margin-right: 10px;
            font-size: 1.2em;
        }
        .filter-section h2::before { content: "🔍"; }
        .chart-section h2::before { content: "📊"; }
        .events-section h2::before { content: "📋"; }
        .sources-section h2::before { content: "📌"; }
        .filters {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .filter-group label {
            font-weight: 600;
            color: #495057;
            font-size: 0.9em;
        }
        .filter-group input, .filter-group select {
            padding: 8px 12px;
            border: 1px solid #ced4da;
            border-radius: 4px;
            font-size: 14px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
            border-radius: 6px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #007bff;
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.9em;
            letter-spacing: 0.5px;
            cursor: pointer;
            user-select: none;
        }
        th:hover {
            background: #0056b3;
        }
        tr:hover {
            background: #f5f5f5;
        }
        .level-critical { 
            background-color: #dc3545; 
            color: white; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-weight: bold; 
            font-size: 0.85em;
        }
        .level-error { 
            background-color: #fd7e14; 
            color: white; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-weight: bold; 
            font-size: 0.85em;
        }
        .level-warning { 
            background-color: #ffc107; 
            color: #212529; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-weight: bold; 
            font-size: 0.85em;
        }
        .level-information { 
            background-color: #17a2b8; 
            color: white; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-weight: bold; 
            font-size: 0.85em;
        }
        .level-verbose { 
            background-color: #6c757d; 
            color: white; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-weight: bold; 
            font-size: 0.85em;
        }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
            font-size: 0.9em;
        }
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        canvas {
            max-width: 100%;
            max-height: 300px;
        }
        .message-cell {
            max-width: 400px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .no-events {
            text-align: center;
            padding: 40px;
            color: #6c757d;
            font-size: 1.1em;
        }
        @media (max-width: 768px) {
            .filters {
                flex-direction: column;
            }
            .summary-grid {
                grid-template-columns: 1fr;
            }
            .message-cell {
                max-width: 200px;
            }
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 Windows Event Log Analysis</h1>
            <p>Generated on $($EventData.GeneratedAt) | Logs: $($EventData.LogsAnalyzed) | Time Range: $($EventData.TimeRange)</p>
        </div>
        
        <div class="content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Events</h3>
                    <div class="value">$($EventData.TotalEvents)</div>
                </div>
                <div class="summary-card critical">
                    <h3>Critical</h3>
                    <div class="value">$($EventData.CriticalCount)</div>
                </div>
                <div class="summary-card error">
                    <h3>Errors</h3>
                    <div class="value">$($EventData.ErrorCount)</div>
                </div>
                <div class="summary-card warning">
                    <h3>Warnings</h3>
                    <div class="value">$($EventData.WarningCount)</div>
                </div>
                <div class="summary-card info">
                    <h3>Information</h3>
                    <div class="value">$($EventData.InformationCount)</div>
                </div>
                <div class="summary-card success">
                    <h3>Verbose</h3>
                    <div class="value">$($EventData.VerboseCount)</div>
                </div>
            </div>

            $(if ($EventData.EventsByHour.Count -gt 0) {
            @"
            <div class="section chart-section">
                <h2>Event Timeline</h2>
                <div class="chart-container">
                    <canvas id="eventsChart"></canvas>
                </div>
            </div>
"@
            })

            <div class="section filter-section">
                <h2>Filter Events</h2>
                <div class="filters">
                    <div class="filter-group">
                        <label for="searchInput">Search:</label>
                        <input type="text" id="searchInput" placeholder="Search in messages...">
                    </div>
                    <div class="filter-group">
                        <label for="levelFilter">Level:</label>
                        <select id="levelFilter">
                            <option value="">All Levels</option>
                            <option value="Critical">Critical</option>
                            <option value="Error">Error</option>
                            <option value="Warning">Warning</option>
                            <option value="Information">Information</option>
                            <option value="Verbose">Verbose</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label for="logFilter">Log:</label>
                        <select id="logFilter">
                            <option value="">All Logs</option>
                            <option value="System">System</option>
                            <option value="Application">Application</option>
                            <option value="Security">Security</option>
                            <option value="Setup">Setup</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label for="sourceFilter">Source:</label>
                        <select id="sourceFilter">
                            <option value="">All Sources</option>
                            $(foreach ($source in ($EventData.Events | Select-Object -ExpandProperty Source -Unique | Sort-Object)) {
                                "<option value='$source'>$source</option>"
                            })
                        </select>
                    </div>
                </div>
            </div>

            <div class="section events-section">
                <h2>Event Details (Showing up to 1000 most recent)</h2>
                $(if ($EventData.Events.Count -eq 0 -or ($EventData.Events.Count -eq 1 -and $EventData.Events[0].Message -eq "No events found in the specified time range")) {
                    "<div class='no-events'>No events found in the specified time range</div>"
                } else {
                @"
                <table id="eventsTable">
                    <thead>
                        <tr>
                            <th onclick="sortTable(0)">Time ↕</th>
                            <th onclick="sortTable(1)">ID ↕</th>
                            <th onclick="sortTable(2)">Level ↕</th>
                            <th onclick="sortTable(3)">Log ↕</th>
                            <th onclick="sortTable(4)">Source ↕</th>
                            <th>Message</th>
                        </tr>
                    </thead>
                    <tbody>
$(
                    foreach ($event in $EventData.Events) {
                        $levelClass = switch ($event.LevelDisplayName) {
                            "Critical" { "level-critical" }
                            "Error" { "level-error" }
                            "Warning" { "level-warning" }
                            "Information" { "level-information" }
                            "Verbose" { "level-verbose" }
                            default { "" }
                        }
                        @"
                        <tr>
                            <td>$($event.TimeCreated)</td>
                            <td>$($event.Id)</td>
                            <td><span class="$levelClass">$($event.LevelDisplayName)</span></td>
                            <td>$($event.LogName)</td>
                            <td>$($event.Source)</td>
                            <td class="message-cell" title="$([System.Web.HttpUtility]::HtmlEncode($event.Message))">$([System.Web.HttpUtility]::HtmlEncode($event.Message))</td>
                        </tr>
"@
                    }
)
                    </tbody>
                </table>
"@
                })
            </div>

            $(if ($EventData.TopSources.Count -gt 0) {
            @"
            <div class="section sources-section">
                <h2>Top Event Sources</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Source</th>
                            <th>Event Count</th>
                        </tr>
                    </thead>
                    <tbody>
$(
                foreach ($source in $EventData.TopSources) {
                    @"
                        <tr>
                            <td>$($source.Source)</td>
                            <td>$($source.Count)</td>
                        </tr>
"@
                }
)
                    </tbody>
                </table>
            </div>
"@
            })
        </div>
        
        <div class="footer">
            <p>Generated by AMH2W Event Log Analyzer | $($EventData.GeneratedAt)</p>
            <p>This report provides a comprehensive analysis of Windows Event Logs</p>
        </div>
    </div>

    <script>
        // Initialize chart if data exists
        $(if ($EventData.EventsByHour.Count -gt 0) {
        @"
        const ctx = document.getElementById('eventsChart').getContext('2d');
        const eventsChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$chartLabels],
                datasets: [{
                    label: 'Events per Hour',
                    data: [$chartData],
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
"@
        })

        // Filter functionality
        function filterTable() {
            const searchValue = document.getElementById('searchInput').value.toLowerCase();
            const levelValue = document.getElementById('levelFilter').value;
            const logValue = document.getElementById('logFilter').value;
            const sourceValue = document.getElementById('sourceFilter').value;
            
            const table = document.getElementById('eventsTable');
            if (!table) return;
            
            const rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i];
                const cells = row.getElementsByTagName('td');
                
                const message = cells[5].textContent.toLowerCase();
                const level = cells[2].textContent;
                const log = cells[3].textContent;
                const source = cells[4].textContent;
                
                const matchesSearch = searchValue === '' || message.includes(searchValue);
                const matchesLevel = levelValue === '' || level === levelValue;
                const matchesLog = logValue === '' || log === logValue;
                const matchesSource = sourceValue === '' || source === sourceValue;
                
                if (matchesSearch && matchesLevel && matchesLog && matchesSource) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            }
        }

        // Sort functionality
        let sortDirection = {};
        
        function sortTable(columnIndex) {
            const table = document.getElementById('eventsTable');
            if (!table) return;
            
            const tbody = table.getElementsByTagName('tbody')[0];
            const rows = Array.from(tbody.getElementsByTagName('tr'));
            
            // Toggle sort direction
            sortDirection[columnIndex] = !sortDirection[columnIndex];
            
            rows.sort((a, b) => {
                const aValue = a.getElementsByTagName('td')[columnIndex].textContent;
                const bValue = b.getElementsByTagName('td')[columnIndex].textContent;
                
                // Handle numeric sorting for ID column
                if (columnIndex === 1) {
                    return sortDirection[columnIndex] ? 
                        parseInt(aValue) - parseInt(bValue) : 
                        parseInt(bValue) - parseInt(aValue);
                }
                
                // Text sorting for other columns
                if (sortDirection[columnIndex]) {
                    return aValue.localeCompare(bValue);
                } else {
                    return bValue.localeCompare(aValue);
                }
            });
            
            // Re-append sorted rows
            rows.forEach(row => tbody.appendChild(row));
        }

        // Attach event listeners
        document.getElementById('searchInput').addEventListener('input', filterTable);
        document.getElementById('levelFilter').addEventListener('change', filterTable);
        document.getElementById('logFilter').addEventListener('change', filterTable);
        document.getElementById('sourceFilter').addEventListener('change', filterTable);
    </script>
</body>
</html>
"@
    
    return $html
}