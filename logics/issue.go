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
		return "", fmt.Errorf("эмитент не найден: %s", targetIssuer)
	}
	brandFound := false
	var brandPrefix string
	for _, item := range brandData {
		if item.Name == targetBrand {
			brandFound = true
			brandPrefix = item.Prefix
			break
		}
	}
	if !brandFound {
		return "", fmt.Errorf("бренд не найден: %s", targetBrand)
	}
	if !isValidPrefix(brandPrefix) || !isValidPrefix(issuerPrefix) {
		return "", fmt.Errorf("неправильный формат префикса")
	}
	isCompatible := strings.HasPrefix(issuerPrefix, brandPrefix) || strings.HasPrefix(brandPrefix, issuerPrefix)
	if !isCompatible {
		return "", fmt.Errorf("бренд '%s' и эмитент '%s' несовместимы", targetBrand, targetIssuer)
	}
	var basePrefix string
	if len(issuerPrefix) >= len(brandPrefix) {
		if !strings.HasPrefix(issuerPrefix, brandPrefix) {
			return "", fmt.Errorf("бренд %s несовместим с эмитентом %s", targetBrand, targetIssuer)
		}
		basePrefix = issuerPrefix
	} else {
		if !strings.HasPrefix(brandPrefix, issuerPrefix) {
			return "", fmt.Errorf("бренд %s несовместим с эмитентом %s", targetBrand, targetIssuer)
		}
		basePrefix = brandPrefix
	}
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	var length int
	switch targetBrand {
	case "AMEX":
		length = 15
	case "VISA":
		lengths := []int{13, 16}
		length = lengths[r.Intn(len(lengths))]
	case "MASTERCARD":
		length = 16
	default:
		length = 16
	}
	randomDigitsCount := length - len(basePrefix) - 1
	if randomDigitsCount < 0 {
		return "", fmt.Errorf("префикс слишком длинный для целевой длины")
	}
	var builder strings.Builder
	builder.WriteString(basePrefix)
	for i := 0; i < randomDigitsCount; i++ {
		builder.WriteString(strconv.Itoa(r.Intn(10)))
	}
	baseNumber := builder.String()
	checkDigit := CalculateLuhnDigit(baseNumber)
	return baseNumber + checkDigit, nil
}

func isValidPrefix(prefix string) bool {
	if prefix == "" {
		return false
	}
	for _, char := range prefix {
		if char < '0' || char > '9' {
			return false
		}
	}
	return true
}
