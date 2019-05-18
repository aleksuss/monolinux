STAGE = $(shell readlink -f build)
TOP = $(STAGE)/monolinux
BZIMAGE = $(TOP)/obj/linux-x86-allnoconfig/arch/x86/boot/bzImage
INITRAMFS = $(TOP)/initramfs.igz
INITRAMFS_CPIO = $(TOP)/initramfs.cpio
APP = $(STAGE)/app
LINUX_SRC = $(STAGE)/linux-$(ML_LINUX_VERSION)
MUSL_SRC = $(STAGE)/musl-$(ML_MUSL_VERSION)
MUSL_GCC = $(STAGE)/musl/bin/musl-gcc
SCRIPTS_DIR = $(ML_ROOT)/scripts

INC += $(ML_ROOT)/src
SRC ?= \
	main.c \
	$(ML_ROOT)/src/ml.c \
	$(ML_ROOT)/src/ml_bus.c \
	$(ML_ROOT)/src/ml_message.c \
	$(ML_ROOT)/src/ml_queue.c

.PHONY: all unpack linux initrd run build clean app

all:
	$(MAKE) build
	$(MAKE) run

build:
	$(MAKE) unpack
	$(MAKE) musl
	$(MAKE) initrd linux

unpack: $(LINUX_SRC) $(MUSL_SRC)

$(MUSL_SRC):
	mkdir -p $(STAGE)
	cd $(STAGE) && \
	tar xzf $(ML_SOURCES)/musl-$(ML_MUSL_VERSION).tar.gz

$(LINUX_SRC):
	mkdir -p $(STAGE)
	cd $(STAGE) && \
	tar xJf $(ML_SOURCES)/linux-$(ML_LINUX_VERSION).tar.xz

linux: $(BZIMAGE)

musl: $(MUSL_GCC)

$(MUSL_GCC): $(MUSL_SRC)
	+$(SCRIPTS_DIR)/musl.sh

$(BZIMAGE): $(LINUX_SRC)
	+$(SCRIPTS_DIR)/linux.sh

initrd:
	$(MAKE) $(INITRAMFS)

app: $(APP)

$(APP): $(SRC)
	mkdir -p $(STAGE)
	$(MUSL_GCC) -Wall -Wextra -Werror -O2 $(INC:%=-I%) $^ -static -o $@

$(INITRAMFS): $(APP)
	fakeroot $(SCRIPTS_DIR)/create_initramfs.sh

size:
	ls -l $(BZIMAGE) $(INITRAMFS_CPIO)

run:
	$(SCRIPTS_DIR)/run.sh

clean:
	rm -rf $(TOP) $(APP)