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
	// var validBrandPrefixes []string
	// for prefix, name := range brandData {
	// 	if name == targetBrand {
	// 		validBrandPrefixes = append(validBrandPrefixes, prefix)
	// 	}
	// }
	// if len(validBrandPrefixes) == 0 {
	// 	return "", fmt.Errorf("бренд '%s' не найден", targetBrand)
	// }
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
	lenght := 16
	if targetBrand == "Amex" {
		lenght = 15
	}
	randomDigitsCount := lenght - len(issuerPrefix) - 1

	if randomDigitsCount < 0 {
		return "", fmt.Errorf("эмитент '%s' слишком длинный для генерации номера", targetIssuer)
	}
	var builder strings.Builder
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	builder.WriteString(issuerPrefix)
	for i := 0; i < randomDigitsCount; i++ {
		builder.WriteString(strconv.Itoa(r.Intn(10)))
	}
	baseNumber := builder.String()
	checkDigit := CalculateLuhnDigit(baseNumber)
	return baseNumber + checkDigit, nil
}
