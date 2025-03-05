package main

import (
	"fmt"
	"net/http"
	"strconv"
	"sync"
)

const (
	svcPort = ":8080"
)

var (
	logMemBytes int
	mutex       sync.Mutex
)

func main() {
	http.HandleFunc("/add", addHandler)
	http.HandleFunc("/value", valueHandler)
	http.HandleFunc("/reset", resetHandler)

	fmt.Printf("Server is listening on port %s\n", svcPort)
	if err := http.ListenAndServe(svcPort, nil); err != nil {
		fmt.Printf("Error starting server: %s\n", err)
	}
}

func addHandler(w http.ResponseWriter, r *http.Request) {
	// Get the "value" query parameter
	valueStr := r.URL.Query().Get("value")
	if valueStr == "" {
		http.Error(w, "Missing 'value' parameter", http.StatusBadRequest)
		return
	}

	// Convert the value to an integer
	value, err := strconv.Atoi(valueStr)
	if err != nil {
		http.Error(w, "Invalid 'value' parameter", http.StatusBadRequest)
		return
	}

	// Safely add the value to the local variable
	mutex.Lock()
	logMemBytes += value
	mutex.Unlock()

	fmt.Fprintf(w, "Added %d bytes to the log memory monitor. New value: %d\n", value, logMemBytes)
}

func valueHandler(w http.ResponseWriter, r *http.Request) {
	// Safely retrieve the current value of the local variable
	mutex.Lock()
	currentValue := logMemBytes
	mutex.Unlock()

	fmt.Fprintf(w, "%d\n", currentValue)
}

func resetHandler(w http.ResponseWriter, r *http.Request) {
	// Safely reset the local variable
	mutex.Lock()
	logMemBytes = 0
	mutex.Unlock()

	fmt.Fprintln(w, "Log memory monitor has been reset")
}
