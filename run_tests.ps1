# ==============================================================================
# ТЕСТОВЫЙ СКРИПТ ДЛЯ ПРОЕКТА CREDITCARD (v3 - ИСПРАВЛЕННЫЙ)
# ==============================================================================

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

    # --- ИСПРАВЛЕНИЕ ЗДЕСЬ: Перенаправляем stderr (2) в stdout (1) и обрабатываем как единый поток текста ---
    $output = & $Command 2>&1
    $actualExitCode = $LASTEXITCODE

    $actualStdout = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`r`n"
    $actualStderr = ($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`r`n"
    
    $actualStdout = $actualStdout.Trim()
    $actualStderr = $actualStderr.Trim()
    # --- КОНЕЦ ИСПРАВЛЕНИЯ ---

    $conditionsMet = @()
    $failures = @()

    $exitCodeMatch = ($actualExitCode -eq $ExpectedExitCode)
    $conditionsMet += $exitCodeMatch
    if (-not $exitCodeMatch) { $failures += "-> Exit Code: Expected '$ExpectedExitCode', Got '$actualExitCode'" }

    if ($ExpectedStdout -ne $null) {
        $stdoutMatch = ($actualStdout -eq $ExpectedStdout)
        $conditionsMet += $stdoutMatch
        if (-not $stdoutMatch) { $failures += "-> Stdout: Expected '$ExpectedStdout', Got '$actualStdout'" }
    }

    if ($CheckStderrContains -ne $null) {
        $stderrContainsMatch = ($actualStderr -like "*$CheckStderrContains*")
        $conditionsMet += $stderrContainsMatch
        if (-not $stderrContainsMatch) { $failures += "-> Stderr should contain '$CheckStderrContains', Got '$actualStderr'" }
    }
    
    if ($CheckStdoutContains -ne $null) {
        $stdoutContainsMatch = ($actualStdout -like "*$CheckStdoutContains*")
        $conditionsMet += $stdoutContainsMatch
        if (-not $stdoutContainsMatch) { $failures += "-> Stdout should contain '$CheckStdoutContains', Got '$actualStdout'" }
    }

    if ($CheckStdoutMatches -ne $null) {
        $stdoutRegexMatch = ($actualStdout -match $CheckStdoutMatches)
        $conditionsMet += $stdoutRegexMatch
        if (-not $stdoutRegexMatch) { $failures += "-> Stdout should match regex '$CheckStdoutMatches', Got '$actualStdout'" }
    }

    if ($conditionsMet -contains $false) {
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
    @"
VISA:4
MASTERCARD:51
MASTERCARD:52
MASTERCARD:53
MASTERCARD:54
MASTERCARD:55
AMEX:34
AMEX:37
"@ | Set-Content $BrandFileName -Encoding utf8NoBOM # Используем utf8NoBOM для чистоты
    @"
Kaspi Gold:440043
Forte Black:404243
Forte Blue:517792
Halyk Bonus:440563
Jusan Pay:539545
AMEX Gold:3782
"@ | Set-Content $IssuerFileName -Encoding utf8NoBOM # Используем utf8NoBOM для чистоты
    Write-Host "Created '$BrandFileName' and '$IssuerFileName'."

    Write-Host "Building the project..."
    go build -o $ExecutableName .
    if ($LASTEXITCODE -ne 0) { throw "Build failed!" }
    Write-Host "Build successful."
    Write-Host ""

    Write-Host "--- STAGE 2: TESTING 'validate' ---" -ForegroundColor Magenta
    Assert-Test -TestName "Validate: Один валидный номер" -Command { & ./$ExecutableName validate "4400430180300003" } -ExpectedExitCode 0 -ExpectedStdout "OK"
    Assert-Test -TestName "Validate: Один невалидный номер" -Command { & ./$ExecutableName validate "4400430180300002" } -ExpectedExitCode 1 -CheckStderrContains "INCORRECT"
    Assert-Test -TestName "Validate: Смешанный ввод" -Command { & ./$ExecutableName validate "4400430180300003" "4400430180300002" } -ExpectedExitCode 1 -ExpectedStdout "OK" -CheckStderrContains "INCORRECT"
    Assert-Test -TestName "Validate: Чтение из stdin" -Command { "4400430180300003 4400430180300011" | & ./$ExecutableName validate --stdin } -ExpectedExitCode 0 -ExpectedStdout "OK`r`nOK"
    Assert-Test -TestName "Validate: Негативный - номер короче 13" -Command { & ./$ExecutableName validate "123456789012" } -ExpectedExitCode 1 -CheckStderrContains "INCORRECT"

    Write-Host "--- STAGE 3: TESTING 'generate' ---" -ForegroundColor Magenta
    # --- ИСПРАВЛЕНИЕ ЗДЕСЬ: Используем валидное количество звездочек (4) ---
    Assert-Test -TestName "Generate: Генерация и проверка сортировки" -Command { & ./$ExecutableName generate "440043018030****" } -ExpectedExitCode 0 -CheckStdoutContains "4400430180300003"
    Assert-Test -TestName "Generate: Случайный выбор --pick" -Command { & ./$ExecutableName generate --pick "440043****" } -ExpectedExitCode 0 -CheckStdoutMatches "^\d{16}$"
    # --- КОНЕЦ ИСПРАВЛЕНИЯ ---
    Assert-Test -TestName "Generate: Негативный - больше 4 звездочек" -Command { & ./$ExecutableName generate "440043*****" } -ExpectedExitCode 1 -CheckStderrContains "количество '*' должно быть от 1 до 4"
    Assert-Test -TestName "Generate: Негативный - звезды не в конце" -Command { & ./$ExecutableName generate "44**43" } -ExpectedExitCode 1 -CheckStderrContains "символы '*' должны находиться в конце шаблона"

    Write-Host "--- STAGE 4: TESTING 'information' ---" -ForegroundColor Magenta
    $expectedInfoValid = "4400430180300003`r`nCorrect: yes`r`nCard Brand: VISA`r`nCard Issuer: Kaspi Gold".Trim()
    Assert-Test -TestName "Information: Валидный номер" -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "4400430180300003" } -ExpectedExitCode 0 -ExpectedStdout $expectedInfoValid
    $expectedInfoInvalid = "1234567890123`r`nCorrect: no`r`nCard Brand: -`r`nCard Issuer: -".Trim()
    # --- ИСПРАВЛЕНИЕ ЗДЕСЬ: Тест ожидает код выхода 0, согласно ТЗ из скриншота ---
    Assert-Test -TestName "Information: Невалидный номер (код выхода 0)" -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "1234567890123" } -ExpectedExitCode 0 -ExpectedStdout $expectedInfoInvalid
    Assert-Test -TestName "Information: Негативный - файл не найден" -Command { & ./$ExecutableName information --brands=nonexistent.txt --issuers=$IssuerFileName "1" } -ExpectedExitCode 1 -CheckStderrContains "ошибка открытия файла"

    Write-Host "--- STAGE 5: TESTING 'issue' ---" -ForegroundColor Magenta
    $global:TotalTests++
    Write-Host "--- TESTING 'Issue: Генерация и валидация VISA/Kaspi Gold' ---" -ForegroundColor Cyan
    # --- ИСПРАВЛЕНИЕ ЗДЕСЬ: Оборачиваем вызов, чтобы избежать падения на null ---
    $issuedVisa = "$(& ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=VISA --issuer='Kaspi Gold' 2>&1)".Trim()
    if (($LASTEXITCODE -eq 0) -and ($issuedVisa -match "^440043\d{10}$")) {
        $validationResult = "$($issuedVisa | & ./$ExecutableName validate --stdin 2>&1)".Trim()
        if ($validationResult -eq "OK") {
            Write-Host "[SUCCESS] Test 'Issue: Генерация и валидация VISA/Kaspi Gold' passed." -ForegroundColor Green; $global:PassedTests++
        } else { Write-Host "[FAILURE] Test ... failed. Reason: Issued number '$issuedVisa' failed validation." -ForegroundColor Red }
    } else { Write-Host "[FAILURE] Test ... failed. Reason: Command failed or output '$issuedVisa' has wrong prefix/length." -ForegroundColor Red }
    Write-Host ""
    # --- КОНЕЦ ИСПРАВЛЕНИЯ ---
    Assert-Test -TestName "Issue: AMEX (проверка длины 15)" -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="AMEX Gold" } -ExpectedExitCode 0 -CheckStdoutMatches "^\d{15}$"
    Assert-Test -TestName "Issue: Негативный - конфликт бренда и эмитента" -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="Kaspi Gold" } -ExpectedExitCode 1 -CheckStderrContains "не подходит для эмитента"
}
finally {
    Write-Host "--- STAGE 6: CLEANUP ---" -ForegroundColor Magenta
    Remove-Item $ExecutableName, $BrandFileName, $IssuerFileName -ErrorAction SilentlyContinue
    Write-Host "Removed temporary files."
    Write-Host "----------------------------------" -ForegroundColor Magenta
    Write-Host "TESTING COMPLETE"
    if ($global:PassedTests -eq $global:TotalTests) {
        Write-Host "RESULT: PASSED ($($global:PassedTests)/$($global:TotalTests))" -ForegroundColor Green
    } else {
        $failed = $global:TotalTests - $global:PassedTests
        Write-Host "RESULT: FAILED ($($failed) failed, $($global:PassedTests) passed, $($global:TotalTests) total)" -ForegroundColor Red
    }
    Write-Host "----------------------------------" -ForegroundColor Magenta
}