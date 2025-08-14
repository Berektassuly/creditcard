# ==============================================================================
# ТЕСТОВЫЙ СКРИПТ ДЛЯ ПРОЕКТА CREDITCARD
# ==============================================================================

# --- Конфигурация ---
$ExecutableName = "creditcard.exe"
$BrandFileName = "brands.txt"
$IssuerFileName = "issuers.txt"

# --- Глобальные счетчики ---
$global:TotalTests = 0
$global:PassedTests = 0

# --- Функция для вывода результатов теста ---
function Assert-Test {
    param (
        [string]$TestName,
        [scriptblock]$Command,
        [int]$ExpectedExitCode,
        [string]$ExpectedStdout = $null,
        [string]$ExpectedStderr = $null,
        [string]$CheckStdoutContains = $null,
        [string]$CheckStderrContains = $null,
        [string]$CheckStdoutMatches = $null
    )

    $global:TotalTests++
    Write-Host "--- TESTING '$TestName' ---" -ForegroundColor Cyan

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    # Выполнение команды и перенаправление потоков вывода
    & $Command 2> $stderrFile | Out-File $stdoutFile -Encoding utf8
    $actualExitCode = $LASTEXITCODE

    $actualStdout = (Get-Content $stdoutFile -Raw).Trim()
    $actualStderr = (Get-Content $stderrFile -Raw).Trim()

    Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

    $conditionsMet = @()
    $failures = @()

    # 1. Проверка кода выхода
    $exitCodeMatch = ($actualExitCode -eq $ExpectedExitCode)
    $conditionsMet += $exitCodeMatch
    if (-not $exitCodeMatch) {
        $failures += "-> Exit Code: Expected '$ExpectedExitCode', Got '$actualExitCode'"
    }

    # 2. Проверка stdout (точное совпадение)
    if ($ExpectedStdout -ne $null) {
        $stdoutMatch = ($actualStdout -eq $ExpectedStdout)
        $conditionsMet += $stdoutMatch
        if (-not $stdoutMatch) {
            $failures += "-> Stdout: Expected '$ExpectedStdout', Got '$actualStdout'"
        }
    }

    # 3. Проверка stderr (точное совпадение)
    if ($ExpectedStderr -ne $null) {
        $stderrMatch = ($actualStderr -eq $ExpectedStderr)
        $conditionsMet += $stderrMatch
        if (-not $stderrMatch) {
            $failures += "-> Stderr: Expected '$ExpectedStderr', Got '$actualStderr'"
        }
    }
    
    # 4. Проверка содержания stdout
    if ($CheckStdoutContains -ne $null) {
        $stdoutContainsMatch = ($actualStdout -like "*$CheckStdoutContains*")
        $conditionsMet += $stdoutContainsMatch
        if (-not $stdoutContainsMatch) {
            $failures += "-> Stdout should contain '$CheckStdoutContains', Got '$actualStdout'"
        }
    }

    # 5. Проверка содержания stderr
    if ($CheckStderrContains -ne $null) {
        $stderrContainsMatch = ($actualStderr -like "*$CheckStderrContains*")
        $conditionsMet += $stderrContainsMatch
        if (-not $stderrContainsMatch) {
            $failures += "-> Stderr should contain '$CheckStderrContains', Got '$actualStderr'"
        }
    }

    # 6. Проверка stdout по регулярному выражению
    if ($CheckStdoutMatches -ne $null) {
        $stdoutRegexMatch = ($actualStdout -match $CheckStdoutMatches)
        $conditionsMet += $stdoutRegexMatch
        if (-not $stdoutRegexMatch) {
            $failures += "-> Stdout should match regex '$CheckStdoutMatches', Got '$actualStdout'"
        }
    }


    if ($conditionsMet -contains $false) {
        Write-Host "[FAILURE] Test '$TestName' failed." -ForegroundColor Red
        foreach ($failure in $failures) {
            Write-Host $failure -ForegroundColor Yellow
        }
    } else {
        Write-Host "[SUCCESS] Test '$TestName' passed." -ForegroundColor Green
        $global:PassedTests++
    }
    Write-Host ""
}

