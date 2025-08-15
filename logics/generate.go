package logics

import (
	"fmt"
	"math"
	"math/rand"
	"sort"
	"strings"
	"time"
)

func Generate(pattern string) ([]string, error) {
	asteriskCount := strings.Count(pattern, "*")
	if asteriskCount == 0 {
		return nil, fmt.Errorf("ошибка: в шаблоне отсутствуют символы '*'")
	}
	if asteriskCount > 4 {
		return nil, fmt.Errorf("ошибка: количество '*' должно быть от 1 до 4")
	}
	if !strings.HasSuffix(pattern, strings.Repeat("*", asteriskCount)) {
		return nil, fmt.Errorf("ошибка: символы '*' должны находиться в конце шаблона")
	}
	base := strings.TrimSuffix(pattern, strings.Repeat("*", asteriskCount))
	if len(base)+asteriskCount < 13 {
		return nil, fmt.Errorf("ошибка: итоговый номер карты слишком короткий")
	}

	var validNumbers []string
	limit := int(math.Pow10(asteriskCount))

	for i := 0; i < limit; i++ {
		candidate := base + fmt.Sprintf("%0*d", asteriskCount, i)
		if IsValid(candidate) {
			validNumbers = append(validNumbers, candidate)
		}
	}
	sort.Strings(validNumbers)
	return validNumbers, nil
}

func PickRandom(numbers []string) (string, error) {
	if len(numbers) == 0 {
		return "", fmt.Errorf("не удалось сгенерировать ни одного валидного номера")
	}
	return numbers[rand.New(rand.NewSource(time.Now().UnixNano())).Intn(len(numbers))], nil
}
