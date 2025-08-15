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
		fmt.Fprintln(os.Stderr, "INCORRECT")
		os.Exit(1)
	}
	anyIncorrect := false
	var okMessages []string
	process := func(number string) {
		if number == "" || !IsValid(number) {
			fmt.Fprintln(os.Stderr, "INCORRECT")
			anyIncorrect = true
		} else {
			okMessages = append(okMessages, "OK")
		}
	}
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		for scanner.Scan() {
			process(scanner.Text())
		}
	} else {
		for _, number := range numbers {
			process(number)
		}
	}
	if len(okMessages) > 0 {
		fmt.Print(strings.Join(okMessages, "\n"))
	}

	if anyIncorrect {
		os.Exit(1)
	}
}

func HandleGenerate(args []string) {
	flags := map[string]string{"--pick": "false"}
	patterns, _ := extractValues(args, flags)
	if len(patterns) != 1 {
		os.Exit(1)
	}
	generated, err := Generate(patterns[0])
	if err != nil {
		os.Exit(1)
	}
	if flags["--pick"] == "true" {
		picked, err := PickRandom(generated)
		if err != nil {
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
		os.Exit(1)
	}
	if !useStdin && len(numbers) == 0 {
		os.Exit(1)
	}
	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		os.Exit(1)
	}
	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		os.Exit(1)
	}
	var outputs []string
	process := func(number string) {
		brand, issuer, validityString := "-", "-", "no"
		if IsValid(number) {
			validityString = "yes"
			brand = FindMatch(number, brandData)
			issuer = FindMatch(number, issuerData)
		}
		output := fmt.Sprintf("%s\nCorrect: %s\nCard Brand: %s\nCard Issuer: %s", number, validityString, brand, issuer)
		outputs = append(outputs, output)
	}
	if useStdin {
		scanner := bufio.NewScanner(os.Stdin)
		scanner.Split(bufio.ScanWords)
		for scanner.Scan() {
			process(scanner.Text())
		}
		if err := scanner.Err(); err != nil && err != io.EOF {
			os.Exit(1)
		}
	} else {
		for _, number := range numbers {
			process(number)
		}
	}
	fmt.Print(strings.Join(outputs, "\n"))
}

func HandleIssue(args []string) {
	flags := map[string]string{"--brands": "", "--issuers": "", "--brand": "", "--issuer": ""}
	extractValues(args, flags)
	for _, value := range flags {
		if value == "" {
			os.Exit(1)
		}
	}
	brandData, err := ReadDataFile(flags["--brands"])
	if err != nil {
		os.Exit(1)
	}
	issuerData, err := ReadDataFile(flags["--issuers"])
	if err != nil {
		os.Exit(1)
	}

	number, err := Issue(brandData, issuerData, flags["--brand"], flags["--issuer"])
	if err != nil {
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
