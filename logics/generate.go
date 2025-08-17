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
	pattern = strings.ReplaceAll(pattern, " ", "")
	asteriskCount := strings.Count(pattern, "*")
	if asteriskCount == 0 {
		return nil, fmt.Errorf("шаблон должен содержать хотя бы одну звездочку")
	}
	if asteriskCount > 4 {
		return nil, fmt.Errorf("шаблон не может содержать более 4 звездочек")
	}
	if !strings.HasSuffix(pattern, strings.Repeat("*", asteriskCount)) {
		return nil, fmt.Errorf("звездочки должны быть в конце шаблона")
	}
	base := strings.TrimSuffix(pattern, strings.Repeat("*", asteriskCount))
	if len(base)+asteriskCount < 13 || len(base)+asteriskCount > 19 {
		return nil, fmt.Errorf("длина шаблона должна быть не менее 13 символов и не более 19 символов")
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
		return "", fmt.Errorf("нет доступных номеров для выбора")
	}
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return numbers[r.Intn(len(numbers))], nil
}
