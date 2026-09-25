package main

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa
#include "editor.h"
*/
import "C"

import "runtime"

func main() {
	runtime.LockOSThread()
	C.RunVZEditor()
}
