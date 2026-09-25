APP_NAME := VZGoEditor
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app

.PHONY: all app run clean test

all: app

app:
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	go build -trimpath -ldflags="-s -w" -o "$(APP_DIR)/Contents/MacOS/$(APP_NAME)" .
	cp Info.plist "$(APP_DIR)/Contents/Info.plist"
	xattr -cr "$(APP_DIR)"
	codesign --force --deep --sign - "$(APP_DIR)"

run: app
	open "$(APP_DIR)"

test:
	go test ./...

clean:
	rm -rf "$(BUILD_DIR)"
