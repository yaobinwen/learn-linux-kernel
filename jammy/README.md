# Ubuntu Jammy

## 1. Overview

The main reference is [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy).

My approach of learning is simple & stupid:
- I know the code [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy) builds.
- I know the build process starts with the file [debian/rules](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian/rules) (See the section "How to build").

So I'm doing it this way: Copy the whole [`debian` folder](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian) into this repository, and run `debian/rules` repeatedly. Surely I'll run into a lot of build errors, but I'll resolve them one by one until I get the kernel built. This way, I'll probably end up with the minimal set of needed source files.

Note: Because I work on `x86` machines, I will focus on building the code on `x86` platforms, so I may not copy the source files that are only needed for building on other platforms.

## 2. How to build

References:
- [1] [Ubuntu: Build Your Own Kernel](https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel)

1. Install `ansible` (if not installed by the VM provisioner): `sudo ./ansible/ansible-bootstrap.sh`
2. Install the necessary development tools:
  - 2.1 `cd ansible`
  - 2.2 `ansible-playbook -K -vvv dev-env.yml`
3. Configure the kernel (if needed). Refer to [1] for the instructions.
4. Build the kernel:
  - 4.1 `cd` into the root directory of kernel source (i.e., this folder).
  - 4.2 `LANG=C fakeroot debian/rules clean`
    - Note: `debian/rules clean` seems to create `debian/control` as well and this file is needed for further building. See the section "Caveat: `debian/rules clean` also creates" below.
  - 4.3 Build in one of the following ways:
    - 4.3.1 (Quicker build) `LANG=C fakeroot debian/rules binary-headers binary-generic binary-perarch`
    - 4.3.2 (Need linux-tools or lowlatency kernel) `LANG=C fakeroot debian/rules binary`
      - The target `binary` is in `debian/rules`.
      - Because the target `binary` depends on two sub-targets: `binary-indep` and `binary-arch`, one can start with `LANG=C fakeroot debian/rules binary-indep` and then build the target `binary-arch`.

## 3. How to resume the previous work

Because I can't finish the kernel building in one sitting, I need to write down how to resume the work:
- 1). `cd ~/yaobin/code/linux-lab`.
- 2). `vagrant up` to start up the VM `ywen-linux-lab`. (See `Linux-Lab` for more details.)
- 3). `vagrant ssh` to log into the VM.
- 4). `cd /lab/learn-linux-kernel/jammy`: This is where I've been building the kernel code. You can run the build command to build the code. See the section "Build verbosity" for the build command.
- 5). `cd /lab/ubuntu-kernel-jammy`: This is the folder I built successfully before so it can be used as a reference.

## 4. Build verbosity

As of 2024-05-14, I've found two ways to control the output verbosity:
- 1). When running `LANG=C fakeroot debian/rules binary-indep`, just append `V=1` to it: `LANG=C fakeroot debian/rules binary-indep V=1`.
- 2). In `jammy/debian/rules.d/2-binary-arch.mk`, find the block of "hmake := $(MAKE) -C $(CURDIR) O=$(headers_tmp) \ ..." and add `V=1` to it:

```
hmake := $(MAKE) \
	-C $(CURDIR) \
	V=1 \
	O=$(headers_tmp) \
	KERNELVERSION=$(abi_release) \
	INSTALL_HDR_PATH=$(headers_tmp)/install \
	SHELL="$(SHELL)" \
	ARCH=$(header_arch)
```

Note that `V=2` doesn't seem to mean "verbose AND give the reason why each target is rebuilt". At least `V=2` is not as verbose as `V=1`. The following block in `jammy/Makefile` shows how the quietness is determined:

```makefile
ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif

ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif
```

## 5. Build progress

- [ ] `binary-indep`
  - [ ] `install-indep`
    - [x] `$(stampdir)/stamp-install-headers`
      - [x] `$(stampdir)/stamp-prepare-indep` (no more deps)
    - [x] `install-doc`
      - [x] `$(stampdir)/stamp-prepare-indep` (no more deps)
    - [x] `install-source`
      - [x] `$(stampdir)/stamp-prepare-indep` (no more deps)
    - [ ] `install-tools`
      - [x] `$(stampdir)/stamp-prepare-indep` (no more deps)
      - [ ] `$(stampdir)/stamp-build-perarch`
        - [x] `$(stampdir)/stamp-prepare-perarch` (no more deps)
        - [ ] `install-arch-headers` (no more deps)
          - [ ] The line `$(hmake) $(defconfig)` actually calls `jammy/Makefile`.
            - [ ] `__sub-make`
              - [ ] `defconfig` in `jammy/Makefile`
                - [ ] `defconfig` in `jammy/scripts/kconfig/Makefile`
                  - [ ] `x86_64_defconfig` in `jammy/Makefile`
                    - [ ] `x86_64_defconfig` in `jammy/scripts/kconfig/Makefile`
            - [ ] WIP: L116: "# Call a source code checker (by default, "sparse") as part of the"
