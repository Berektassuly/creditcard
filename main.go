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
	cardNumber := os.Args[1]
	if logics.IsValid(cardNumber) {
		// По заданию нужно выводить "OK"
		fmt.Println("OK")
		os.Exit(0)
	} else {
		// По заданию нужно выводить "INCORRECT" в stderr
		fmt.Fprintln(os.Stderr, "INCORRECT")
		os.Exit(1)
	}
}
