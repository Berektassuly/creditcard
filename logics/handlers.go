package logics

import (
	"bufio"
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
		if IsValid(number) {
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

	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла брендов: %v\n", err)
		os.Exit(1)
	}

	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла эмитентов: %v\n", err)
		os.Exit(1)
	}

	processNumbers(numbers, useStdin, func(number string) bool {
		fmt.Println(number)
		isValid := IsValid(number)
		validityString := "no"
		if isValid {
			validityString = "yes"
		}

		brand := FindMatch(number, brandData)
		issuer := FindMatch(number, issuerData)

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

	for flag, value := range flags {
		if value == "" {
			fmt.Fprintf(os.Stderr, "Ошибка: Отсутствует обязательный флаг %s\n", flag)
			os.Exit(1)
		}
	}

	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла брендов: %v\n", err)
		os.Exit(1)
	}
	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ошибка чтения файла эмитентов: %v\n", err)
		os.Exit(1)
	}

	number, err := Issue(brandData, issuerData, flags["--brand"], flags["--issuer"])
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
	fmt.Println(number)
}

func extractValues(args []string, flags map[string]string) (values []string, useStdin bool) {
	for _, arg := range args {
		if strings.HasPrefix(arg, "--") {
			if arg == "--stdin" {
				useStdin = true
				continue
			}
			if arg == "--pick" {
				if flags != nil {
					flags["--pick"] = "true"
				}
				continue
			}
			parts := strings.SplitN(arg, "=", 2)
			if len(parts) == 2 && flags != nil {
				if _, ok := flags[parts[0]]; ok {
					flags[parts[0]] = parts[1]
				}
			}
		} else {
			values = append(values, arg)
		}
	}
	return
}


func processNumbers(numbers []string, useStdin bool, processor func(string) bool) {
	var overallSuccess = true
	var itemsProcessed = 0

	processFunc := func(number string) {
		itemsProcessed++
		if !processor(number) {
			overallSuccess = false
		}
	}

	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		for scanner.Scan() {
			processFunc(scanner.Text())
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

	if itemsProcessed > 0 && !overallSuccess {
		os.Exit(1)
	}
}
