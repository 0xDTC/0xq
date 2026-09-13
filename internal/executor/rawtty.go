package executor

import "golang.org/x/sys/unix"

var savedTermios *unix.Termios

// setRawMode drops the tty into non-canonical, no-echo mode so a
// single keystroke returns immediately (no Enter required).
func setRawMode(fd int) error {
	t, err := unix.IoctlGetTermios(fd, unix.TCGETS)
	if err != nil {
		return err
	}
	savedTermios = &unix.Termios{}
	*savedTermios = *t
	raw := *t
	// Disable canonical mode + echo.
	raw.Lflag &^= unix.ICANON | unix.ECHO
	raw.Cc[unix.VMIN] = 1
	raw.Cc[unix.VTIME] = 0
	return unix.IoctlSetTermios(fd, unix.TCSETS, &raw)
}

// restoreMode puts the tty back the way we found it.
func restoreMode(fd int) {
	if savedTermios == nil {
		return
	}
	_ = unix.IoctlSetTermios(fd, unix.TCSETS, savedTermios)
	savedTermios = nil
}
