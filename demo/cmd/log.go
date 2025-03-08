package main

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"sync"

	"k8s.io/klog/v2"
)

const (
	logMetricsServer = "http://localhost:30180" + "/add"
	sendLogMetrics   = true
	minLogSizeBytes  = 256
)

type LogEntry struct {
	seqnum int64
	value  any
}

type LogStorage struct {
	seqnum  int64
	mu      sync.Mutex
	entries map[string][]LogEntry
}

func NewLogStorage() *LogStorage {
	return &LogStorage{
		seqnum:  1,
		entries: make(map[string][]LogEntry),
	}
}

func (d *LogStorage) Append(tags []string, value any) int64 {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.seqnum++
	entry := LogEntry{
		seqnum: d.seqnum,
		value:  value,
	}
	for _, tag := range tags {
		d.entries[tag] = append(d.entries[tag], entry)
	}
	go func() {
		if !sendLogMetrics {
			return
		}
		// send log metrics
		params := url.Values{}
		params.Add("value", strconv.Itoa(minLogSizeBytes))

		// Build the complete URL
		fullURL := fmt.Sprintf("%s?%s", logMetricsServer, params.Encode())

		// Make the GET request
		resp, err := http.Get(fullURL)
		if err != nil {
			klog.Errorf("Error making request: %v", err)
			return
		}
		defer resp.Body.Close()

		// Check the response status code
		if resp.StatusCode != http.StatusOK {
			klog.Errorf("Error: received status code %d\n", resp.StatusCode)
			return
		}
	}()
	return d.seqnum
}

func (d *LogStorage) Read(tag string, seqnum int64) ([]LogEntry, bool) {
	d.mu.Lock()
	defer d.mu.Unlock()
	logSequence, ok := d.entries[tag]
	if !ok {
		return nil, false
	}
	if seqnum == 0 {
		return logSequence, true
	}
	for i := len(logSequence) - 1; i >= 0; i-- {
		if logSequence[i].seqnum <= seqnum {
			return []LogEntry{logSequence[i]}, true
		}
	}
	return nil, false
}
