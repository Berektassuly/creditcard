#!/bin/bash

#
# СЦЕНАРИЙ БЕЗЖАЛОСТНОГО ТЕСТИРОВАНИЯ 'creditcard'
# ВЕРСИЯ 2.0 ДЛЯ BASH: ТЕПЕРЬ КРОССПЛАТФОРМЕННО, НО НЕ МЕНЕЕ БОЛЕЗНЕННО
#

# --- ИНФРАСТРУКТУРА ДЛЯ УНИЖЕНИЯ ---

# Цвета для вывода, чтобы было красивее и больнее
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_DARK_CYAN='\033[0;96m'
C_WHITE='\033[0;97m'
C_NC='\033[0m' # No Color

# Функция для вывода вердикта. Без соплей.
test_result() {
    local test_name="$1"
    local success="$2"
    local reason="$3"

    if [ "$success" = true ]; then
        echo -e "${C_GREEN}[ PASS ]${C_NC} $test_name"
    else
        echo -e "${C_RED}[ FAIL ]${C_NC} $test_name"
        echo -e "    ${C_YELLOW}└─ ПРИЧИНА ПРОВАЛА:${C_NC} $reason"
    fi
}

# --- ПОДГОТОВКА ПОЛИГОНА ---
echo -e "${C_DARK_CYAN}--- ЭТАП 0: ПОДГОТОВКА ПОЛИГОНА ---${C_NC}"

# Создаем файлы с данными, которые покроют больше кейсов
echo "Создаю файлы brands.txt и issuers.txt..."
cat << EOF > brands.txt
VISA:4
MASTERCARD:51
MASTERCARD:52
MASTERCARD:53
MASTERCARD:54
MASTERCARD:55
AMEX:34
AMEX:37
EOF

cat << EOF > issuers.txt
Kaspi Gold:440043
Forte Blue:517792
AMEX Platinum:37828
Halyk Bonus:440563
Totally-Not-A-VISA-Card:511111
EOF

# Собираем проект. Если он не собирается, дальше говорить не о чем.
echo "Собираю твой бинарь creditcard..."
go build -o creditcard .
if [ $? -ne 0 ]; then
    echo -e "${C_RED}[ FATAL ] Твой код даже не компилируется. Разговор окончен.${C_NC}"
    exit 1
fi
echo -e "${C_GREEN}Сборка прошла успешно. Не обольщайся, это только начало.${C_NC}"
echo ""

# Глобальные счетчики
TOTAL_TESTS=0
FAILED_TESTS=0

# Обертка для запуска и оценки теста
run_test() {
    local test_name="$1"
    local command_to_run="$2"
    local failure_reason="$3"

    ((TOTAL_TESTS++))
    # Выполняем команду в subshell, чтобы избежать влияния на основной скрипт
    if (eval "$command_to_run"); then
        test_result "$test_name" true
    else
        test_result "$test_name" false "$failure_reason"
        ((FAILED_TESTS++))
    fi
}

# --- ЭТАП 1: ТЕСТИРОВАНИЕ 'validate' ---
echo -e "${C_CYAN}--- ЭТАП 1: НАЧИНАЕМ ИЗБИЕНИЕ 'validate' ---${C_NC}"

run_test "Validate: Валидный номер" \
    '[ "$(./creditcard validate "4400430180300003" 2>/dev/null)" = "OK" ] && [ $? -eq 0 ]' \
    "Ожидался exit code 0 и 'OK' в stdout."

run_test "Validate: Невалидный номер" \
    'output=$(./creditcard validate "4400430180300002" 2>&1 >/dev/null); [ "$output" = "INCORRECT" ] && [ $? -eq 1 ]' \
    "Ожидался exit code 1 и 'INCORRECT' в stderr."

run_test "Validate: Множественный ввод (валидный, невалидный)" \
    'output_stdout=$(./creditcard validate "4400430180300003" "4400430180300002" 2>stderr.txt); exit_code=$?; output_stderr=$(cat stderr.txt); [ "$output_stdout" = "OK" ] && [ "$output_stderr" = "INCORRECT" ] && [ $exit_code -eq 1 ]' \
    "При смешанном вводе ожидался exit code 1, 'OK' в stdout, 'INCORRECT' в stderr."

run_test "Validate: Чтение из stdin" \
    '[ "$(echo "4400430180300003" | ./creditcard validate --stdin 2>/dev/null)" = "OK" ] && [ $? -eq 0 ]' \
    "Флаг --stdin не работает или работает некорректно."

run_test "Validate: Негативный - номер с буквами" \
    './creditcard validate "440043018030000a" &>/dev/null; [ $? -eq 1 ]' \
    "Программа должна падать с кодом 1 на нечисловом вводе."

run_test "Validate: Негативный - номер короче 13 символов" \
    './creditcard validate "12345" &>/dev/null; [ $? -eq 1 ]' \
    "Программа должна падать с кодом 1 на слишком коротком номере."

# --- ЭТАП 2: ТЕСТИРОВАНИЕ 'generate' ---
echo -e "\n${C_CYAN}--- ЭТАП 2: ЛОМАЕМ ГЕНЕРАТОР 'generate' ---${C_NC}"

