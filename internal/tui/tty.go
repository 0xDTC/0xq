package tui

import "os"

// openTTY returns the controlling terminal opened R/W. Both bubbletea
// input and output get routed through this handle so stdout remains
// clean for callers that capture it (Ctrl+Q widget, `q --inline`).
//
// Falls back to os.Stdin/os.Stderr wrapped in a single ReadWriter if
// /dev/tty can't be opened — extremely rare (chroots without /dev,
// mostly). In that fallback the alt-screen escapes leak through the
// stderr side, which is at least visible to the user.
func openTTY() (*os.File, error) {
	f, err := os.OpenFile("/dev/tty", os.O_RDWR, 0)
	if err != nil {
		return nil, err
	}
	return f, nil
}
