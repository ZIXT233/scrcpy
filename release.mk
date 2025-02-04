# This makefile provides recipes to build a "portable" version of scrcpy for
# Windows.
#
# Here, "portable" means that the client and server binaries are expected to be
# anywhere, but in the same directory, instead of well-defined separate
# locations (e.g. /usr/bin/scrcpy and /usr/share/scrcpy/scrcpy-server).
#
# In particular, this implies to change the location from where the client push
# the server to the device.

.PHONY: default clean \
	test \
	build-server \
	prepare-deps-win32 prepare-deps-win64 \
	build-win32 build-win64 \
	dist-win32 dist-win64 \
	zip-win32 zip-win64 \
	release

GRADLE ?= ./gradlew

TEST_BUILD_DIR := build-test
SERVER_BUILD_DIR := build-server
WIN32_BUILD_DIR := build-win32
WIN64_BUILD_DIR := build-win64
WIN_ARM64_BUILD_DIR := build-win-arm64

DIST := dist
WIN32_TARGET_DIR := scrcpy-win32
WIN64_TARGET_DIR := scrcpy-win64
WIN_ARM64_TARGET_DIR := scrcpy-win-arm64

VERSION := $(shell git describe --tags --always)
WIN32_TARGET := $(WIN32_TARGET_DIR)-$(VERSION).zip
WIN64_TARGET := $(WIN64_TARGET_DIR)-$(VERSION).zip
WIN_ARM64_TARGET := $(WIN_ARM64_TARGET_DIR)-$(VERSION).zip

RELEASE_DIR := release-$(VERSION)

release: clean test build-server zip-win32 zip-win64
	mkdir -p "$(RELEASE_DIR)"
	cp "$(SERVER_BUILD_DIR)/server/scrcpy-server" \
		"$(RELEASE_DIR)/scrcpy-server-$(VERSION)"
	cp "$(DIST)/$(WIN32_TARGET)" "$(RELEASE_DIR)"
	cp "$(DIST)/$(WIN64_TARGET)" "$(RELEASE_DIR)"
	cd "$(RELEASE_DIR)" && \
		sha256sum "scrcpy-server-$(VERSION)" \
			"scrcpy-win32-$(VERSION).zip" \
			"scrcpy-win64-$(VERSION).zip" > SHA256SUMS.txt
	@echo "Release generated in $(RELEASE_DIR)/"

clean:
	$(GRADLE) clean
	rm -rf "$(DIST)" "$(TEST_BUILD_DIR)" "$(SERVER_BUILD_DIR)" \
		"$(WIN32_BUILD_DIR)" "$(WIN64_BUILD_DIR)"

test:
	[ -d "$(TEST_BUILD_DIR)" ] || ( mkdir "$(TEST_BUILD_DIR)" && \
		meson "$(TEST_BUILD_DIR)" -Db_sanitize=address )
	ninja -C "$(TEST_BUILD_DIR)"
	$(GRADLE) -p server check

build-server:
	[ -d "$(SERVER_BUILD_DIR)" ] || ( mkdir "$(SERVER_BUILD_DIR)" && \
		meson "$(SERVER_BUILD_DIR)" --buildtype release -Dcompile_app=false )
	ninja -C "$(SERVER_BUILD_DIR)"

prepare-deps-win32:
	@app/prebuilt-deps/prepare-adb.sh
	@app/prebuilt-deps/prepare-sdl.sh
	@app/prebuilt-deps/prepare-ffmpeg-win32.sh
	@app/prebuilt-deps/prepare-libusb.sh

prepare-deps-win64:
	@app/prebuilt-deps/prepare-adb.sh
	@app/prebuilt-deps/prepare-sdl.sh
	@app/prebuilt-deps/prepare-ffmpeg-win64.sh
	@app/prebuilt-deps/prepare-libusb.sh

prepare-deps-win-arm64:
	@app/prebuilt-deps/prepare-adb.sh
	@app/prebuilt-deps/prepare-sdl-win-arm64.sh
	@app/prebuilt-deps/prepare-ffmpeg-win-arm64.sh
	@app/prebuilt-deps/prepare-libusb-win-arm64.sh

build-win32: prepare-deps-win32
	[ -d "$(WIN32_BUILD_DIR)" ] || ( mkdir "$(WIN32_BUILD_DIR)" && \
		meson "$(WIN32_BUILD_DIR)" \
			--cross-file cross_win32.txt \
			--buildtype release --strip -Db_lto=true \
			-Dcompile_server=false \
			-Dportable=true )
	ninja -C "$(WIN32_BUILD_DIR)"

build-win64: prepare-deps-win64
	[ -d "$(WIN64_BUILD_DIR)" ] || ( mkdir "$(WIN64_BUILD_DIR)" && \
		meson "$(WIN64_BUILD_DIR)" \
			--cross-file cross_win64.txt \
			--buildtype release --strip -Db_lto=true \
			-Dcompile_server=false \
			-Dportable=true )
	ninja -C "$(WIN64_BUILD_DIR)"


