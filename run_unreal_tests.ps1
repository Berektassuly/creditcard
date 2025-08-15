#!/bin/bash

# ==============================================================================
# БЕЗЖАЛОСТНЫЙ ТЕСТОВЫЙ СКРИПТ ДЛЯ ПРОЕКТА CREDITCARD
# АВТОР: muberikta
# ВЕРСЯ: 1.0
#
# ИНСТРУКЦИИ:
# 1. Поместите этот скрипт в корневую директорию вашего проекта.
# 2. Дайте ему права на выполнение: chmod +x test.sh
# 3. Запустите: ./test.sh
# 4. Не ожидайте снисхождения.
# ==============================================================================

# --- КОНФИГУРАЦИЯ ---
EXECUTABLE="./creditcard"
BRANDS_FILE="brands.txt"
ISSUERS_FILE="issuers.txt"
GOFUMPT_CHECK=true # Установите false, если не хотите проверять форматирование

# --- ЦВЕТА И СЧЕТЧИКИ ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
TEST_COUNT=0

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

# Функция для вывода заголовка секции
print_header() {
    echo -e "\n${YELLOW}=====================================================${NC}"
    echo -e "${YELLOW}>>> ТЕСТИРОВАНИЕ КОМАНДЫ: $1${NC}"
    echo -e "${YELLOW}=====================================================${NC}"
}

# Функция для выполнения и проверки теста
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_stdout="$3"
    local expected_stderr="$4"
    local expected_exit_code="$5"

    TEST_COUNT=$((TEST_COUNT + 1))
    echo -n "  [ТЕСТ] $test_name..."

    # Выполнение команды и захват вывода/кода
    local actual_stdout
    local actual_stderr
    local actual_exit_code

    # Временные файлы для хранения вывода
    STDOUT_FILE=$(mktemp)
    STDERR_FILE=$(mktemp)
    
    # eval позволяет корректно обрабатывать команды с пайпами и кавычками
    eval "$command" > "$STDOUT_FILE" 2> "$STDERR_FILE"
    actual_exit_code=$?
    
    # Нормализуем концы строк (удаляем \r) для кросс-платформенной совместимости
    actual_stdout=$(tr -d '\r' < "$STDOUT_FILE")
    actual_stderr=$(tr -d '\r' < "$STDERR_FILE")

    rm "$STDOUT_FILE" "$STDERR_FILE"

    # Проверка результатов
    local errors=""
    if [ "$actual_stdout" != "$expected_stdout" ]; then
        errors+="ОШИБКА STDOUT\n  Ожидалось: '$expected_stdout'\n  Получено:  '$actual_stdout'\n"
    fi
    if [ "$actual_stderr" != "$expected_stderr" ]; then
        errors+="ОШИБКА STDERR\n  Ожидалось: '$expected_stderr'\n  Получено:  '$actual_stderr'\n"
    fi
    if [ "$actual_exit_code" -ne "$expected_exit_code" ]; then
        errors+="ОШИБКА EXIT CODE\n  Ожидалось: $expected_exit_code\n  Получено:  $actual_exit_code\n"
    fi

    if [ -z "$errors" ]; then
        echo -e " ${GREEN}ПРОЙДЕН${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e " ${RED}ПРОВАЛЕН${NC}"
        echo -e "    ${RED}--- ДЕТАЛИ ---${NC}"
        echo -e "    Команда: $command"
        echo -e "    ${RED}$errors${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# Функция для создания тестовых файлов
create_data_files() {
    # Используем printf для надежной записи \n
    printf "VISA:4\nMASTERCARD:51\nMASTERCARD:52\nMASTERCARD:53\nMASTERCARD:54\nMASTERCARD:55\nAMEX:34\nAMEX:37" > "$BRANDS_FILE"
    printf "Kaspi Gold:440043\nForte Black:404243\nForte Blue:517792\nHalyk Bonus:440563\nJusan Pay:539545" > "$ISSUERS_FILE"
}

