package logics

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func ReadDataFile (filepath string) (map[string]string, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("ошибка открытия файла: %s: %v", filepath, err)
	}
	defer file.Close()
	data := make(map[string]string)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 {
			name := strings.TrimSpace(parts[0])
			prefix := strings.TrimSpace(parts[1])
			if name != "" && prefix != "" {
				data[prefix] = name
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения файла: %s: %v", filepath, err)
	}
	return data, nil
}

func FindMatch(cardNumber string, data map[string]string) string {
	bestMatchPrefix := ""
	foundName := "-"
	for prefix, name := range data {
		if strings.HasPrefix(cardNumber, prefix) {
			if len(prefix) > len(bestMatchPrefix) {
				bestMatchPrefix = prefix
				foundName = name
			}
		}
	}
	return foundName
}
