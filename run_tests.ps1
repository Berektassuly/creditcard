# --- PREPARATION: CREATE FILES AND BUILD THE PROJECT ---
Clear-Host

# Function to display results
function Test-Result {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Expected,
        [string]$Got
    )
    if ($Success) {
        Write-Host "[SUCCESS] $TestName" -ForegroundColor Green
    } else {
        Write-Host "[FAILURE] $TestName" -ForegroundColor Red
        Write-Host "  - Expected: $Expected" -ForegroundColor Yellow
        Write-Host "  - Got:      $Got" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Create brands.txt
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

# Create issuers.txt
@"
Kaspi Gold:440043
Forte Black:404243
Forte Blue:517792
Halyk Bonus:440563
Jusan Pay:539545
AMEX-Bank:371234
"@ | Set-Content -Path "issuers.txt" -Encoding utf8

# Build the project
Write-Host "### Building project..." -ForegroundColor Cyan
go build -o creditcard.exe .
if ($LASTEXITCODE -ne 0) {
    Write-Host "### BUILD FAILED! Your code doesn't even compile." -ForegroundColor Red
    exit 1
}
Write-Host "### Build successful." -ForegroundColor Green
Write-Host ""

$totalTests = 0
$failedTests = 0

# --- TEST 'validate' COMMAND ---
Write-Host "--- TESTING 'validate' ---" -ForegroundColor Cyan

$totalTests++; ./creditcard validate "4400430180300003" > $null
if ($LASTEXITCODE -eq 0) { Test-Result "Validate: One valid number" $true }
else { Test-Result "Validate: One valid number" $false "Exit code 0" "Exit code $LASTEXITCODE"; $failedTests++ }

$totalTests++; ./creditcard validate "4400430180300002" 2> $null
if ($LASTEXITCODE -eq 1) { Test-Result "Validate: One invalid number" $true }
else { Test-Result "Validate: One invalid number" $false "Exit code 1" "Exit code $LASTEXITCODE"; $failedTests++ }

$totalTests++;
$output = (./creditcard validate "4400430180300003" "1234567890123" 2>&1) | Out-String
if (($LASTEXITCODE -eq 1) -and ($output -like "*OK*") -and ($output -like "*INCORRECT*")) {
    Test-Result "Validate: Mix of valid and invalid" $true
} else {
    Test-Result "Validate: Mix of valid and invalid" $false "Code 1 and OK/INCORRECT output" "Code $LASTEXITCODE"; $failedTests++
}

# --- TEST 'generate' COMMAND ---
Write-Host "--- TESTING 'generate' ---" -ForegroundColor Cyan

$totalTests++; ./creditcard generate "4400430180*****" 2> $null
if ($LASTEXITCODE -eq 1) { Test-Result "Generate: Error > 4 asterisks" $true }
else { Test-Result "Generate: Error > 4 asterisks" $false "Exit code 1" "Exit code $LASTEXITCODE"; $failedTests++ }

# --- TEST 'information' COMMAND ---
Write-Host "--- TESTING 'information' ---" -ForegroundColor Cyan

$totalTests++; ./creditcard information --brands=brands.txt --issuers=issuers.txt "4400430180300002" > $null
if ($LASTEXITCODE -eq 1) { Test-Result "Information: Invalid number exit code" $true }
else { Test-Result "Information: Invalid number exit code" $false "Exit code 1" "Exit code $LASTEXITCODE"; $failedTests++ }

# --- TEST 'issue' COMMAND ---
Write-Host "--- TESTING 'issue' ---" -ForegroundColor Cyan

$totalTests++;
$card_amex = ./creditcard issue --brands=brands.txt --issuers=issuers.txt --brand=AMEX --issuer="AMEX-Bank"
if ($LASTEXITCODE -eq 0) { Test-Result "Issue: Issue AMEX (quotes problem)" $true }
else { Test-Result "Issue: Issue AMEX (quotes problem)" $false "Exit code 0" "Exit code $LASTEXITCODE"; $failedTests++ }

if ($LASTEXITCODE -eq 0) {
    $totalTests++;
    if ($card_amex.Length -eq 15) { Test-Result "Issue: AMEX card length" $true }
    else { Test-Result "Issue: AMEX card length" $false "15" "$($card_amex.Length)"; $failedTests++ }
}

$totalTests++;
./creditcard issue --brands=brands.txt --issuers=issuers.txt --brand=AMEX --issuer="Kaspi Gold" 2> $null
if ($LASTEXITCODE -eq 1) { Test-Result "Issue: Invalid brand/issuer pair" $true }
else { Test-Result "Issue: Invalid brand/issuer pair" $false "Exit code 1" "Exit code $LASTEXITCODE"; $failedTests++ }

# --- FINAL VERDICT ---
Write-Host "--- TESTING COMPLETE ---" -ForegroundColor Cyan
if ($failedTests -eq 0) {
    Write-Host "ALL $totalTests TESTS PASSED. I can't believe it." -ForegroundColor Green
} else {
    Write-Host "$failedTests out of $totalTests TESTS FAILED. Go fix your code, you useless amateur." -ForegroundColor Red
}

# Cleanup
Remove-Item -Path "brands.txt", "issuers.txt", "creditcard.exe" -ErrorAction SilentlyContinue