# Очистка перед выходом
cleanup() {
    rm -f "$BRANDS_FILE" "$ISSUERS_FILE" "$EXECUTABLE"
}
trap cleanup EXIT

# ==============================================================================
# --- НАЧАЛО ТЕСТИРОВАНИЯ ---
# ==============================================================================

echo "Подготовка к экзамену (Версия 1.0)..."

# --- ЭТАП 0: ПРОВЕРКА КОДА И КОМПИЛЯЦИЯ ---
echo -e "\n${YELLOW}--- ЭТАП 0: Проверка кода и компиляция ---${NC}"

if $GOFUMPT_CHECK; then
    if ! command -v gofumpt &> /dev/null; then
        echo "  [ПРЕДУПРЕЖДЕНИЕ] gofumpt не найден. Пропускаю проверку форматирования."
        echo "  Для установки: go install mvdan.cc/gofumpt@latest"
    else
        echo -n "  [ПРОВЕРКА] Форматирование gofumpt..."
        gofumpt_output=$(gofumpt -l .)
        if [ -n "$gofumpt_output" ]; then
            echo -e " ${RED}ПРОВАЛЕНА${NC}"
            echo "    Следующие файлы не отформатированы:"
            echo "$gofumpt_output"
            echo "    ${RED}ЗАДАНИЕ ПРОВАЛЕНО. ВЫПОЛНИТЕ 'gofumpt -w .'.${NC}"
            exit 1
        else
            echo -e " ${GREEN}OK${NC}"
        fi
    fi
fi

echo -n "  [ПРОВЕРКА] Компиляция проекта 'go build -o $EXECUTABLE .'..."
go build -o $EXECUTABLE .
if [ $? -ne 0 ]; then
    echo -e " ${RED}ПРОВАЛЕНА${NC}"
    echo "    ${RED}Проект не компилируется. Дальнейшее тестирование невозможно.${NC}"
    exit 1
else
    echo -e " ${GREEN}OK${NC}"
fi


# --- ЭТАП 1: VALIDATE ---
print_header "validate"
run_test "Один валидный номер" \
    "$EXECUTABLE validate '4400430180300003'" \
    "OK" "" 0
run_test "Один невалидный номер" \
    "$EXECUTABLE validate '4400430180300002'" \
    "" "INCORRECT" 1
# ИСПРАВЛЕНО: Используем echo -e для создания ожидаемой строки, чтобы избежать проблем с heredoc
run_test "Два валидных номера" \
    "$EXECUTABLE validate '4400430180300003' '4400430180300011'" \
    "$(echo -e "OK\nOK")" "" 0
run_test "Смешанные номера (валидный, невалидный)" \
    "$EXECUTABLE validate '4400430180300003' '4400430180300002'" \
    "OK" "INCORRECT" 1
run_test "Валидный номер через --stdin" \
    "echo '4400430180300003' | $EXECUTABLE validate --stdin" \
    "OK" "" 0
# ИСПРАВЛЕНО: Используем echo -e для создания ожидаемой строки
run_test "Два валидных номера через --stdin (одна строка)" \
    "echo '4400430180300003 4400430180300011' | $EXECUTABLE validate --stdin" \
    "$(echo -e "OK\nOK")" "" 0
run_test "Невалидный номер (короткий)" \
    "$EXECUTABLE validate '12345'" \
    "" "INCORRECT" 1
run_test "Невалидный номер (содержит буквы)" \
    "$EXECUTABLE validate '440043018030000a'" \
    "" "INCORRECT" 1
run_test "Пустой ввод" \
    "$EXECUTABLE validate ''" \
    "" "INCORRECT" 1

