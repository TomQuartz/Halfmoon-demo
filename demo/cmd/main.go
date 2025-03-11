package main

import (
	"fmt"
	"time"
)

var db *DemoDB[int]
var log *LogStorage

func init() {
	log = NewLogStorage()
	db = NewDemoDB[int](log)
}

func main() {
	fmt.Printf("\n\n################### UNSAFE ###################n\n")

	ts1 := time.Now().Format(time.TimeOnly)
	fmt.Printf("\nInitial memory usage -> 1000B at %s\n", ts1)
	unsafeUpdateMetric(1000, "v0")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Testing unsafe monitor (w/o logging) at %s\n", ts1)
	unsafeMonitor(ts1, true)
	time.Sleep(2 * time.Second)

	fmt.Printf("\nUpdating memory usage -> 100B at %s\n", time.Now().Format(time.TimeOnly))
	unsafeUpdateMetric(100, "v1")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Retrying unsafe monitor (w/o logging)\n")
	unsafeMonitor(ts1, false)
	time.Sleep(2 * time.Second)

	fmt.Printf("\n\n################### HALFMOON ###################\n\n")

	ts2 := time.Now().Format(time.TimeOnly)
	fmt.Printf("\nInitial metric -> 1000B at %s\n", ts2)
	halfmoonUpdateMetric(1000, "v0")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Testing halfmoon monitor (w/ logging) at %s\n", ts2)
	halfmoonMonitor(ts2, true)
	time.Sleep(2 * time.Second)

	fmt.Printf("\nUpdating memory usage -> 100B at %s\n", time.Now().Format(time.TimeOnly))
	halfmoonUpdateMetric(100, "v1")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Retrying halfmoon monitor (w/ logging)\n")
	halfmoonMonitor(ts2, false)
	time.Sleep(2 * time.Second)
}

func unsafeMonitor(ts string, crash bool) {
	observedMetric, _ := db.UnsafeRead("metric")
	if observedMetric >= 1000 {
		fmt.Printf("High memory usage detected at %s (metric=%vB)\n", ts, observedMetric)
	} else {
		fmt.Printf("No high memory warning (metric=%vB)\n", observedMetric)
	}
	if crash {
		fmt.Printf("Detector crashed\n")
		return
	}
	if observedMetric >= 1000 {
		db.UnsafeWrite(ts, observedMetric)
		fmt.Printf("Warning recorded for %s\n", ts)
	}
}

func halfmoonMonitor(ts string, crash bool) {
	seqnum := halfmoonInit(ts)
	observedMetric, _ := db.HMRead("metric", seqnum)
	if observedMetric >= 1000 {
		fmt.Printf("High memory usage detected at %s (metric=%vB)\n", ts, observedMetric)
	} else {
		fmt.Printf("No high memory warning (metric=%vB)\n", observedMetric)
	}
	if crash {
		fmt.Printf("Detector crashed\n")
		return
	}
	if observedMetric >= 1000 {
		_ = db.HMWrite(ts, observedMetric, fmt.Sprintf("%d", seqnum))
		fmt.Printf("Warning recorded for %s\n", ts)
	}
}

func halfmoonInit(id string) int64 {
	seqnum := int64(0)
	if entries, ok := log.Read(id, 0); ok {
		seqnum = entries[0].seqnum
	} else {
		seqnum = log.Append([]string{id}, "init")
	}
	return seqnum
}

func unsafeUpdateMetric(value int, _ string) {
	db.UnsafeWrite("metric", value)
}

func halfmoonUpdateMetric(value int, version string) {
	db.HMWrite("metric", value, version)
}
