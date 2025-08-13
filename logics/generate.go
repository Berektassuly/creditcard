package logics

import (
	"fmt"
	"math"
	"math/rand"
	"strings"
	"time"
)

func Generate(pattern string) ([]string, error) {
	asterisCount := strings.Count(pattern, "*")
	if asterisCount < 1 || asterisCount > 4 {
		return nil, fmt.Errorf("ошибка: количество '*' должно быть от 1 до 4")
	}
	if !strings.HasSuffix(pattern, strings.Repeat("*", asterisCount)) {
		return nil, fmt.Errorf("ошибка: смволы '*' должны находится в конце шаблона")
	}

	base := strings.TrimRight(pattern, "*")
	if len(base) + asterisCount < 13 {
		return nil, fmt.Errorf("ошибка: итоговый номер карты слишком короткий")
	}

	var validNumbers []string
	limit := int(math.Pow10(asterisCount))

	for i := 0; i < limit; i++ {
		suffix := fmt.Sprintf("%0*d", asterisCount, i)
		candidate := base + suffix
		if IsValid(candidate) {
			validNumbers = append(validNumbers, candidate)
		}
	}
	return validNumbers, nil
}

func PickRandom(numbers []string) (string, error) {
	if len(numbers) == 0 {
		return "", fmt.Errorf("не удалось сгенерировать ниодного валидного номера")
	}
	return numbers[rand.New(rand.NewSource(time.Now().UnixNano())).Intn(len(numbers))], nil
}