- [ ] (To be continued)

## Noticeable files

### syscalls

The system call tables are in `jammy/arch/x86/entry/syscalls`:
- `syscall_32.tbl`, needed by 'arch/x86/include/generated/uapi/asm/unistd_32.h'
- `syscall_64.tbl` (not sure if needed by any file)

There are two supportive scripts:
- `scripts/syscallhdr.sh` generates a syscall number header.
- `scripts/syscalltbl.sh` generates a syscall table header.

The build produced the following header files (paths are relative to `debian/tmp-headers`):
```
/usr/bin/make -f /lab/learn-linux-kernel/jammy/scripts/Makefile.build obj=arch/x86/entry/syscalls all
  sh /lab/learn-linux-kernel/jammy/scripts/syscallhdr.sh --abis i386 --emit-nr   /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_32.tbl arch/x86/include/generated/uapi/asm/unistd_32.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscallhdr.sh --abis common,64 --emit-nr   /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_64.tbl arch/x86/include/generated/uapi/asm/unistd_64.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscallhdr.sh --abis common,x32 --emit-nr --offset __X32_SYSCALL_BIT  /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_64.tbl arch/x86/include/generated/uapi/asm/unistd_x32.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscalltbl.sh --abis i386 /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_32.tbl arch/x86/include/generated/asm/syscalls_32.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscallhdr.sh --abis i386 --emit-nr  --prefix ia32_ /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_32.tbl arch/x86/include/generated/asm/unistd_32_ia32.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscallhdr.sh --abis x32 --emit-nr  --prefix x32_ /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_64.tbl arch/x86/include/generated/asm/unistd_64_x32.h
  sh /lab/learn-linux-kernel/jammy/scripts/syscalltbl.sh --abis common,64 /lab/learn-linux-kernel/jammy/arch/x86/entry/syscalls/syscall_64.tbl arch/x86/include/generated/asm/syscalls_64.h
```

### relocation

The `relocs.*` files under `jammy/arch/x86/tools` are part of the tools used for processing relocation information in the `x86` architecture. Relocation information is crucial for linking and loading processes, as it describes how to adjust addresses in the code when the binary is loaded into memory.
- `jammy/arch/x86/tools/relocs.h` includes the header file `<tools/le_byteshift.h>` which is `jammy/tools/include/tools/le_byteshift.h`.

The generated `relocs` tool is in `./debian/tmp-headers/arch/x86/tools/relocs`. Its help info is as follows:

```
vagrant@ywen-linux-lab:/lab/learn-linux-kernel/jammy/debian/tmp-headers/arch/x86/tools$ ./relocs --help
relocs [--abs-syms|--abs-relocs|--reloc-info|--text|--realmode] vmlinux
```

Is it used specifically for `vmlinux`?

### vmlinux

`vmlinux` is the uncompressed, ELF (Executable and Linkable Format) file that represents the Linux kernel. It is generated as part of the kernel build process and contains the core kernel code, including both the executable code and the necessary data structures.
- Unlike other kernel images like bzImage, which are compressed to save space and reduce boot times, vmlinux is an uncompressed binary. This makes it easier to analyze and debug.
- `vmlinux` is in the ELF format, which is a common standard for executables, object code, shared libraries, and core dumps. This format includes headers that describe the file's structure, sections, and segments.

Role and Usage of vmlinux:
- **Intermediate Build Artifact**: During the kernel build process, `vmlinux` is generated first. Subsequent steps may convert it into different formats suitable for booting on various hardware architectures.
- **Debugging and Analysis**: Because `vmlinux` is uncompressed and in ELF format, it contains symbol information that is useful for debugging. Developers can use tools like gdb to analyze `vmlinux` and diagnose issues within the kernel.
- **Relocation and Linking**: `vmlinux` includes relocation information necessary for linking and loading kernel modules. This information helps the kernel loader adjust addresses so that the kernel can run correctly in memory.

### `usbip`

