#
# СЦЕНАРИЙ БЕЗЖАЛОСТНОГО ТЕСТИРОВАНИЯ 'creditcard'
# ВЕРСИЯ 2.0: ДЛЯ ТЕХ, КТО НЕ УМЕЕТ КОПИРОВАТЬ
#
Clear-Host

# --- ИНФРАСТРУКТУРА ДЛЯ УНИЖЕНИЯ ---

# Функция для вывода вердикта. Без соплей.
function Test-Result {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Reason = ""
    )
    if ($Success) {
        Write-Host "[ PASS ] $TestName" -ForegroundColor Green
    } else {
        Write-Host "[ FAIL ] $TestName" -ForegroundColor Red
        Write-Host "    └─ ПРИЧИНА ПРОВАЛА: $Reason" -ForegroundColor Yellow
    }
}

# --- ПОДГОТОВКА ПОЛИГОНА ---
Write-Host "--- ЭТАП 0: ПОДГОТОВКА ПОЛИГОНА ---" -ForegroundColor DarkCyan

# Создаем файлы с данными, которые покроют больше кейсов
Write-Host "Создаю файлы brands.txt и issuers.txt..."
@"
VISA:4
MASTERCARD:51
MASTERCARD:52
MASTERCARD:53
MASTERCARD:54
MASTERCARD:55
AMEX:34
AMEX:37
"@ | Set-Content -Path "brands.txt" -Encoding utf8

@"
Kaspi Gold:440043
Forte Blue:517792
AMEX Platinum:37828
Halyk Bonus:440563
Totally-Not-A-VISA-Card:511111
"@ | Set-Content -Path "issuers.txt" -Encoding utf8

# Собираем проект. Если он не собирается, дальше говорить не о чем.
Write-Host "Собираю твой бинарь creditcard.exe..."
go build -o creditcard.exe .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ FATAL ] Твой код даже не компилируется. Разговор окончен." -ForegroundColor Red
    exit 1
}
Write-Host "Сборка прошла успешно. Не обольщайся, это только начало." -ForegroundColor Green
Write-Host ""

$Global:totalTests = 0
$Global:failedTests = 0

function Run-Test {
    param(
        [string]$TestName,
        [scriptblock]$ValidationBlock,
        [string]$FailureReason
    )
    $Global:totalTests++
    try {
        if (& $ValidationBlock) {
            Test-Result -TestName $TestName -Success $true
        } else {
            Test-Result -TestName $TestName -Success $false -Reason $FailureReason
            $Global:failedTests++
        }
    } catch {
        Test-Result -TestName $TestName -Success $false -Reason "Тест упал с критической ошибкой: $($_.Exception.Message)"
        $Global:failedTests++
    }
}


# --- ЭТАП 1: ТЕСТИРОВАНИЕ 'validate' ---
Write-Host "--- ЭТАП 1: НАЧИНАЕМ ИЗБИЕНИЕ 'validate' ---" -ForegroundColor Cyan

Run-Test "Validate: Валидный номер" `
    { $output = (./creditcard.exe validate "4400430180300003" 2>&1); return ($LASTEXITCODE -eq 0 -and $output.Trim() -eq "OK") } `
    "Ожидался exit code 0 и 'OK' в stdout."

Run-Test "Validate: Невалидный номер" `
    {
        $p = Start-Process ./creditcard.exe -ArgumentList 'validate', '4400430180300002' -PassThru -NoNewWindow -RedirectStandardError 'stderr.txt'
        $p.WaitForExit()
        $stderr = Get-Content stderr.txt
        return ($p.ExitCode -eq 1 -and $stderr.Trim() -eq "INCORRECT")
    } `
    "Ожидался exit code 1 и 'INCORRECT' в stderr."

Run-Test "Validate: Множественный ввод (валидный, невалидный)" `
    {
        $p = Start-Process ./creditcard.exe -ArgumentList 'validate', '4400430180300003', '4400430180300002' -PassThru -NoNewWindow -RedirectStandardOutput 'stdout.txt' -RedirectStandardError 'stderr.txt'
        $p.WaitForExit()
        $stdout = Get-Content stdout.txt
        $stderr = Get-Content stderr.txt
        return ($p.ExitCode -eq 1 -and $stdout.Trim() -eq "OK" -and $stderr.Trim() -eq "INCORRECT")
    } `
    "При смешанном вводе ожидался exit code 1, 'OK' в stdout, 'INCORRECT' в stderr."

Run-Test "Validate: Чтение из stdin" `
    { $output = (echo "4400430180300003" | ./creditcard.exe validate --stdin 2>&1); return ($LASTEXITCODE -eq 0 -and $output.Trim() -eq "OK") } `
    "Флаг --stdin не работает или работает некорректно."
    
