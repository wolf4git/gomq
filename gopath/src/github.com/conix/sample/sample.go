package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func printDir(root string) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		files = append(files, path)
		return nil
	})
	if err != nil {
		panic(err)
	}
	for _, file := range files {
		fmt.Println(file)
	}
}

func main() {
	fmt.Printf("\nHello from Wolfs-Sample go-prog!")
	fmt.Printf("\nList all environment-vars\n")
	for _, pair := range os.Environ() {
		fmt.Printf("\n... %v", pair)
	}
	fmt.Printf("\n\n...Sleep for ever, display ever 3min an info")

	for {
		fmt.Println("Current date and time is: ", time.Now().String())
		duration := time.Duration(60*3) * time.Second // Pause for 10 seconds
		time.Sleep(duration)
	}

	// fmt.Print("Press 'Enter' to continue...")
	// bufio.NewReader(os.Stdin).ReadBytes('\n')

	// fmt.Printf("\nList directory of GOPATH\n")
	// printDir(os.Getenv("GOPATH"))
	//	fmt.Printf("\n\nList directory of LIBPATH\n")
	//	printDir(os.Getenv("LIBPATH"))
}
