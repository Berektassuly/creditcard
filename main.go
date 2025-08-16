package main

import (
	"creditcard/logics"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Ошибка: Не указана команда. Используйте 'validate', 'generate', 'information' или 'issue'.")
		os.Exit(1)
	}
	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "validate":
		logics.HandleValidate(args)
	case "generate":
		logics.HandleGenerate(args)
	case "information":
		logics.HandleInformation(args)
	case "issue":
		logics.HandleIssue(args)
	default:
		fmt.Fprintf(os.Stderr, "Неизвестная команда: %s\n", command)
		os.Exit(1)
	}
}
