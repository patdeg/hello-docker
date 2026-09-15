package main

import (
	"fmt"
	"os"
)

func main() {
	hostname, _ := os.Hostname()
	fmt.Printf("Hello from a compiled Go binary, running in container %s!\n", hostname)
}
