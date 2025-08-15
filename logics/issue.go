package logics

import (
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"time"
)

func Issue(brandData []BrandOrIssuer, issuerData []BrandOrIssuer, targetBrand, targetIssuer string) (string, error) {
	var issuerPrefix string
	issuerFound := false
	for _, item := range issuerData {
		if item.Name == targetIssuer {
			issuerPrefix = item.Prefix
			issuerFound = true
			break
		}
	}
	if !issuerFound {
		return "", fmt.Errorf("эмитент '%s' не найден", targetIssuer)
	}

	brandFound := false
	isCompatible := false
	for _, item := range brandData {
		if item.Name == targetBrand {
			brandFound = true
			if strings.HasPrefix(issuerPrefix, item.Prefix) {
				isCompatible = true
				break
			}
		}
	}

	if !brandFound {
		return "", fmt.Errorf("бренд '%s' не найден", targetBrand)
	}
	if !isCompatible {
		return "", fmt.Errorf("бренд '%s' не подходит для эмитента '%s'", targetBrand, targetIssuer)
	}

	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	var length int
	switch targetBrand {
	case "AMEX":
		length = 15
	case "VISA":
		lengths := []int{13, 16}
		length = lengths[r.Intn(len(lengths))]
	default:
		length = 16
	}

	randomDigitsCount := length - len(issuerPrefix) - 1
	if randomDigitsCount < 0 {
		return "", fmt.Errorf("префикс эмитента '%s' (%s) слишком длинный", targetIssuer, issuerPrefix)
	}

	var builder strings.Builder
	builder.WriteString(issuerPrefix)
	for i := 0; i < randomDigitsCount; i++ {
		builder.WriteString(strconv.Itoa(r.Intn(10)))
	}
	baseNumber := builder.String()
	checkDigit := CalculateLuhnDigit(baseNumber)
	return baseNumber + checkDigit, nil
}