`usbip` is a tool used in Linux for sharing USB devices over a network. It stands for "USB over IP" and allows you to make a USB device connected to one machine (the server) appear as if it is connected to another machine (the client). This can be particularly useful for accessing USB devices remotely, such as printers, storage devices, or other peripherals. It consists of two parts:
- The server daemon (`usbipd`) runs on the machine where the USB devices are physically connected. It exports the devices to the network.
- The client (`usbip`) runs on the machine that wants to use the remote USB device. It imports the USB device from the server and makes it available as if it were a local device.

The source files are under `jammy/tools/usb/usbip`. The build artifacts are installed under `debian/build/tools-perarch/tools/usb/usbip`, as shown in the build log (which mentions the `lib` folder specifically, but all the build artifacts are under `debian/build/tools-perarch/tools/usb/usbip`, such as `bin/sbin/usbipd`):

```
----------------------------------------------------------------------
Libraries have been installed in:
   /lab/learn-linux-kernel/jammy/debian/build/tools-perarch/tools/usb/usbip/bin/lib

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the '-LLIBDIR'

flag during linking and do at least one of the following:
   - add LIBDIR to the 'LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the 'LD_RUN_PATH' environment variable
     during linking
   - use the '-Wl,-rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to '/etc/ld.so.conf'

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------
```

### `include/linux`

On 2024-06-16, I needed to add the file `include/linux/circ_buf.h`. Then it occurred to me that `include/linux` probably has all the interface header files for Linux.

## 2024-05-11 (Sat)

### `make kernelversion`

Today I started to work on building Ubuntu Jammy's source code.

I followed the build instructions above and started with `debian/rules clean`. After running `debian/rules clean`, the first obstacle was the line below in `jammy/debian/rules.d/0-common-vars.mk`:

```makefile
raw_kernelversion=$(shell make kernelversion)
```

To run `make kernelversion` successfully, I needed to copy more files into the source tree. The commit `883ca1313f2eae65139ba71130eb46429d7963e5` has all the needed files to run `make kernelversion` successfully:

```
vagrant@ywen-linux-lab:/lab/learn-linux-kernel/jammy$ make kernelversion
[ywen] Makefile: $this-makefile = Makefile
[ywen] Makefile: $abs_srctree = /lab/learn-linux-kernel/jammy
[ywen] Makefile: $abs_objtree = /lab/learn-linux-kernel/jammy
[ywen] $SUBARCH=x86
[ywen] $ARCH = x86
[ywen] $UTS_MACHINE = x86
[ywen] $SRCARCH = x86
5.15.77
```

### Caveat: Build target block may be longer

Today I read the following build target in `rules.d/3-binary-indep.mk`:

```makefile
$(stampdir)/stamp-install-headers: $(stampdir)/stamp-prepare-indep
	@echo Debug: $@
	dh_testdir

# NOTE(ywen): OK... So this whole `ifeq...endif` block still belongs to the
# build target `$(stampdir)/stamp-install-headers`.
ifeq ($(do_flavour_header_package),true)
	install -d $(indep_hdrdir)
	find . -path './debian' -prune -o -path './$(DEBIAN)' -prune \
	  -o -path './include/*' -prune \
	  -o -path './scripts/*' -prune -o -type f \
	  \( -name 'Makefile*' -o -name 'Kconfig*' -o -name 'Kbuild*' -o \
	     -name '*.sh' -o -name '*.pl' -o -name '*.lds' \) \
	  -print | cpio -pd --preserve-modification-time $(indep_hdrdir)
	cp -a scripts include $(indep_hdrdir)
	(find arch -name include -type d -print | \
		xargs -n1 -i: find : -type f) | \
		cpio -pd --preserve-modification-time $(indep_hdrdir)
endif
	@touch $@
```

Because the `ifeq` statement starts from the beginning of the line, I thought it didn't belong to the build target `$(stampdir)/stamp-install-headers` until later I realized it did.

### Unknown package `linux-lib-dev`

As of 2024-05-11, running `LANG=C fakeroot debian/rules binary-indep` would result in the following error:

```
Debug: install-arch-headers
dh_testdir
dh_testroot
dh_prep -plinux-libc-dev
dh_prep: error: Requested unknown package linux-libc-dev via -p/--package, expected one of: linux-source-5.15.0 linux-headers-5.15.0-57 linux-tools-common linux-tools-5.15.0-57 linux-cloud-tools-common linux-cloud-tools-5.15.0-57 linux-tools-host
dh_prep: error: unknown option or error during option parsing; aborting
make: *** [debian/rules.d/2-binary-arch.mk:550: install-arch-headers] Error 255
```

Finally, I figured this error was because I didn't copy `debian.master/control.d/linux-libc-dev.stub`.

So `debian/rules` has the following code:

