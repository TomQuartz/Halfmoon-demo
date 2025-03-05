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

	fmt.Printf("\nInitial metric -> 0 (anomaly=true)\n")
	unsafeUpdateMetric(0, "v0")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Testing unsafe anomaly detector (w/o logging)\n")
	unsafeAnomalyDetector("unsafe", true)
	time.Sleep(2 * time.Second)

	fmt.Printf("\nUpdating metric -> 100 (anomaly=false)\n")
	unsafeUpdateMetric(100, "v1")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Retrying unsafe anomaly detector (w/o logging)\n")
	unsafeAnomalyDetector("unsafe", false)
	time.Sleep(2 * time.Second)

	fmt.Printf("\n\n################### HALFMOON ###################\n\n")

	fmt.Printf("\nInitial metric -> 0 (anomaly=true)\n")
	halfmoonUpdateMetric(0, "v0")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Testing halfmoon anomaly detector (w/ logging)\n")
	halfmoonAnomalyDetector("halfmoon", true)
	time.Sleep(2 * time.Second)

	fmt.Printf("\nUpdating metric -> 100 (anomaly=false)\n")
	halfmoonUpdateMetric(100, "v1")
	time.Sleep(2 * time.Second)

	fmt.Printf("\n-- Retrying halfmoon anomaly detector (w/ logging)\n")
	halfmoonAnomalyDetector("halfmoon", false)
	time.Sleep(2 * time.Second)
}

func unsafeAnomalyDetector(id string, crash bool) {
	observedMetric, _ := db.UnsafeRead("metric")
	if observedMetric < 50 {
		fmt.Printf("Anomaly event detected (metric=%v)\n", observedMetric)
	} else {
		fmt.Printf("No anomaly detected (metric=%v)\n", observedMetric)
	}
	if crash {
		fmt.Printf("Detector crashed\n")
		return
	}
	if observedMetric < 50 {
		db.UnsafeWrite(id, observedMetric)
		fmt.Printf("Event recorded\n")
	}
}

func halfmoonAnomalyDetector(id string, crash bool) {
	seqnum := int64(0)
	func() {
		if entries, ok := log.Read(id, 0); ok {
			seqnum = entries[0].seqnum
		} else {
			seqnum = log.Append([]string{id}, "init")
		}
	}()
	observedMetric, _ := db.HMRead("metric", seqnum)
	if observedMetric < 50 {
		fmt.Printf("Anomaly event detected (metric=%v)\n", observedMetric)
	} else {
		fmt.Printf("No anomaly detected (metric=%v)\n", observedMetric)
	}
	if crash {
		fmt.Printf("Detector crashed\n")
		return
	}
	if observedMetric < 50 {
		seqnum = db.HMWrite(id, observedMetric, fmt.Sprintf("%d", seqnum))
		fmt.Printf("Anomaly recorded\n")
	}
}

func unsafeUpdateMetric(value int, _ string) {
	db.UnsafeWrite("metric", value)
}

func halfmoonUpdateMetric(value int, version string) {
	db.HMWrite("metric", value, version)
}
