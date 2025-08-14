package logics

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

type BrandOrIssuer struct {
	Name   string
	Prefix string
}

func ReadDataFile(filepath string) ([]BrandOrIssuer, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("ошибка открытия файла: %s: %v", filepath, err)
	}
	defer file.Close()

	var data []BrandOrIssuer
	scanner := bufio.NewScanner(file)

	isFirstLine := true 
	for scanner.Scan() {
		line := scanner.Text()
		if isFirstLine {
			line = strings.TrimPrefix(line, "\uFEFF")
			isFirstLine = false
		}

		if line == "" {
			continue
		}
		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 {
			name := strings.TrimSpace(parts[0])
			prefix := strings.TrimSpace(parts[1])
			if name != "" && prefix != "" {
				newItem := BrandOrIssuer{Name: name, Prefix: prefix}
				data = append(data, newItem)
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения файла: %s: %v", filepath, err)
	}
	return data, nil
}

func FindMatch(cardNumber string, data []BrandOrIssuer) string {
	bestMatchPrefix := ""
	foundName := "-"
	for _, item := range data {
		if strings.HasPrefix(cardNumber, item.Prefix) {
			if len(item.Prefix) > len(bestMatchPrefix) {
				bestMatchPrefix = item.Prefix
				foundName = item.Name
			}
		}
	}
	return foundName
}
