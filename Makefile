# Makefile for libOnStep (Linux only)
# macOS: use Xcode — xcodebuild clean && xcodebuild

CXX    = g++
RM     = rm -f
STRIP  = strip

TARGET_LIB = libOnStep.so
OS_FLAG    = -DSB_LINUX_BUILD
LDFLAGS    = -shared -lstdc++

# The SDK headers use relative includes of the form "../../licensedinterfaces/foo.h".
# Adding -I../X2-Examples/licensedinterfaces makes that path resolve as:
#   ../X2-Examples/licensedinterfaces/../../licensedinterfaces/ = appinstall/licensedinterfaces/
SDK_LI   = ../X2-Examples/licensedinterfaces

CPPFLAGS = -fPIC -Wall -Wextra -O2 -g $(OS_FLAG) -std=gnu++11 -I. -I$(SDK_LI)

SRCS = main.cpp OnStep.cpp ZWOMount.cpp x2mount.cpp
OBJS = $(SRCS:.cpp=.o)

.PHONY: all clean validate_ui udev-install

all: validate_ui $(TARGET_LIB)

validate_ui:
	@if command -v uic >/dev/null 2>&1; then \
		echo "Validating OnStep.ui..."; \
		uic OnStep.ui > /dev/null || (echo "UI validation failed!" && exit 1); \
		echo "UI OK."; \
	else \
		echo "uic not found, skipping UI validation."; \
	fi

$(TARGET_LIB): $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^
	$(STRIP) $@ >/dev/null 2>&1 || true

%.o: %.cpp
	$(CXX) $(CPPFLAGS) -c $< -o $@

clean:
	$(RM) $(TARGET_LIB) $(OBJS)

# ZWO AM mounts are native USB CDC-ACM devices (ttyACM*), not USB-serial adapters.
# 03c3:4001 observed on an AM5. Do not match ATTRS{serial}: it is the placeholder 123456.
udev-install:
	@echo "Installing udev rule for ZWO AM Mount..."
	@echo 'SUBSYSTEM=="tty", ATTRS{idVendor}=="03c3", ATTRS{idProduct}=="4001", SYMLINK+="ttyZWO-AM-Mount"' | sudo tee /etc/udev/rules.d/99-zwo-am-mount.rules > /dev/null
	@sudo udevadm control --reload-rules
	@sudo udevadm trigger --subsystem-match=tty
	@echo "udev rule installed to /etc/udev/rules.d/99-zwo-am-mount.rules and reloaded."
	@echo "Note: If your mount does not show up as /dev/ttyZWO-AM-Mount, check its IDs with: udevadm info -a -n /dev/ttyACM0"
