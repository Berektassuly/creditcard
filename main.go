package main

import (
	"creditcard/logics"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Ошибка: Необходимо передать номер карты в качестве аргумента.")
		os.Exit(1)
	}

	command := os.Args[1]
	switch command {
	case "validate":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Ошибка: Необходимо передать номер карты для проверки.")
			os.Exit(1)
		}

		cardNumber := os.Args[2]

		if logics.IsValid(cardNumber) {
			// По заданию нужно выводить "OK"
			fmt.Println("OK")
			os.Exit(0)
		} else {
			// По заданию нужно выводить "INCORRECT" в stderr
			fmt.Fprintln(os.Stderr, "INCORRECT")
			os.Exit(1)
		}
	
	default:
		fmt.Fprintf(os.Stderr, "Ошибка: Неизвестная команда '%s'.\n", command)
		os.Exit(1)
	}
}
