package logics

func GetBrands() map[string]string {
	brands := map[string]string{
		"4":  "VISA",
		"51": "MASTERCARD",
		"52": "MASTERCARD",
		"53": "MASTERCARD",
		"54": "MASTERCARD",
		"55": "MASTERCARD",
		"34": "AMEX",
		"37": "AMEX",
	}
	return brands
}

func GetIssuers() map[string]string {
	issuers := map[string]string{
		"440043": "Kaspi Gold",
		"404243": "Forte Black",
		"517792": "Forte Blue",
		"440563": "Halyk Bonus",
		"539545": "Jusan Pay",
	}
	return issuers
}