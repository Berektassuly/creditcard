package logics

import (
	"strconv"
	"strings"
)


func IsValid(cardNumber string) bool {
	cardNumber = strings.TrimSpace(cardNumber)
	if len(cardNumber) < 13 {
		return false
	}

	var sum int
	parity := len(cardNumber) % 2
	for i, r := range cardNumber {
		digit, err := strconv.Atoi(string(r))
		if err != nil {
			return false
		}

		if i%2 == parity {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}

		sum += digit
	}

	return sum%10 == 0
}

func CalculateLuhnDigit(baseNumber string) string {
	tempNumber := baseNumber + "0"
	var sum int
	parity := len(tempNumber) % 2

	for i, r := range tempNumber {
		digit, _ := strconv.Atoi(string(r))
		if i%2 == parity {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}
		sum += digit
	}
	checkDigit := (10 - (sum % 10)) % 10
	return strconv.Itoa(checkDigit)
}
