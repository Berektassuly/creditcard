package logics

import (
	"strings"
)

func FindMatch(cardNumber string, data map[string]string) string {
	var bestMatchPrefix string = ""
	var foundName string = "-"
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

func FindBrand(cardNumber string) string {
	brandsData := GetBrands()
	return FindMatch(cardNumber, brandsData)
}

func FindIssuer(cardNumber string) string {
	issuersData := GetIssuers()
	return FindMatch(cardNumber, issuersData)
}