Run-Test "Validate: Негативный - номер с буквами" `
    { ./creditcard.exe validate "440043018030000a" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Программа должна падать с кодом 1 на нечисловом вводе."

Run-Test "Validate: Негативный - номер короче 13 символов" `
    { ./creditcard.exe validate "12345" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Программа должна падать с кодом 1 на слишком коротком номере."

# --- ЭТАП 2: ТЕСТИРОВАНИЕ 'generate' ---
Write-Host "`n--- ЭТАП 2: ЛОМАЕМ ГЕНЕРАТОР 'generate' ---" -ForegroundColor Cyan

Run-Test "Generate: Негативный - больше 4 звездочек" `
    { ./creditcard.exe generate "4400*****" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Должен быть exit code 1 при >4 звездочках."

Run-Test "Generate: Негативный - звезды не в конце" `
    { ./creditcard.exe generate "44**1234" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Должен быть exit code 1, если звезды не в конце строки."

Run-Test "Generate: Проверка валидности и сортировки вывода" `
    {
        $numbers = ./creditcard.exe generate "411111111111**"
        if ($LASTEXITCODE -ne 0) { Write-Host "Generate command failed"; return $false }
        if ($numbers.Length -eq 0) { Write-Host "Generate produced no output"; return $false }
        # Проверяем, что все сгенерированные номера валидны
        foreach ($num in $numbers) {
            ./creditcard.exe validate $num.Trim() >$null
            if ($LASTEXITCODE -ne 0) { Write-Host "Generated number '$num' is invalid"; return $false }
        }
        # Проверяем сортировку
        $sortedNumbers = $numbers | Sort-Object
        if ((Compare-Object $numbers $sortedNumbers) -ne $null) { Write-Host "Output is not sorted"; return $false }
        return $true
    } `
    "Вывод 'generate' либо невалиден, либо не отсортирован."

Run-Test "Generate: Флаг --pick" `
    {
        $output = ./creditcard.exe generate --pick "411111111111****"
        $lines = $output -split "`n" | Where-Object { $_.Trim() -ne "" }
        if ($lines.Length -ne 1) { return $false } # Должна быть ровно одна строка
        ./creditcard.exe validate $lines[0].Trim() >$null
        return ($LASTEXITCODE -eq 0)
    } `
    "Флаг --pick должен выводить ровно один валидный номер."


# --- ЭТАП 3: ТЕСТИРОВАНИЕ 'information' ---
Write-Host "`n--- ЭТАП 3: ПРОВЕРЯЕМ ИНФОРМАТОРА 'information' ---" -ForegroundColor Cyan

$expectedInfo = @"
4400430180300003
Correct: yes
Card Brand: VISA
Card Issuer: Kaspi Gold
"@.Trim()
Run-Test "Information: Валидный номер (VISA, Kaspi)" `
    { $output = (./creditcard.exe information --brands=brands.txt --issuers=issuers.txt "4400430180300003").Trim(); return ($LASTEXITCODE -eq 0 -and $output -eq $expectedInfo) } `
    "Вывод для валидной карты не соответствует эталону."

$expectedIncorrectInfo = @"
4400450180300003
Correct: no
Card Brand: -
Card Issuer: -
"@.Trim()
Run-Test "Information: Невалидный номер (по ТЗ должен быть exit code 0)" `
    { $output = (./creditcard.exe information --brands=brands.txt --issuers=issuers.txt "4400450180300003").Trim(); return ($LASTEXITCODE -eq 0 -and $output -eq $expectedIncorrectInfo) } `
    "Вывод для невалидной карты некорректен или exit code не равен 0, что ПРОТИВОРЕЧИТ ТЗ."

Run-Test "Information: Негативный - файл не найден" `
    { ./creditcard.exe information --brands=nonexistent.txt --issuers=issuers.txt "4400430180300003" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Программа должна падать с кодом 1, если файл данных не найден."


# --- ЭТАП 4: ТЕСТИРОВАНИЕ 'issue' ---
Write-Host "`n--- ЭТАП 4: ВЗЛАМЫВАЕМ ЭМИТЕНТА 'issue' ---" -ForegroundColor Cyan

Run-Test "Issue: Генерация валидной карты AMEX" `
    {
        $card = (./creditcard.exe issue --brands=brands.txt --issuers=issuers.txt --brand=AMEX --issuer="AMEX Platinum").Trim()
        if ($LASTEXITCODE -ne 0) { return $false }
        if ($card.Length -ne 15) { return $false } # AMEX = 15
        if (-not $card.StartsWith("37828")) { return $false }
        ./creditcard.exe validate $card >$null
        return ($LASTEXITCODE -eq 0)
    } `
    "Сгенерированная карта AMEX невалидна, имеет неверную длину или префикс."

Run-Test "Issue: Негативный - конфликт бренда и эмитента" `
    { ./creditcard.exe issue --brands=brands.txt --issuers=issuers.txt --brand=VISA --issuer="Totally-Not-A-VISA-Card" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Программа должна падать с кодом 1, если префикс эмитента (51) не соответствует бренду (4)."

Run-Test "Issue: Негативный - бренд не существует" `
    { ./creditcard.exe issue --brands=brands.txt --issuers=issuers.txt --brand=MIR --issuer="Kaspi Gold" 2>$null; return ($LASTEXITCODE -eq 1) } `
    "Программа должна падать с кодом 1 при запросе несуществующего бренда."


# --- ФИНАЛЬНЫЙ ВЕРДИКТ ---
Write-Host "`n--- ВЕРДИКТ ---" -ForegroundColor DarkCyan
if ($Global:failedTests -eq 0) {
    Write-Host "ВСЕ $($Global:totalTests) ТЕСТОВ ПРОЙДЕНЫ." -ForegroundColor Green
    Write-Host "Я в ахуе. Либо ты списал, либо случайно все правильно сделал. Можешь идти." -ForegroundColor White
} else {
    Write-Host "$($Global:failedTests) из $($Global:totalTests) ТЕСТОВ ПРОВАЛЕНО." -ForegroundColor Red
    Write-Host "Твой код - это дырявое корыто. Иди и переписывай, пока я не вызвал санитаров." -ForegroundColor White
}

# --- ЗАЧИСТКА ---
Remove-Item -Path "brands.txt", "issuers.txt", "creditcard.exe", "stdout.txt", "stderr.txt" -ErrorAction SilentlyContinue