package logics

import (
	"bufio"
	"creditcard/logics"
	"fmt"
	"io"
	"os"
	"strings"
)

func HandleValidate(args []string) {
	numbers, useStdin := extractValues(args, nil)
	if !useStdin && len(numbers) == 0 {
		fmt.Fprintln(os.Stderr, "Ошибка: Необходимо передать номер карты для проверки или использовать флаг --stdin.")
		os.Exit(1)
	}

	processNumbers(numbers, useStdin, func(number string) bool {
		if logics.IsValid(number) {
			fmt.Println("OK")
			return true
		}
		fmt.Fprintln(os.Stderr, "INCORRECT")
		return false
	})
}

func HandleInformation(args []string) {
	flags := map[string]string{"--brands": "", "--issuers": ""}
	numbers, useStdin := extractValues(args, flags)

	if flags["--brands"] == "" || flags["--issuers"] == "" {
		fmt.Fprintln(os.Stderr, "Ошибка: Необходимо указать файлы с помощью --brands=file.txt и --issuers=file.txt.")
		os.Exit(1)
	}
	if !useStdin && len(numbers) == 0 {
		fmt.Fprintln(os.Stderr, "Ошибка: Необходимо передать номер карты или использовать флаг --stdin.")
		os.Exit(1)
	}

	brandData, err := logics.ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла брендов: %v\n", err)
		os.Exit(1)
	}

	issuerData, err := logics.ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла эмитентов: %v\n", err)
		os.Exit(1)
	}

	processNumbers(numbers, useStdin, func(number string) bool {
		fmt.Println(number)
		isValid := logics.IsValid(number)
		validityString := "no"
		if isValid {
			validityString = "yes"
		}

		brand := logics.FindMatch(number, brandData)
		issuer := logics.FindMatch(number, issuerData)

		fmt.Printf("Correct: %s\n", validityString)
		fmt.Printf("Card Brand: %s\n", brand)
		fmt.Printf("Card Issuer: %s\n", issuer)
		if len(numbers) > 1 || useStdin {
			fmt.Println()
		}
		return isValid
	})
}

func HandleIssue(args []string) {
	flags := map[string]string{"--brands": "", "--issuers": "", "--brand": "", "--issuer": ""}
	extractValues(args, flags)

	for flag, valuse := range flags {
		if value == "" {
			fmt.Fprintf(os.Stderr, "Ошибка: Отсутствует обязательный флаг %s.\n", flag)
			os.Args(1)
		}
	}
	brandData, err := logics.ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла брендов: %v\n", err)
		os.Exit(1)
	}
	issuerData,err := logics.ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла эмитентов: %v\n", err)
		os.Exit(1)
	}
	number, err := logics.Issuue(brandData, issuerData, flags["--brand"], flags["--issuer"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
	fmt.Println(number)
}

func ExtractNumbers(args []string, flags map[string]string) (values []string, useStdin bool) {
	for _, args := range args {
		if strings.HasPrefix() {
			if args == "--stdin" {
				useStdin = true
				continue
			}
		}
			if args == "--pick" {
				if flags != nil {
					flags["--pick"] = "true"
					continue
				}
			}
			parts := strings.SplitN(args, "=", 2)
			if len(parts) == 2 && flags != nil{
				if _, ok := flags[parts[0]]; ok {
					flags[parts[0]] = parts[1]
				} else {
					fmt.Fprintf(os.Stderr, "Ошибка: Неизвестный флаг '%s'.\n", parts[0])
					os.Exit(1)
				}
			}
	}
}

func ProcessNumber(numbers []string, useStdin bool, processor func(string) bool) {
	var overallSuccess = true
	var itemProcessed = 0

	processFunc := func(number string) {
		itemProcessed++
		if !processor(number) {
			overallSuccess = false
		}
	}
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanLines)
		for scanner.Scan() {
			processFunc(scannner.Text())
		}
		if err := scanner.Err(); err != nil && err != io.EOF {
			fmt.Fprintf(os.Stderr, "Ошибка чтения из stdin: %v\n", err)
			os.Exit(1)
		}
	} else {
		for _, number := range numbers {
			processFunc(number)
		}
	}
	
	if itemProcessed >0 && !overallSuccess {
		os.Exit(1)
	}
}