# --- ЭТАП 2: GENERATE ---
print_header "generate"
echo "  [ТЕСТ] Генерация, проверка валидности и сортировки..."
TEST_COUNT=$((TEST_COUNT + 1))
GEN_OUTPUT_FILE=$(mktemp)
$EXECUTABLE generate "440043018030**" > "$GEN_OUTPUT_FILE" 2> /dev/null
GEN_EXIT_CODE=$?
if [ $GEN_EXIT_CODE -ne 0 ]; then
    echo -e " ${RED}ПРОВАЛЕН${NC}"
    echo "    Команда generate завершилась с ошибкой ($GEN_EXIT_CODE), хотя не должна была."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    if [ ! -s "$GEN_OUTPUT_FILE" ]; then
        echo -e " ${RED}ПРОВАЛЕН${NC}"
        echo "    Команда generate не сгенерировала ни одного номера."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        if sort -c "$GEN_OUTPUT_FILE" &> /dev/null; then
            VALIDATION_ERRORS=$(tr -d '\r' < "$GEN_OUTPUT_FILE" | $EXECUTABLE validate --stdin 2>&1 >/dev/null)
            if [ -n "$VALIDATION_ERRORS" ]; then
                echo -e " ${RED}ПРОВАЛЕН${NC}"
                echo "    Не все сгенерированные номера валидны. Обнаружены ошибки при проверке."
                FAIL_COUNT=$((FAIL_COUNT + 1))
            else
                echo -e " ${GREEN}ПРОЙДЕН${NC}"
                PASS_COUNT=$((PASS_COUNT + 1))
            fi
        else
            echo -e " ${RED}ПРОВАЛЕН${NC}"
            echo "    Сгенерированные номера не отсортированы."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
fi
rm "$GEN_OUTPUT_FILE"

echo "  [ТЕСТ] Генерация с флагом --pick..."
TEST_COUNT=$((TEST_COUNT + 1))
PICK_OUTPUT=$($EXECUTABLE generate --pick "440043018030****")
PICK_EXIT_CODE=$?
if [ $PICK_EXIT_CODE -ne 0 ]; then
    echo -e " ${RED}ПРОВАЛЕН${NC}"
    echo "    Команда generate --pick завершилась с ошибкой ($PICK_EXIT_CODE)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
elif [ $(echo "$PICK_OUTPUT" | wc -l) -ne 1 ]; then
    echo -e " ${RED}ПРОВАЛЕН${NC}"
    echo "    Команда generate --pick должна выводить ровно один номер."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    VALIDATION_OUTPUT=$(echo "$PICK_OUTPUT" | $EXECUTABLE validate --stdin)
    if [ "$VALIDATION_OUTPUT" == "OK" ]; then
        echo -e " ${GREEN}ПРОЙДЕН${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e " ${RED}ПРОВАЛЕН${NC}"
        echo "    Номер, сгенерированный --pick, не является валидным: $PICK_OUTPUT"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

run_test "Ошибка: слишком много звездочек (>4)" "$EXECUTABLE generate '4400430180*****'" "" "" 1
run_test "Ошибка: звездочки не в конце" "$EXECUTABLE generate '4400**0180301234'" "" "" 1
run_test "Ошибка: нет звездочек" "$EXECUTABLE generate '4400430180300003'" "" "" 1

# --- ЭТАП 3: INFORMATION ---
print_header "information"
create_data_files

EXPECTED_INFO_OK=$(printf "4400430180300003\nCorrect: yes\nCard Brand: VISA\nCard Issuer: Kaspi Gold")
run_test "Валидная карта (VISA, Kaspi Gold)" \
    "$EXECUTABLE information --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE '4400430180300003'" \
    "$EXPECTED_INFO_OK" "" 0

EXPECTED_INFO_FAIL=$(printf "4400450180300003\nCorrect: no\nCard Brand: -\nCard Issuer: -")
run_test "Невалидная карта" \
    "$EXECUTABLE information --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE '4400450180300003'" \
    "$EXPECTED_INFO_FAIL" "" 0

