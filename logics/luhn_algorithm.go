package logics

import (
	"strconv"
)

func IsValid(cardNumber string) bool {
	if len(cardNumber) < 13 {
		return false
	}

	var sum int
	var alternate bool
	for i := len(cardNumber) - 1; i > -1; i-- {
		digit, err := strconv.Atoi(string(cardNumber[i]))
		if err != nil {
			return false
		}
		if alternate {
			digit *= 2
			if digit > 9 {
				digit = (digit % 10) + 1
			}
		}
		sum += digit
		alternate = !alternate
	}
	return sum%10 == 0
}

func CalculateLuhnDigit(baseNumber string) string {
	var sum int
	alternate := true
	for i := len(baseNumber) - 1; i > -1; i-- {
		digit, _ := strconv.Atoi(string(baseNumber[i]))
		if alternate {
			digit *= 2
			if digit > 9 {
				digit = (digit % 10) + 1
			}
		}
		sum += digit
		alternate = !alternate
	}
	checkDigit := (10 - (sum % 10)) % 10
	return strconv.Itoa(checkDigit)
}
