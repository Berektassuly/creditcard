# ==============================================================================
# ТЕСТОВЫЙ СКРИПТ ДЛЯ ПРОЕКТА CREDITCARD (v4 - СОВМЕСТИМЫЙ И ИСПРАВЛЕННЫЙ)
# ==============================================================================
$ErrorActionPreference = "Stop" # Останавливаем скрипт при любой ошибке

# --- Конфигурация ---
$ExecutableName = "creditcard.exe"
$BrandFileName = "brands.txt"
$IssuerFileName = "issuers.txt"
$global:TotalTests = 0
$global:PassedTests = 0

function Assert-Test {
    param (
        [string]$TestName,
        [scriptblock]$Command,
        [int]$ExpectedExitCode,
        [string]$ExpectedStdout = $null,
        [string]$CheckStderrContains = $null,
        [string]$CheckStdoutContains = $null,
        [string]$CheckStdoutMatches = $null
    )

    $global:TotalTests++
    Write-Host "--- TESTING '$TestName' ---" -ForegroundColor Cyan

    $actualStdout = ""
    $actualStderr = ""
    
    try {
        # Перенаправляем stderr (2) в stdout (1) и сохраняем все в $output
        $output = & $Command 2>&1
    } catch {
        # Отлавливаем ошибки, которые PowerShell генерирует для stderr
        $actualStderr = $_.Exception.Message
    }

    # Разделяем stdout и stderr из вывода
    if ($output) {
       $actualStdout = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`r`n"
       # Дополняем stderr, если он уже был пойман в catch
       $actualStderr += ($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`r`n"
    }
    
    $actualExitCode = $LASTEXITCODE
    $actualStdout = $actualStdout.Trim()
    $actualStderr = $actualStderr.Trim()

    $failures = @()

    if ($actualExitCode -ne $ExpectedExitCode) { $failures += "-> Exit Code: Expected '$ExpectedExitCode', Got '$actualExitCode'" }
    if (($ExpectedStdout -ne $null) -and ($actualStdout -ne $ExpectedStdout)) { $failures += "-> Stdout: Expected '$ExpectedStdout', Got '$actualStdout'" }
    if (($CheckStderrContains -ne $null) -and ($actualStderr -notlike "*$CheckStderrContains*")) { $failures += "-> Stderr should contain '$CheckStderrContains', Got '$actualStderr'" }
    if (($CheckStdoutContains -ne $null) -and ($actualStdout -notlike "*$CheckStdoutContains*")) { $failures += "-> Stdout should contain '$CheckStdoutContains', Got '$actualStdout'" }
    if (($CheckStdoutMatches -ne $null) -and ($actualStdout -notmatch $CheckStdoutMatches)) { $failures += "-> Stdout should match regex '$CheckStdoutMatches', Got '$actualStdout'" }

    if ($failures.Count -gt 0) {
        Write-Host "[FAILURE] Test '$TestName' failed." -ForegroundColor Red
        foreach ($failure in $failures) { Write-Host $failure -ForegroundColor Yellow }
    } else {
        Write-Host "[SUCCESS] Test '$TestName' passed." -ForegroundColor Green
        $global:PassedTests++
    }
    Write-Host ""
}

try {
    Write-Host "--- STAGE 1: SETUP ---" -ForegroundColor Magenta
    # --- ИСПРАВЛЕНИЕ: Используем просто UTF8, совместимый со старыми PowerShell ---
    @"
VISA:4
MASTERCARD:51
MASTERCARD:52
AMEX:34
AMEX:37
"@ | Set-Content $BrandFileName -Encoding UTF8
    @"
Kaspi Gold:440043
Forte Blue:517792
AMEX Gold:3782
"@ | Set-Content $IssuerFileName -Encoding UTF8
    Write-Host "Created '$BrandFileName' and '$IssuerFileName'."

    Write-Host "Building the project..."
    go build -o $ExecutableName .
    Write-Host "Build successful."
    Write-Host ""

    Write-Host "--- STAGE 2: TESTING 'validate' ---" -ForegroundColor Magenta
    Assert-Test -TestName "Validate: Один валидный номер" -Command { & ./$ExecutableName validate "4400430180300003" } -ExpectedExitCode 0 -ExpectedStdout "OK"
    Assert-Test -TestName "Validate: Один невалидный номер" -Command { & ./$ExecutableName validate "4400430180300002" } -ExpectedExitCode 1 -CheckStderrContains "INCORRECT"
    Assert-Test -TestName "Validate: Смешанный ввод" -Command { & ./$ExecutableName validate "4400430180300003" "4400430180300002" } -ExpectedExitCode 1 -ExpectedStdout "OK" -CheckStderrContains "INCORRECT"

    Write-Host "--- STAGE 3: TESTING 'generate' ---" -ForegroundColor Magenta
    Assert-Test -TestName "Generate: Генерация и проверка сортировки" -Command { & ./$ExecutableName generate "440043018030****" } -ExpectedExitCode 0 -CheckStdoutContains "4400430180300003"
    Assert-Test -TestName "Generate: Случайный выбор --pick" -Command { & ./$ExecutableName generate --pick "440043****" } -ExpectedExitCode 0 -CheckStdoutMatches "^\d{16}$"
    
    Write-Host "--- STAGE 4: TESTING 'information' ---" -ForegroundColor Magenta
    $expectedInfoValid = "4400430180300003`r`nCorrect: yes`r`nCard Brand: VISA`r`nCard Issuer: Kaspi Gold".Trim()
    Assert-Test -TestName "Information: Валидный номер" -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "4400430180300003" } -ExpectedExitCode 0 -ExpectedStdout $expectedInfoValid
    $expectedInfoInvalid = "1234567890123`r`nCorrect: no`r`nCard Brand: -`r`nCard Issuer: -".Trim()
    Assert-Test -TestName "Information: Невалидный номер (код выхода 0)" -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "1234567890123" } -ExpectedExitCode 0 -ExpectedStdout $expectedInfoInvalid

    Write-Host "--- STAGE 5: TESTING 'issue' ---" -ForegroundColor Magenta
    Assert-Test -TestName "Issue: AMEX (проверка длины 15)" -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="AMEX Gold" } -ExpectedExitCode 0 -CheckStdoutMatches "^\d{15}$"
    Assert-Test -TestName "Issue: Негативный - конфликт бренда" -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="Kaspi Gold" } -ExpectedExitCode 1 -CheckStderrContains "не подходит для эмитента"

} finally {
    Write-Host "--- STAGE 6: CLEANUP ---" -ForegroundColor Magenta
    Remove-Item $ExecutableName, $BrandFileName, $IssuerFileName -ErrorAction SilentlyContinue
    Write-Host "Removed temporary files."
    Write-Host "----------------------------------" -ForegroundColor Magenta
    Write-Host "TESTING COMPLETE"
    if ($global:TotalTests -gt 0 -and $global:PassedTests -eq $global:TotalTests) {
        Write-Host "RESULT: PASSED ($($global:PassedTests)/$($global:TotalTests))" -ForegroundColor Green
    } else {
        $failed = $global:TotalTests - $global:PassedTests
        Write-Host "RESULT: FAILED ($($failed) failed, $($global:PassedTests) passed, $($global:TotalTests) total)" -ForegroundColor Red
    }
    Write-Host "----------------------------------" -ForegroundColor Magenta
}