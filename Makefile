PPTC ?= pp
OSBARE_DIR ?= ../pengpeng-osbare
PPNET_DIR ?= ../ppnet
PPHTTP_DIR ?= ../pphttp
OSRT_DIR ?= ../osrt
WAMR_DIR ?=
HOST_CC ?= cc
AS := x86_64-elf-as
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
OBJCOPY := x86_64-elf-objcopy
READELF := x86_64-elf-readelf
NM := x86_64-elf-nm
AR := x86_64-elf-ar
QEMU := qemu-system-x86_64

BUILD := build
TARGET_OBJECT := target/x86_64-unknown-none/debug/ppos/image.o
LD_FLAGS := -z noexecstack

.PHONY: all check component ppnet-component pphttp-component osrt-component run run-headless test test-smoke test-boundary test-elf verify clean

all: $(BUILD)/ppos-v0.3.0.elf

check:
	$(PPTC) check --name image

$(BUILD):
	mkdir -p $(BUILD)

$(TARGET_OBJECT): pp.toml src/main.pp src/agent.pp
	$(PPTC) build --name image

component:
	$(MAKE) -C $(OSBARE_DIR) component AS=$(AS) CC=$(CC) AR=$(AR)

ppnet-component:
	HOST_CC=$(HOST_CC) CC=$(CC) AR=$(AR) \
		sh $(PPNET_DIR)/tools/build-third-party.sh

pphttp-component:
	$(MAKE) -C $(PPHTTP_DIR) component CC=$(CC) AR=$(AR)

osrt-component:
	test -n "$(WAMR_DIR)"
	$(MAKE) -C $(OSRT_DIR) build/freestanding/libosrt_wamr.a \
		WAMR_DIR=$(WAMR_DIR) AS=$(AS) CC=$(CC) AR=$(AR) RANLIB=x86_64-elf-ranlib

$(BUILD)/deepseek_trust.o: c/deepseek_trust.c c/digicert_global_root_g2.h | $(BUILD)
	test -n "$(BEARSSL_SOURCE)"
	$(CC) -std=c11 -ffreestanding -fno-stack-protector -fno-pic -Os -m64 \
		-mno-red-zone -mcmodel=kernel -mno-mmx -mno-sse -mno-sse2 \
		-Wall -Wextra -Werror -I$(PPNET_DIR)/c/include \
		-I$(BEARSSL_SOURCE)/inc -c $< -o $@

$(BUILD)/ppos-kernel.elf64: $(TARGET_OBJECT) $(BUILD)/deepseek_trust.o \
		$(OSBARE_DIR)/arch/x86_64/kernel64.ld component ppnet-component \
		pphttp-component osrt-component | $(BUILD)
	$(LD) $(LD_FLAGS) -T $(OSBARE_DIR)/arch/x86_64/kernel64.ld \
		$(OSBARE_DIR)/build/entry64.o $(TARGET_OBJECT) \
		$(PPNET_DIR)/build/third_party/libuip-core.a \
		$(PPNET_DIR)/build/third_party/libppnet-tls.a \
		$(PPNET_DIR)/build/third_party/libbearssl.a \
		$(BUILD)/deepseek_trust.o \
		$(PPHTTP_DIR)/build/libpphttp.a \
		$(OSRT_DIR)/build/freestanding/libosrt_wamr.a \
		$(OSBARE_DIR)/build/libosbare.a -o $@

$(BUILD)/ppos-kernel.bin: $(BUILD)/ppos-kernel.elf64
	$(OBJCOPY) -O binary $< $@

$(BUILD)/ppos-kernel.bin.o: $(BUILD)/ppos-kernel.bin
	$(OBJCOPY) -I binary -O elf32-i386 -B i386 \
		--rename-section .data=.kernel,alloc,load,code,contents $< $@

$(BUILD)/ppos-v0.3.0.elf: $(BUILD)/ppos-kernel.bin.o component
	$(LD) $(LD_FLAGS) -m elf_i386 -T $(OSBARE_DIR)/arch/x86_64/boot32.ld \
		$(OSBARE_DIR)/build/boot32.o $< -o $@

$(BUILD)/ppos-disk.img: | $(BUILD)
	dd if=/dev/zero of=$@ bs=1048576 count=1 status=none

$(BUILD)/ppos-initrd.bin: $(FX_WASM) | $(BUILD)
	test -n "$(FX_WASM)"
	cp $< $@

run: $(BUILD)/ppos-v0.3.0.elf $(BUILD)/ppos-disk.img $(BUILD)/ppos-initrd.bin
	$(QEMU) -machine pc -cpu max -m 384M -serial stdio -monitor none \
		-kernel $< -initrd $(BUILD)/ppos-initrd.bin -append 'ppos.release=0.3.0' \
		-drive file=$(BUILD)/ppos-disk.img,format=raw,if=ide \
		-device e1000,netdev=net0 -netdev user,id=net0 -no-reboot -no-shutdown

run-headless: $(BUILD)/ppos-v0.3.0.elf $(BUILD)/ppos-disk.img $(BUILD)/ppos-initrd.bin
	$(QEMU) -machine pc -cpu max -m 384M -display none -serial stdio -monitor none \
		-kernel $< -initrd $(BUILD)/ppos-initrd.bin -append 'ppos.release=0.3.0' \
		-drive file=$(BUILD)/ppos-disk.img,format=raw,if=ide \
		-device e1000,netdev=net0 -netdev user,id=net0 -no-reboot -no-shutdown

test-smoke: $(BUILD)/ppos-v0.3.0.elf $(BUILD)/ppos-disk.img $(BUILD)/ppos-initrd.bin
	QEMU=$(QEMU) sh tests/run-qemu-smoke.sh $^

test-boundary: $(TARGET_OBJECT)
	NM=$(NM) sh tests/check-boundary.sh $(TARGET_OBJECT)

test-elf: $(BUILD)/ppos-kernel.elf64 $(BUILD)/ppos-v0.3.0.elf
	READELF=$(READELF) sh tests/check-elf.sh $^

test: test-boundary test-elf test-smoke

verify: check test
	node tools/check-repository.mjs

clean:
	rm -rf $(BUILD) target
