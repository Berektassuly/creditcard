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
	for _, item := range issuerData {
		if item.Name == targetIssuer {
			issuerPrefix = item.Prefix
			break
		}
	}

	if issuerPrefix == "" {
		return "", fmt.Errorf("эмитент '%s' не найден", targetIssuer)
	}

	isBrandValidForIssuer := false
	for _, item := range brandData {
		if item.Name == targetBrand {
			if strings.HasPrefix(issuerPrefix, item.Prefix) {
				isBrandValidForIssuer = true
				break
			}
		}
	}

	if !isBrandValidForIssuer {
		return "", fmt.Errorf("бренд '%s' не подходит для эмитента '%s'", targetBrand, targetIssuer)
	}


	length := 16
	if targetBrand == "AMEX" {
		length = 15
	}
	randomDigitsCount := length - len(issuerPrefix) - 1

	if randomDigitsCount < 0 {
		return "", fmt.Errorf("префикс эмитента '%s' слишком длинный для генерации номера", issuerPrefix)
	}
	
	rand.Seed(time.Now().UnixNano())
	var builder strings.Builder

	builder.WriteString(issuerPrefix)
	for i := 0; i < randomDigitsCount; i++ {
		builder.WriteString(strconv.Itoa(rand.Intn(10)))
	}
	baseNumber := builder.String()
	checkDigit := CalculateLuhnDigit(baseNumber)
	return baseNumber + checkDigit, nil
}