# ИСПРАВЛЕНО: Использован корректный валидный номер, которого нет в issuers.txt
EXPECTED_INFO_UNKNOWN_ISSUER=$(printf "4111111111111111\nCorrect: yes\nCard Brand: VISA\nCard Issuer: -")
run_test "Валидная карта, неизвестный эмитент" \
    "$EXECUTABLE information --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE '4111111111111111'" \
    "$EXPECTED_INFO_UNKNOWN_ISSUER" "" 0

EXPECTED_INFO_MULTIPLE=$(printf "%s\n%s" "$EXPECTED_INFO_OK" "$EXPECTED_INFO_FAIL")
run_test "Несколько карт (валидная и невалидная)" \
    "$EXECUTABLE information --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE '4400430180300003' '4400450180300003'" \
    "$EXPECTED_INFO_MULTIPLE" "" 0

run_test "Валидная карта через --stdin" \
    "echo '4400430180300003' | $EXECUTABLE information --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE --stdin" \
    "$EXPECTED_INFO_OK" "" 0

# --- ЭТАП 4: ISSUE ---
print_header "issue"
echo "  [ТЕСТ] Успешная выдача карты (VISA, Kaspi Gold)..."
TEST_COUNT=$((TEST_COUNT + 1))
ISSUED_CARD=$($EXECUTABLE issue --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE --brand=VISA --issuer="Kaspi Gold")
ISSUE_EXIT_CODE=$?

if [ $ISSUE_EXIT_CODE -ne 0 ]; then
    echo -e " ${RED}ПРОВАЛЕН${NC}"
    echo "    Команда issue завершилась с ошибкой ($ISSUE_EXIT_CODE), хотя не должна была."
    FAIL_COUNT=$((FAIL_COUNT + 1))
elif [ -z "$ISSUED_CARD" ]; then
    echo -e " ${RED}ПРОВАЛЕН${NC}"
    echo "    Команда issue не вернула номер карты."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    if [[ "$ISSUED_CARD" != 440043* ]]; then
        echo -e " ${RED}ПРОВАЛЕН${NC}"
        echo "    Выданная карта ($ISSUED_CARD) не начинается с префикса эмитента (440043)."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        VALIDATION_OUTPUT=$(echo "$ISSUED_CARD" | $EXECUTABLE validate --stdin)
        if [ "$VALIDATION_OUTPUT" == "OK" ]; then
            echo -e " ${GREEN}ПРОЙДЕН${NC}"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo -e " ${RED}ПРОВАЛЕН${NC}"
            echo "    Выданная карта ($ISSUED_CARD) не является валидной."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
fi

run_test "Ошибка: Неизвестный эмитент" "$EXECUTABLE issue --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE --brand=VISA --issuer='Bank Of Tuff'" "" "" 1
run_test "Ошибка: Неизвестный бренд" "$EXECUTABLE issue --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE --brand=Discover --issuer='Kaspi Gold'" "" "" 1
run_test "Ошибка: Несоответствие бренда и эмитента" "$EXECUTABLE issue --brands=$BRANDS_FILE --issuers=$ISSUERS_FILE --brand=AMEX --issuer='Kaspi Gold'" "" "" 1

# ==============================================================================
# --- РЕЗУЛЬТАТЫ ЭКЗАМЕНА ---
# ==============================================================================
echo -e "\n${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}>>> ИТОГОВЫЕ РЕЗУЛЬТАТЫ${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo "  Всего тестов: $TEST_COUNT"
echo -e "  ${GREEN}Пройдено:    $PASS_COUNT${NC}"
echo -e "  ${RED}Провалено:   $FAIL_COUNT${NC}"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n${GREEN}Поздравляю. Ты сдал.${NC}"
else
    echo -e "\n${RED}НЕЗАЧЕТ. Возвращайся, когда твой код будет работать.${NC}"
    exit 1
fi

exit 0