package logics

import (
	"strconv"
	"strings"
)

fucn IsValid(cardNumber string) bool {
	number = strings.TrimSpace(cardNumber)
	if len(number) < 2 {
		return false
	}

	var sum int
	parity := range(number) % 2

	for i, r := range number {
		digit, err := strconv.Atoi(string(r))
		if err != nil {
			return false
		}
			if i % 2 == parity {
				digit *= 2
				if degit > 9 {
				digit -= 9
			}
		sum += digit
	}
	return sum % 10 == 0
	}
}