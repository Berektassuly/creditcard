package logics

import (
	"strings"
)

func FindMatch(cardNumber string, data map[string]string) string{
	var bestmatch string = ""
	var namemanth string = "-"

	for name, name1 := range data {
		if strings.HasPrefix(carndNumber, name) {
			if len(name) > len(bestmatch) {
			bestmatch = name
			namemanth = name1
			}
		}
	}
}