build-win-arm64: prepare-deps-win-arm64
	[ -d "$(WIN_ARM64_BUILD_DIR)" ] || ( mkdir "$(WIN_ARM64_BUILD_DIR)" && \
		meson "$(WIN_ARM64_BUILD_DIR)" \
		--cross-file cross_win_arm64.txt \
		--buildtype release --strip -Db_lto=true \
		-Dcompile_server=false \
		-Dportable=true )
	sed -i 's/-Wl,--allow-shlib-undefined//g' "$(WIN_ARM64_BUILD_DIR)/build.ninja"
	ninja -C "$(WIN_ARM64_BUILD_DIR)"

dist-win32: build-server build-win32
	mkdir -p "$(DIST)/$(WIN32_TARGET_DIR)"
	cp "$(SERVER_BUILD_DIR)"/server/scrcpy-server "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp "$(WIN32_BUILD_DIR)"/app/scrcpy.exe "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/data/scrcpy-console.bat "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/scrcpy-noconsole.vbs "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/icon.png "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/data/open_a_terminal_here.bat "$(DIST)/$(WIN32_TARGET_DIR)"
	cp app/prebuilt-deps/data/ffmpeg-win32-4.3.1/bin/avutil-56.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win32-4.3.1/bin/avcodec-58.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win32-4.3.1/bin/avformat-58.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win32-4.3.1/bin/swresample-3.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win32-4.3.1/bin/swscale-5.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/adb.exe "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinApi.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinUsbApi.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/SDL2-2.0.22/i686-w64-mingw32/bin/SDL2.dll "$(DIST)/$(WIN32_TARGET_DIR)/"
	cp app/prebuilt-deps/data/libusb-1.0.26/MinGW-Win32/msys-usb-1.0.dll "$(DIST)/$(WIN32_TARGET_DIR)/"

dist-win64: build-server build-win64
	mkdir -p "$(DIST)/$(WIN64_TARGET_DIR)"
	cp "$(SERVER_BUILD_DIR)"/server/scrcpy-server "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp "$(WIN64_BUILD_DIR)"/app/scrcpy.exe "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/data/scrcpy-console.bat "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/scrcpy-noconsole.vbs "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/icon.png "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/data/open_a_terminal_here.bat "$(DIST)/$(WIN64_TARGET_DIR)"
	cp app/prebuilt-deps/data/ffmpeg-win64-5.0.1/bin/avutil-57.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win64-5.0.1/bin/avcodec-59.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win64-5.0.1/bin/avformat-59.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win64-5.0.1/bin/swresample-4.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-win64-5.0.1/bin/swscale-6.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/adb.exe "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinApi.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinUsbApi.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/SDL2-2.0.22/x86_64-w64-mingw32/bin/SDL2.dll "$(DIST)/$(WIN64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/libusb-1.0.26/MinGW-x64/msys-usb-1.0.dll "$(DIST)/$(WIN64_TARGET_DIR)/"

dist-win-arm64: build-server build-win-arm64
	mkdir -p "$(DIST)/$(WIN_ARM64_TARGET_DIR)"
	cp "$(SERVER_BUILD_DIR)"/server/scrcpy-server "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp "$(WIN_ARM64_BUILD_DIR)"/app/scrcpy.exe "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/data/scrcpy-console.bat "$(DIST)/$(WIN_ARM64_TARGET_DIR)"
	cp app/data/scrcpy-noconsole.vbs "$(DIST)/$(WIN_ARM64_TARGET_DIR)"
	cp app/data/icon.png "$(DIST)/$(WIN_ARM64_TARGET_DIR)"
	cp app/data/open_a_terminal_here.bat "$(DIST)/$(WIN_ARM64_TARGET_DIR)"
	cp app/prebuilt-deps/data/ffmpeg-aarch64-4.3.1/bin/avutil-56.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-aarch64-4.3.1/bin/avcodec-58.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-aarch64-4.3.1/bin/avformat-58.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-aarch64-4.3.1/bin/swresample-3.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/ffmpeg-aarch64-4.3.1/bin/swscale-5.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/adb.exe "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinApi.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/platform-tools-33.0.1/AdbWinUsbApi.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/SDL2-2.0.22/aarch64-w64-mingw32/bin/SDL2.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"
	cp app/prebuilt-deps/data/libusb-1.0.26/MinGW-aarch64/libusb-1.0.dll "$(DIST)/$(WIN_ARM64_TARGET_DIR)/"

zip-win32: dist-win32
	cd "$(DIST)/$(WIN32_TARGET_DIR)"; \
		zip -r "../$(WIN32_TARGET)" .

zip-win64: dist-win64
	cd "$(DIST)/$(WIN64_TARGET_DIR)"; \
		zip -r "../$(WIN64_TARGET)" .

zip-win-arm64: dist-win-arm64
	cd "$(DIST)/$(WIN_ARM64_TARGET_DIR)"; \
		zip -r "../$(WIN_ARM64_TARGET)" .
