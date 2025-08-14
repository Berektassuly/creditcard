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
	sum := 0
	isSecond := false
	for i := len(cardNumber) - 1; i >= 0; i-- {
		digit, err := strconv.Atoi(string(cardNumber[i]))
		if err != nil {
			return false
		}
		if isSecond {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}
		sum += digit
		isSecond = !isSecond
	}

	return sum%10 == 0
}

func CalculateLuhnDigit(baseNumber string) string {
	sum := 0
	isSecond := true
	for i := len(baseNumber) - 1; i >= 0; i-- {
		digit, _ := strconv.Atoi(string(baseNumber[i]))

		if isSecond {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}
		sum += digit
		isSecond = !isSecond
	}

	checkDigit := (10 - (sum % 10)) % 10
	return strconv.Itoa(checkDigit)
}