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
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		hasInput := false
		anyIncorrect := false
		for scanner.Scan() {
			hasInput = true
			number := strings.ReplaceAll(scanner.Text(), " ", "")
			if number == "" || !IsValid(number) {
				fmt.Fprintln(os.Stderr, "INCORRECT")
				anyIncorrect = true
			} else {
				fmt.Println("OK")
			}
		}
		if err := scanner.Err(); err != nil && err != io.EOF {
			fmt.Fprintln(os.Stderr, "INCORRECT")
			os.Exit(1)
		}
		if !hasInput {
			fmt.Fprintln(os.Stderr, "INCORRECT")
			os.Exit(1)
		}
		if anyIncorrect {
			os.Exit(1)
		}
		return
	}
	if len(numbers) == 0 {
		fmt.Fprintln(os.Stderr, "INCORRECT")
		os.Exit(1)
	}
	anyIncorrect := false
	for _, number := range numbers {
		cleanNumber := strings.ReplaceAll(number, " ", "")
		if cleanNumber == "" || !IsValid(cleanNumber) {
			fmt.Fprintln(os.Stderr, "INCORRECT")
			anyIncorrect = true
		} else {
			fmt.Println("OK")
		}
	}
	if anyIncorrect {
		os.Exit(1)
	}
}

func HandleGenerate(args []string) {
	flags := map[string]string{"--pick": "false"}
	patterns, useStdin := extractValues(args, flags)
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		hasInput := false
		for scanner.Scan() {
			hasInput = true
			pattern := scanner.Text()
			generated, err := Generate(pattern)
			if err != nil {
				fmt.Fprintln(os.Stderr, err.Error())
				os.Exit(1)
			}
			if flags["--pick"] == "true" {
				picked, err := PickRandom(generated)
				if err != nil {
					fmt.Fprintln(os.Stderr, err.Error())
					os.Exit(1)
				}
				fmt.Println(picked)
			} else {
				for _, num := range generated {
					fmt.Println(num)
				}
			}
		}
		if !hasInput {
			fmt.Fprintln(os.Stderr, "входные данные не предоставлены")
			os.Exit(1)
		}
		return
	}
	if len(patterns) != 1 {
		fmt.Fprintln(os.Stderr, "требуется ровно один шаблон")
		os.Exit(1)
	}
	generated, err := Generate(patterns[0])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	if flags["--pick"] == "true" {
		picked, err := PickRandom(generated)
		if err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
			os.Exit(1)
		}
		fmt.Println(picked)
	} else {
		for _, num := range generated {
			fmt.Println(num)
		}
	}
}

func HandleInformation(args []string) {
	flags := map[string]string{"--brands": "", "--issuers": ""}
	numbers, useStdin := extractValues(args, flags)
	if flags["--brands"] == "" || flags["--issuers"] == "" {
		fmt.Fprintln(os.Stderr, "требуются оба флага: --brands и --issuers")
		os.Exit(1)
	}
	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		hasInput := false
		for scanner.Scan() {
			hasInput = true
			number := strings.ReplaceAll(scanner.Text(), " ", "")
			processInformationNumber(number, brandData, issuerData)
		}
		if err := scanner.Err(); err != nil && err != io.EOF {
			fmt.Fprintln(os.Stderr, "ошибка чтения stdin")
			os.Exit(1)
		}
		if !hasInput {
			fmt.Fprintln(os.Stderr, "входные данные не предоставлены")
			os.Exit(1)
		}
		return
	}
	if len(numbers) == 0 {
		fmt.Fprintln(os.Stderr, "номера карт не предоставлены")
		os.Exit(1)
	}
	for i, number := range numbers {
		cleanNumber := strings.ReplaceAll(number, " ", "")
		processInformationNumber(cleanNumber, brandData, issuerData)
		if i < len(numbers)-1 {
			fmt.Println()
		}
	}
}

func processInformationNumber(number string, brandData, issuerData []BrandOrIssuer) {
	brand, issuer, validityString := "-", "-", "no"
	if IsValid(number) {
		validityString = "yes"
		if strings.Trim(number, "0") == "" {
			validityString = "no"
		}
		brand = FindMatch(number, brandData)
		issuer = FindMatch(number, issuerData)
	}
	fmt.Printf("%s\nCorrect: %s\nCard Brand: %s\nCard Issuer: %s",
		number, validityString, brand, issuer)
}

func HandleIssue(args []string) {
	flags := map[string]string{"--brands": "", "--issuers": "", "--brand": "", "--issuer": ""}
	remainingArgs, useStdin := extractValues(args, flags)
	if len(remainingArgs) > 0 {
		fmt.Fprintln(os.Stderr, "неожиданные аргументы")
		os.Exit(1)
	}
	if useStdin {
		fmt.Fprintln(os.Stderr, "stdin не поддерживается для команды issue")
		os.Exit(1)
	}
	missingFlags := []string{}
	for flagName, value := range flags {
		if value == "" {
			missingFlags = append(missingFlags, flagName)
		}
	}
	if len(missingFlags) > 0 {
		fmt.Fprintln(os.Stderr, ".")
		os.Exit(1)
	}
	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	number, err := Issue(brandData, issuerData, flags["--brand"], flags["--issuer"])
	if err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
	fmt.Println(number)
}

func extractValues(args []string, flags map[string]string) ([]string, bool) {
	var values []string
	useStdin := false
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
	return values, useStdin
}