# ==============================================================================
# --- ОСНОВНАЯ ЛОГИКА СКРИПТА ---
# ==============================================================================
try {
    # --- 1. ПОДГОТОВКА ---
    Write-Host "--- STAGE 1: SETUP ---" -ForegroundColor Magenta

    # Создаем brands.txt
    @"
VISA:4
MASTERCARD:51
MASTERCARD:52
MASTERCARD:53
MASTERCARD:54
MASTERCARD:55
AMEX:34
AMEX:37
"@ | Set-Content $BrandFileName -Encoding utf8
    
    # Создаем issuers.txt
    @"
Kaspi Gold:440043
Forte Black:404243
Forte Blue:517792
Halyk Bonus:440563
Jusan Pay:539545
AMEX Gold:3782
"@ | Set-Content $IssuerFileName -Encoding utf8

    Write-Host "Created '$BrandFileName' and '$IssuerFileName'."

    # Компиляция
    Write-Host "Building the project..."
    go build -o $ExecutableName .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed! Aborting tests." -ForegroundColor Red
        exit 1
    }
    Write-Host "Build successful."
    Write-Host ""


    # --- 2. ТЕСТИРОВАНИЕ 'VALIDATE' ---
    Write-Host "--- STAGE 2: TESTING 'validate' ---" -ForegroundColor Magenta
    
    Assert-Test `
        -TestName "Validate: Один валидный номер" `
        -Command { & ./$ExecutableName validate "4400430180300003" } `
        -ExpectedExitCode 0 `
        -ExpectedStdout "OK"

    Assert-Test `
        -TestName "Validate: Один невалидный номер" `
        -Command { & ./$ExecutableName validate "4400430180300002" } `
        -ExpectedExitCode 1 `
        -ExpectedStderr "INCORRECT"

    Assert-Test `
        -TestName "Validate: Смешанный ввод (валидный, невалидный)" `
        -Command { & ./$ExecutableName validate "4400430180300003" "4400430180300002" } `
        -ExpectedExitCode 1 `
        -ExpectedStdout "OK" `
        -ExpectedStderr "INCORRECT"

    Assert-Test `
        -TestName "Validate: Чтение из stdin" `
        -Command { "4400430180300003 4400430180300011" | & ./$ExecutableName validate --stdin } `
        -ExpectedExitCode 0 `
        -ExpectedStdout "OK`r`nOK" # Два OK, каждый на новой строке

    Assert-Test `
        -TestName "Validate: Негативный - номер короче 13 символов" `
        -Command { & ./$ExecutableName validate "123456789012" } `
        -ExpectedExitCode 1 `
        -ExpectedStderr "INCORRECT"

    # --- 3. ТЕСТИРОВАНИЕ 'GENERATE' ---
    Write-Host "--- STAGE 3: TESTING 'generate' ---" -ForegroundColor Magenta

    Assert-Test `
        -TestName "Generate: Генерация и проверка сортировки" `
        -Command { & ./$ExecutableName generate "517792**********" } `
        -ExpectedExitCode 0 `
        -CheckStdoutContains "5177920000000038" # Проверяем первое валидное число

    Assert-Test `
        -TestName "Generate: Случайный выбор --pick" `
        -Command { & ./$ExecutableName generate --pick "440043**********" } `
        -ExpectedExitCode 0 `
        -CheckStdoutMatches "^\d{16}$" # Проверяем, что на выходе 16-значное число

    Assert-Test `
        -TestName "Generate: Негативный - больше 4 звездочек" `
        -Command { & ./$ExecutableName generate "440043***********" } `
        -ExpectedExitCode 1 `
        -CheckStderrContains "количество '*' должно быть от 1 до 4"

    Assert-Test `
        -TestName "Generate: Негативный - звезды не в конце" `
        -Command { & ./$ExecutableName generate "44**430000000000" } `
        -ExpectedExitCode 1 `
        -CheckStderrContains "символы '*' должны находиться в конце шаблона"

    # --- 4. ТЕСТИРОВАНИЕ 'INFORMATION' ---
    Write-Host "--- STAGE 4: TESTING 'information' ---" -ForegroundColor Magenta

    $expectedInfoValid = @"
4400430180300003
Correct: yes
Card Brand: VISA
Card Issuer: Kaspi Gold
"@.Trim()
    Assert-Test `
        -TestName "Information: Валидный номер" `
        -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "4400430180300003" } `
        -ExpectedExitCode 0 `
        -ExpectedStdout $expectedInfoValid

    $expectedInfoInvalid = @"
1234567890123
Correct: no
Card Brand: -
Card Issuer: -
"@.Trim()
    Assert-Test `
        -TestName "Information: Невалидный номер (код выхода 0)" `
        -Command { & ./$ExecutableName information --brands=$BrandFileName --issuers=$IssuerFileName "1234567890123" } `
        -ExpectedExitCode 0 `
        -ExpectedStdout $expectedInfoInvalid

    Assert-Test `
        -TestName "Information: Негативный - файл не найден" `
        -Command { & ./$ExecutableName information --brands=nonexistent.txt --issuers=$IssuerFileName "4400430180300003" } `
        -ExpectedExitCode 1 `
        -CheckStderrContains "ошибка открытия файла"

    # --- 5. ТЕСТИРОВАНИЕ 'ISSUE' ---
    Write-Host "--- STAGE 5: TESTING 'issue' ---" -ForegroundColor Magenta
    
    # Этот тест сложнее: он генерирует номер, а потом проверяет его валидность и префикс
    Write-Host "--- TESTING 'Issue: Генерация и валидация VISA/Kaspi Gold' ---" -ForegroundColor Cyan
    $global:TotalTests++
    $issuedVisa = (& ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=VISA --issuer="Kaspi Gold").Trim()
    if (($LASTEXITCODE -eq 0) -and ($issuedVisa -match "^440043\d{10}$")) {
        $validationResult = ($issuedVisa | & ./$ExecutableName validate --stdin).Trim()
        if ($validationResult -eq "OK") {
            Write-Host "[SUCCESS] Test 'Issue: Генерация и валидация VISA/Kaspi Gold' passed." -ForegroundColor Green
            $global:PassedTests++
        } else {
            Write-Host "[FAILURE] Test 'Issue: Генерация и валидация VISA/Kaspi Gold' failed." -ForegroundColor Red
            Write-Host "-> Reason: Issued number '$issuedVisa' failed validation." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[FAILURE] Test 'Issue: Генерация и валидация VISA/Kaspi Gold' failed." -ForegroundColor Red
        Write-Host "-> Reason: Command failed or output '$issuedVisa' has wrong prefix/length." -ForegroundColor Yellow
    }
    Write-Host ""

    Assert-Test `
        -TestName "Issue: AMEX (проверка длины 15)" `
        -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="AMEX Gold" } `
        -ExpectedExitCode 0 `
        -CheckStdoutMatches "^\d{15}$"

    Assert-Test `
        -TestName "Issue: Негативный - конфликт бренда и эмитента" `
        -Command { & ./$ExecutableName issue --brands=$BrandFileName --issuers=$IssuerFileName --brand=AMEX --issuer="Kaspi Gold" } `
        -ExpectedExitCode 1 `
        -CheckStderrContains "не подходит для эмитента"

}
finally {
    # --- 6. ЗАВЕРШЕНИЕ И ОЧИСТКА ---
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