run_test "Generate: Негативный - больше 4 звездочек" \
    './creditcard generate "4400*****" &>/dev/null; [ $? -eq 1 ]' \
    "Должен быть exit code 1 при >4 звездочках."

run_test "Generate: Негативный - звезды не в конце" \
    './creditcard generate "44**1234" &>/dev/null; [ $? -eq 1 ]' \
    "Должен быть exit code 1, если звезды не в конце строки."

run_test "Generate: Проверка валидности и сортировки вывода" \
    '
    numbers=$(./creditcard generate "411111111111**")
    [ $? -ne 0 ] && exit 1
    [ -z "$numbers" ] && exit 1
    
    sorted_numbers=$(echo "$numbers" | sort)
    [ "$numbers" != "$sorted_numbers" ] && exit 1
    
    while IFS= read -r line; do
        ./creditcard validate "$line" &>/dev/null
        [ $? -ne 0 ] && exit 1
    done <<< "$numbers"
    ' \
    "Вывод 'generate' либо невалиден, либо не отсортирован."

run_test "Generate: Флаг --pick" \
    '
    output=$(./creditcard generate --pick "411111111111****")
    [ $(echo "$output" | wc -l) -ne 1 ] && exit 1
    ./creditcard validate "$output" &>/dev/null
    [ $? -ne 0 ] && exit 1
    ' \
    "Флаг --pick должен выводить ровно один валидный номер."


# --- ЭТАП 3: ТЕСТИРОВАНИЕ 'information' ---
echo -e "\n${C_CYAN}--- ЭТАП 3: ПРОВЕРЯЕМ ИНФОРМАТОРА 'information' ---${C_NC}"

expected_info=$(cat <<EOF
4400430180300003
Correct: yes
Card Brand: VISA
Card Issuer: Kaspi Gold
EOF
)
run_test "Information: Валидный номер (VISA, Kaspi)" \
    'output=$(./creditcard information --brands=brands.txt --issuers=issuers.txt "4400430180300003"); [ $? -eq 0 ] && [ "$output" = "$expected_info" ]' \
    "Вывод для валидной карты не соответствует эталону."

expected_incorrect_info=$(cat <<EOF
4400450180300003
Correct: no
Card Brand: -
Card Issuer: -
EOF
)
run_test "Information: Невалидный номер (по ТЗ должен быть exit code 0)" \
    'output=$(./creditcard information --brands=brands.txt --issuers=issuers.txt "4400450180300003"); [ $? -eq 0 ] && [ "$output" = "$expected_incorrect_info" ]' \
    "Вывод для невалидной карты некорректен или exit code не равен 0, что ПРОТИВОРЕЧИТ ТЗ."

run_test "Information: Негативный - файл не найден" \
    './creditcard information --brands=nonexistent.txt --issuers=issuers.txt "4400430180300003" &>/dev/null; [ $? -eq 1 ]' \
    "Программа должна падать с кодом 1, если файл данных не найден."


# --- ЭТАП 4: ТЕСТИРОВАНИЕ 'issue' ---
echo -e "\n${C_CYAN}--- ЭТАП 4: ВЗЛАМЫВАЕМ ЭМИТЕНТА 'issue' ---${C_NC}"

run_test "Issue: Генерация валидной карты AMEX" \
    '
    card=$(./creditcard issue --brands=brands.txt --issuers=issuers.txt --brand=AMEX --issuer="AMEX Platinum")
    [ $? -ne 0 ] && exit 1
    [ ${#card} -ne 15 ] && exit 1
    [[ "$card" != 37828* ]] && exit 1
    ./creditcard validate "$card" &>/dev/null
    [ $? -ne 0 ] && exit 1
    ' \
    "Сгенерированная карта AMEX невалидна, имеет неверную длину или префикс."

run_test "Issue: Негативный - конфликт бренда и эмитента" \
    './creditcard issue --brands=brands.txt --issuers=issuers.txt --brand=VISA --issuer="Totally-Not-A-VISA-Card" &>/dev/null; [ $? -eq 1 ]' \
    "Программа должна падать с кодом 1, если префикс эмитента (51) не соответствует бренду (4)."

run_test "Issue: Негативный - бренд не существует" \
    './creditcard issue --brands=brands.txt --issuers=issuers.txt --brand=MIR --issuer="Kaspi Gold" &>/dev/null; [ $? -eq 1 ]' \
    "Программа должна падать с кодом 1 при запросе несуществующего бренда."


# --- ФИНАЛЬНЫЙ ВЕРДИКТ ---
echo -e "\n${C_DARK_CYAN}--- ВЕРДИКТ ---${C_NC}"
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${C_GREEN}ВСЕ $TOTAL_TESTS ТЕСТОВ ПРОЙДЕНЫ.${C_NC}"
    echo -e "${C_WHITE}Я в ахуе. Либо ты списал, либо случайно все правильно сделал. Можешь идти.${C_NC}"
else
    echo -e "${C_RED}$FAILED_TESTS из $TOTAL_TESTS ТЕСТОВ ПРОВАЛЕНО.${C_NC}"
    echo -e "${C_WHITE}Твой код - это дырявое корыто. Иди и переписывай, пока я не вызвал санитаров.${C_NC}"
fi

# --- ЗАЧИСТКА ---
rm -f brands.txt issuers.txt creditcard stderr.txt