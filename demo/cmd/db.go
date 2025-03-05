package main

import (
	"fmt"
	"sync"
)

type AddableValueType interface {
	~int | ~float64 | ~string
}

type DemoDB[T AddableValueType] struct {
	log     *LogStorage
	mu      sync.Mutex
	entries map[string]T
}

func NewDemoDB[T AddableValueType](log *LogStorage) *DemoDB[T] {
	return &DemoDB[T]{
		log:     log,
		entries: make(map[string]T),
	}
}

func (d *DemoDB[T]) UnsafeWrite(key string, value T) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.entries[key] = value
}

func (d *DemoDB[T]) UnsafeRead(key string) (T, bool) {
	d.mu.Lock()
	defer d.mu.Unlock()
	v, ok := d.entries[key]
	return v, ok
}

func (d *DemoDB[T]) HMRead(key string, seqnum int64) (T, bool) {
	entries, ok := d.log.Read(key, seqnum)
	if !ok {
		var zero T
		return zero, false
	}
	versionedKey := entries[0].value.(string)
	return d.UnsafeRead(versionedKey)
}

func (d *DemoDB[T]) HMWrite(key string, value T, version string) int64 {
	versionedKey := fmt.Sprintf("%s-%s", key, version)
	d.UnsafeWrite(versionedKey, value)
	if entries, ok := d.log.Read(key, 0); ok {
		for i := len(entries) - 1; i >= 0; i-- {
			if entries[i].value.(string) == versionedKey {
				return entries[i].seqnum
			}
		}
	}
	return d.log.Append([]string{key}, versionedKey)
}
