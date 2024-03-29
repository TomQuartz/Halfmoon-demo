package main

import (
	"log"
	"os"
	"strconv"
	"sync"
	"time"

	"math/rand"

	"github.com/aws/aws-sdk-go/service/dynamodb/expression"
	"github.com/eniac/Beldi/internal/utils"
	"github.com/eniac/Beldi/pkg/cayonlib"

	"cs.utexas.edu/zjia/faas"
)

const table = "batching"

var nKeys = 10000
var valueSize = 256 // bytes
var value string

var nOps float64
var readRatio float64
var nReads int
var sleepDuration = 5 * time.Millisecond
var batchSize int

func init() {
	if nk, err := strconv.Atoi(os.Getenv("NUM_KEYS")); err == nil {
		nKeys = nk
	} else {
		panic("invalid NUM_KEYS")
	}
	if vs, err := strconv.Atoi(os.Getenv("VALUE_SIZE")); err == nil {
		valueSize = vs
	} else {
		panic("invalid VALUE_SIZE")
	}
	if ops, err := strconv.ParseFloat(os.Getenv("NUM_OPS"), 64); err == nil {
		nOps = ops
	} else {
		panic("invalid NUM_OPS")
	}
	rr, err := strconv.ParseFloat(os.Getenv("READ_RATIO"), 64)
	if err != nil || rr < 0 || rr > 1 {
		panic("invalid READ_RATIO")
	} else {
		readRatio = rr
	}
	if bs, err := strconv.Atoi(os.Getenv("BATCH_SIZE")); err == nil {
		batchSize = bs
	} else {
		panic("invalid BATCH_SIZE")
	}
	nReads = int(nOps * readRatio)
	log.Printf("[INFO] nKeys=%d, valueSize=%d, nOps=%d, readRatio=%.2f, nReads=%d", nKeys, valueSize, int(nOps), readRatio, nReads)

	value = utils.RandomString(valueSize)
	rand.Seed(time.Now().UnixNano())
}

func Handler(env *cayonlib.Env) interface{} {
	var wg sync.WaitGroup
	if cayonlib.TYPE == "WRITELOG" { // halfmoon-read
		for i := 0; i < nReads; i++ {
			cayonlib.Read(env, table, strconv.Itoa(rand.Intn(nKeys)))
		}
		writeSet := []int{}
		nWrites := int(nOps) - nReads
		for i := 0; i < nWrites; i++ {
			writeKey := rand.Intn(nKeys)
			cayonlib.BatchWrite(env, table, strconv.Itoa(writeKey), map[expression.NameBuilder]expression.OperandBuilder{
				expression.Name("V"): expression.Value(value),
			}, &wg)
			writeSet = append(writeSet, writeKey)
			if (i + 1) % batchSize == 0 {
				wg.Wait()
			}
		}
		if nWrites % batchSize != 0 {
			wg.Wait()
		}
		return writeSet
	} else { // halfmoon-write
		for i := 0; i < nReads; i++ {
			cayonlib.BatchRead(env, table, strconv.Itoa(rand.Intn(nKeys)), &wg)
			if (i + 1) % batchSize == 0 {
				wg.Wait()
			}
		}
		if nReads % batchSize != 0 {
			wg.Wait()
		}
		writeSet := []int{}
		for i := 0; i < int(nOps) - nReads; i++ {
			writeKey := rand.Intn(nKeys)
			cayonlib.Write(env, table, strconv.Itoa(writeKey), map[expression.NameBuilder]expression.OperandBuilder{
				expression.Name("V"): expression.Value(value),
			}, false)
			writeSet = append(writeSet, writeKey)
		}
	}
	return nil
}

func main() {
	faas.Serve(cayonlib.CreateFuncHandlerFactory(Handler))
}
