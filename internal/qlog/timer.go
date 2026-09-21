package qlog

import "time"

// timerSleep is separated so the main file doesn't import "time" and
// stays focused on the logging surface.
func timerSleep(ms int) { time.Sleep(time.Duration(ms) * time.Millisecond) }
