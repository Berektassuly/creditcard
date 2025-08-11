package logics

import (
	"strconv"
	"strings"
)

func IsValid(cardNumber string) bool {
	cardNumber = strings.TrimSpace(cardNumber)
	if len(cardNumber) < 2 {
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