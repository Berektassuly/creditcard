package logics

import (
	"strings"
)

func FindMatch(cardNumber string, data map[string]string) string{
	for dataName, id := range data {
		if strings.contains(cardNumber, id) {
			return dataName
		}
	}
	return -"Unknown"
}