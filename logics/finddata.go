package logics

import (
	"strings"
)

func GetMatch(cardNumber string, data map[string]string) string{
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
	return bestmatch
}

func GetBrands( cardnumber string) string {
	brands := GetBrands()
	return GetMatch(cardNumber, brands)
}

func GetIssuers(cardnumber string) string {
	issuersData := GetIssuers()
	return GetMatch(cardNumber, issuersData)
}
