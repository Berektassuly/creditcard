package main

import (
	"fmt"
	"os"

	"creditcard/logics"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "отсутствует команда")
		os.Exit(1)
	}
	command := os.Args[1]
	args := os.Args[2:]
	if len(os.Args) > 2 {
		validCommands := []string{"validate", "generate", "information", "issue"}
		isValidCommand := false
		for _, validCmd := range validCommands {
			if command == validCmd {
				isValidCommand = true
				break
			}
		}
		if isValidCommand {
			for _, validCmd := range validCommands {
				if len(args) > 0 && args[0] == validCmd {
					fmt.Fprintln(os.Stderr, "неправильная комбинация команд")
					os.Exit(1)
				}
			}
		}
	}
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
		fmt.Fprintf(os.Stderr, "неизвестная команда: %s\n", command)
		os.Exit(1)
	}
}
