V               ?= @

.DEFAULT_GOAL := help

BUILD_DIR := build
BUILD_DIR_32 := $(BUILD_DIR)/build32
BUILD_DIR_64 := $(BUILD_DIR)/build64
BUILD_DIR_ZIP := $(BUILD_DIR)/zip

DIST_DIR := dist

# Add "-D[option]=[value]" here as necessary
MESON_OPTIONS :=
# For options that shouldn't be committed
-include MesonLocalOptions.mk

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------

.PHONY: build # Build the project
build:
	$(V)meson setup $(MESON_OPTIONS) --cross cross-mingw-32.txt $(BUILD_DIR_32)
	$(V)ninja -C $(BUILD_DIR_32)
	$(V)meson setup $(MESON_OPTIONS) --cross cross-mingw-64.txt $(BUILD_DIR_64)
	$(V)ninja -C $(BUILD_DIR_64)

.PHONY: dist # Build and stage DLLs into dist/bin
dist: build clean-dist stage

.PHONY: clean-dist # Remove staged DLLs
clean-dist:
	$(V)rm -rf $(DIST_DIR)/bin

.PHONY: stage # Copy DLL outputs into dist/bin
stage:
	$(V)mkdir -p $(DIST_DIR)/bin/x86 $(DIST_DIR)/bin/x64
	$(V)cp -f $(BUILD_DIR_32)/src/chuniio-proxy.dll $(DIST_DIR)/bin/x86/chuniio-proxy.dll
	$(V)cp -f $(BUILD_DIR_64)/src/chuniio-proxy.dll $(DIST_DIR)/bin/x64/chuniio-proxy.dll

.PHONY: clean # Cleanup build output
clean:
	$(V)rm -rf $(BUILD_DIR)

# -----------------------------------------------------------------------------
# Utility, combo and alias targets
# -----------------------------------------------------------------------------

.PHONY: help # Print help screen
help:
	$(V)echo chuniio-proxy makefile.
	$(V)echo
	$(V)echo "Environment variables:"
	$(V)grep -E '^[A-Z_]+ \?= .* #' Makefile | gawk 'match($$0, /([A-Z_]+) \?= [$$\(]*([^\)]*)[\)]{0,1} # (.*)/, a) { printf("  \033[0;35m%-25s \033[0;0m%-45s [%s]\n", a[1], a[3], a[2]) }'
	$(V)echo ""
	$(V)echo "Targets:"
	$(V)grep '^.PHONY: .* #' Makefile | gawk 'match($$0, /\.PHONY: (.*) # (.*)/, a) { printf("  \033[0;32m%-25s \033[0;0m%s\n", a[1], a[2]) }'
