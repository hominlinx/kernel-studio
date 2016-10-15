LINUX := linux
TARGET_LINUX=target/linux
BUSYBOX := busybox

default: kernel.img rootfs.img

run: kernel.img rootfs.img
	#qemu-system-x86_64 -kernel kernel.img -append "root=/dev/ram rdinit=/sbin/init" -initrd rootfs.img -net nic,model=e1000 -net user
	qemu-system-x86_64 -kernel kernel.img -nographic  -append "root=/dev/ram rdinit=/sbin/init console=ttyS0" -initrd rootfs.img -net nic,model=e1000 -net user

debug: kernel.img rootfs.img
	qemu-system-x86_64 -kernel kernel.img -append "root=/dev/ram rdinit=/sbin/init kgdboc=ttyS0,115200 kgdbwait" -initrd rootfs.img -net nic,model=e1000 -net user -serial tcp::1234,server &
	TMPFILE=$$(mktemp) && echo "target remote localhost:1234" > $$TMPFILE && gdb -x $$TMPFILE $(LINUX)/vmlinux

clean:
	rm -f kernel.img rootfs.img

kernel.img: $(TARGET_LINUX)/.config
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOADADDR=0x48000000  INSTALL_MOD_PATH=./_install O=../${TARGET_LINUX} -C ${LINUX} uImage
	make -C $(LINUX) bzImage -j4
	cp $(LINUX)/arch/x86/boot/bzImage $@

rootfs.img: $(BUSYBOX)/.config
	make CROSS_COMPILE=arm-linux-gnueabihf- -C $(BUSYBOX) install -j4
	./mkrootfs $@

install $(LINUX)/.config $(BUSYBOX)/.config:
	./install

.PHONY: default run debug clean install