```makefile
control_files := $(DEBIAN)/control.stub.in
ifeq ($(do_libc_dev_package),true)
ifneq (,$(wildcard $(DEBIAN)/control.d/linux-libc-dev.stub))
	control_files += $(DEBIAN)/control.d/linux-libc-dev.stub
endif
endif
```

If `do_libc_dev_package` is `true` and the file `$(DEBIAN)/control.d/linux-libc-dev.stub` could be found, `$(DEBIAN)/control.d/linux-libc-dev.stub` is appended to the list `control_files`.

Later, the target `$(DEBIAN)/control.stub` calls a `for` loop to append the `control` stubs into `control.stub`:

```makefile
$(DEBIAN)/control.stub: 				\
		...
	for i in $(control_files); do                                           \
	  cat $$i;                                                              \
	  echo "";                                                              \
	done | sed -e 's/PKGVER/$(release)/g'                                   \
	...
	  > $(DEBIAN)/control.stub;
```

And finally `$(DEBIAN)/control.stub` is copied into `debian/control`:

```makefile
.PHONY: debian/control
debian/control: $(DEBIAN)/control.stub
	cp $(DEBIAN)/control.stub debian/control
```

### Caveat: `debian/rules clean` also creates

The **caveat** is that the file `debian/control` seems to be generated by the `debian/rules clean` command, because only the `clean` target depends on the target `debian/control`:

```makefile
clean: debian/control debian/canonical-certs.pem debian/canonical-revoked-certs.pem
```

If I didn't call `debian/rule clean` but called `debian/rule binary-indep` directly, I'd get the error "`debian/control` not found":

```
dh_prep: error: "debian/control" not found. Are you sure you are in the correct directory?
```

## 2024-05-12 (Sun)

Today I continued with the Jammy kernel building. I was currently running into the following error:

```
/usr/bin/make -C /lab/learn-linux-kernel/jammy O=/lab/learn-linux-kernel/jammy/debian/tmp-headers KERNELVERSION=5.15.0-57 INSTALL_HDR_PATH=/lab/learn-linux-kernel/jammy/debian/tmp-headers/install SHELL="/bin/bash -e" ARCH=x86 defconfig
make[1]: Entering directory '/lab/learn-linux-kernel/jammy'
make[2]: Entering directory '/lab/learn-linux-kernel/jammy/debian/tmp-headers'
  GEN     Makefile
  HOSTCC  scripts/basic/fixdep
  HOSTCC  scripts/kconfig/conf.o
  HOSTCC  scripts/kconfig/confdata.o
  HOSTCC  scripts/kconfig/expr.o
  LEX     scripts/kconfig/lexer.lex.c
  YACC    scripts/kconfig/parser.tab.[ch]
  HOSTCC  scripts/kconfig/lexer.lex.o
  HOSTCC  scripts/kconfig/menu.o
  HOSTCC  scripts/kconfig/parser.tab.o
  HOSTCC  scripts/kconfig/preprocess.o
  HOSTCC  scripts/kconfig/symbol.o
  HOSTCC  scripts/kconfig/util.o
  HOSTLD  scripts/kconfig/conf
*** Default configuration is based on target 'x86_64_defconfig'
  GEN     Makefile
sh: 1: /lab/learn-linux-kernel/jammy/scripts/as-version.sh: not found
```

## 2024-05-14 (Tue)

Today I read the article [Exploring the Linux kernel: The secrets of Kconfig/kbuild](https://opensource.com/article/18/10/kbuild-and-kconfig) to get some sense about `Kconfig`.

## 2024-05-20 (Mon)

Today I learned how to use the first executable I built: `unifdef`.

I ran into the following build error:

```
In file included from /lab/learn-linux-kernel/jammy/arch/x86/tools/relocs_32.c:2:
/lab/learn-linux-kernel/jammy/arch/x86/tools/relocs.h:18:10: fatal error: tools/le_byteshift.h: No such file or directory
   18 | #include <tools/le_byteshift.h>
      |          ^~~~~~~~~~~~~~~~~~~~~~
compilation terminated.
```

Will need to move `./tools/include/tools/le_byteshift.h` to the build source tree.

## 2024-05-22 (Wed)

Today I started to build `tools/power/acpi`. Building it requires the files in `include/acpi/`.

Meanwhile, "acpi" means "Advanced Configuration and Power Interface". See [ACPI Component Architecture (ACPICA)](https://www.intel.com/content/www/us/en/developer/topic-technology/open/acpica/overview.html) for more information.

## 2024-05-25 (Sat)

I have to pause the project for a while because my baby girl was born tonight so I will need to spend time taking care of her.
