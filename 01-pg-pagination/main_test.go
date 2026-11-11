package main

import "testing"

func TestX(t *testing.T) {}

func BenchmarkX(b *testing.B) {
	for b.Loop() {
	}
}
