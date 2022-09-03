package english_greetings

import "testing"

func TestHelloWorld(t *testing.T) {
	want := "Hello world"
	if got := HelloWorld(); got != want {
		t.Errorf("HelloWorld() = %q, want %q", got, want)
	}
}
