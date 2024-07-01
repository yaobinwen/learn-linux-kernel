# Ubuntu Jammy

## 1. Overview

The main reference is [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy).

My approach of learning is simple & stupid:
- I know the code [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy) builds.
- I know the build process starts with the file [debian/rules](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian/rules) (See the section "How to build").

So I'm doing it this way: Copy the whole [`debian` folder](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian) into this repository, and run `debian/rules` repeatedly. Surely I'll run into a lot of build errors, but I'll resolve them one by one until I get the kernel built. This way, I'll probably end up with the minimal set of needed source files.

Note: Because I work on `x86` machines, I will focus on building the code on `x86` platforms, so I may not copy the source files that are only needed for building on other platforms.

### Find `*.h` and `*.c` files

Because the source files are copied into the sub-folder `debian` as well, we should exclude the files under `debian`, so the `find` command can be:

```
find . -name "*.[ch]" ! -path "./debian/*" -type f
```

./include/x86_64-linux-gnu/sys/types.h

### The header files

It looks like building the kernel code requires the Linux API header files and static/dynamic libraries. For example, `jammy/scripts/basic/fixdep.c` includes the following header files:

```c
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
```

I can find many of the header files in the Linux source tree. For example:
- `include/uapi/linux/unistd.h`
- `include/linux/fcntl.h`
- `include/linux/string.h`
- `include/linux/ctype.h`

However, the command that builds `fixdep` is as follows:

```
gcc -Wp,-MMD,scripts/basic/.fixdep.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89       -I ./scripts/basic   -o scripts/basic/fixdep /lab/learn-linux-kernel/jammy/scripts/basic/fixdep.c
```

The `-I` only includes `./scripts/basic`, so it doesn't look like that the compiler is able to find those header files in the Linux source tree, so I guess the Linux API header files and library files must be installed as a pre-condition in order to compile the code.

### Header file resolution: the `-H` option

I can add `-H` to the `c_flags` and `cpp_flags` in `scripts/Makefile.lib` so `gcc` will print the path of the selected header files:

```make
c_flags        = -Wp,-MMD,$(depfile) $(NOSTDINC_FLAGS) -H $(LINUXINCLUDE)     \
		 -include $(srctree)/include/linux/compiler_types.h       \
		 $(_c_flags) $(modkern_cflags)                           \
		 $(basename_flags) $(modname_flags)

# ...

cpp_flags      = -Wp,-MMD,$(depfile) $(NOSTDINC_FLAGS) -H $(LINUXINCLUDE)     \
		 $(_cpp_flags)
```

The example output of building `scripts/mod` (see the related section below):

```
  gcc -Wp,-MMD,scripts/mod/.devicetable-offsets.s.d -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/11/include -H -I./arch/x86/include -I./arch/x86/include/generated -I./include -I./arch/x86/include/uapi -I./arch/x86/include/generated/uapi -I./include/uapi -I./include/generated/uapi -include ./include/linux/compiler-version.h -include ./include/linux/kconfig.h -I./ubuntu/include -include ./include/linux/compiler_types.h -D__KERNEL__ -fmacro-prefix-map=./= -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Wno-format-security -std=gnu89 -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -fcf-protection=none -m64 -falign-jumps=1 -falign-loops=1 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -mtune=generic -mno-red-zone -mcmodel=kernel -Wno-sign-compare -fno-asynchronous-unwind-tables -mindirect-branch=thunk-extern -mindirect-branch-register -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -fno-jump-tables -fno-delete-null-pointer-checks -Wno-frame-address -Wno-format-truncation -Wno-format-overflow -Wno-address-of-packed-member -O2 -fno-allow-store-data-races -Wframe-larger-than=2048 -fstack-protector-strong -Wimplicit-fallthrough=5 -Wno-main -Wno-unused-but-set-variable -Wno-unused-const-variable -fomit-frame-pointer -fno-stack-clash-protection -fno-inline-functions-called-once -Wdeclaration-after-statement -Wvla -Wno-pointer-sign -Wno-stringop-truncation -Wno-zero-length-bounds -Wno-array-bounds -Wno-stringop-overflow -Wno-restrict -Wno-maybe-uninitialized -Wno-alloc-size-larger-than -fno-strict-overflow -fno-stack-check -fconserve-stack -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wno-packed-not-aligned -DKBUILD_MODFILE='"scripts/mod/devicetable-offsets"' -DKBUILD_BASENAME='"devicetable_offsets"' -DKBUILD_MODNAME='"devicetable_offsets"' -D__KBUILD_MODNAME=kmod_devicetable_offsets -fverbose-asm -S -o scripts/mod/devicetable-offsets.s scripts/mod/devicetable-offsets.c
. ./include/linux/kbuild.h
. ./include/linux/mod_devicetable.h
.. ./include/linux/types.h
... ./include/uapi/linux/types.h
.... ./arch/x86/include/generated/uapi/asm/types.h
..... ./include/uapi/asm-generic/types.h
...... ./include/asm-generic/int-ll64.h
....... ./include/uapi/asm-generic/int-ll64.h
........ ./arch/x86/include/generated/uapi/asm/bitsperlong.h
......... ./include/asm-generic/bitsperlong.h
.......... ./include/uapi/asm-generic/bitsperlong.h
.... ./include/uapi/linux/posix_types.h
..... ./include/linux/stddef.h
...... ./include/uapi/linux/stddef.h
....... ./include/linux/compiler_types.h
..... ./arch/x86/include/generated/uapi/asm/posix_types.h
...... ./include/uapi/asm-generic/posix_types.h
....... ./arch/x86/include/generated/uapi/asm/bitsperlong.h
.. ./include/linux/uuid.h
... ./include/uapi/linux/uuid.h
... ./include/linux/string.h
.... ./include/linux/compiler.h
..... ./arch/x86/include/generated/asm/rwonce.h
...... ./include/asm-generic/rwonce.h
....... ./include/linux/kasan-checks.h
....... ./include/linux/kcsan-checks.h
.... ./include/linux/errno.h
..... ./include/uapi/linux/errno.h
...... ./arch/x86/include/generated/uapi/asm/errno.h
....... ./include/uapi/asm-generic/errno.h
........ ./include/uapi/asm-generic/errno-base.h
.... ./include/linux/stdarg.h
.... ./include/uapi/linux/string.h
.... ./arch/x86/include/asm/string.h
..... ./arch/x86/include/asm/string_64.h
...... ./include/linux/jump_label.h
....... ./arch/x86/include/asm/jump_label.h
........ ./arch/x86/include/asm/asm.h
......... ./include/linux/stringify.h
......... ./arch/x86/include/asm/extable_fixup_types.h
........ ./arch/x86/include/asm/nops.h
```

### TODOs:
- [ ] `./arch/x86/tools/relocs.*`
- [ ] `./scripts/unifdef.c`
- [ ] `./scripts/kconfig/`
- [ ] `./scripts/selinux/mdp/mdp.c`
- [ ] `./scripts/selinux/genheaders/genheaders.c`
- [ ] `./scripts/sorttable.c`
- [ ] `./scripts/kallsyms.c`
- [ ] `./scripts/genksyms/`
- [ ] `./scripts/dtc`
- [ ] `./tools/usb/usbip/`
- [ ] `./tools/power/cpupower/`
- [ ] `./tools/power/acpi`
- [ ] `./security/selinux/include/`
- [ ] `./tools/arch/x86/include/asm/orc_types.h`
- [ ] `./tools/include/tools/be_byteshift.h`
- [ ] `./tools/include/tools/le_byteshift.h`
- [ ] `jammy/include/linux/circ_buf.h`
- [ ] `jammy/include/linux/kconfig.h`
- [ ] `jammy/include/linux/compiler.h`

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
          - [x] The line `$(hmake) $(defconfig)` actually calls `jammy/Makefile`.
            - [x] `__sub-make` on three targets:
              - [x] `defconfig` in `jammy/Makefile` (`$(hmake) $(defconfig)` in `jammy/debian/rules.d/2-binary-arch.mk`)
                - [x] `defconfig` in `jammy/scripts/kconfig/Makefile`
                  - [x] `x86_64_defconfig` in `jammy/Makefile`
                    - [x] `x86_64_defconfig` in `jammy/scripts/kconfig/Makefile`
              - [x] `syncconfig` (`$(hmake) syncconfig` in `jammy/debian/rules.d/2-binary-arch.mk`)
              - [x] `headers_install` (`$(hmake) headers_install` in `jammy/debian/rules.d/2-binary-arch.mk`)
          - [x] Build `usbip` if `do_tools_usbip` is true.
          - [x] Build `acpidbg` if `do_tools_acpidbg` is true.
- [ ] (To be continued)

## 6. Noticeable files

### `init/Kconfig`

The `Kconfig` files (not only `init/Kconfig` but also the `Kconfig` files that are found in many sub-folders) define the configuration options available when building the kernel, including their dependencies, default values, and help text. Specifically, `init/Kconfig` handles the configuration options related to the kernel initialization and general setup. It includes options that control basic kernel features, startup settings, and various system initialization parameters.

A `Kconfig` file is written in a specific syntax used by the kernel's configuration tools (e.g., `make menuconfig`, `make xconfig`). The structure typically includes:
- Menu entries: Groups of related configuration options.
- Config entries: Individual configuration options.
- Dependencies: Conditions under which certain options are available.
- Help text: Descriptions of what each option does.

The `source` statements in `init/Kconfig` is used to include other `Kconfig` files into the current configuration hierarchy. This mechanism allows the kernel's configuration system to be modular and organized, making it easier to manage and navigate the numerous configuration options available in the Linux kernel.

Also note that some configuration items call external scripts to determine their values. For example:

```
config CC_HAS_ASM_GOTO
    def_bool $(success,$(srctree)/scripts/gcc-goto.sh $(CC))
```

- `def_bool` is used to set the default value of the boolean configuration option.
- `$(success,...)` is a special macro that evaluates the command within the parentheses and returns `true` (1) if the command succeeds (i.e., exits with a status code of 0), and `false` (0) otherwise.

### Compiler feature detection scripts

Several shell scripts are called in `init/Kconfig` (or the other `Kconfig` files that `init/Kconfig` includes) to check if the used compiler has certain features. To find such scripts, search `/scripts/` in all `Kconfig` files:
- `scripts/cc-can-link.sh`
- `scripts/gcc-goto.sh`
- `scripts/gcc-x86_64-has-stack-protector.sh`
- `scripts/gcc-x86_32-has-stack-protector.sh`

`Kconfig` also calls some other scripts. Search `/scripts/` in all `Kconfig` files to find them all.

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

### `include/linux/compiler-version.h`

This is all the file has:

```c
#ifdef  __LINUX_COMPILER_VERSION_H
#error "Please do not include <linux/compiler-version.h>. This is done by the build system."
#endif
#define __LINUX_COMPILER_VERSION_H
```

### `include/linux/compiler_types.h`

This file defines various macros and attributes that are used to interact with and extend the capabilities of different compilers. This file helps ensure compatibility and optimization across different compiler versions and types, providing a standardized way to use compiler-specific features and attributes in the kernel code.

This file includes the following header files:
- `<linux/compiler_attributes.h>`
- `<linux/compiler-clang.h>`
- `<linux/compiler-intel.h>`
- `<linux/compiler-gcc.h>`
- `<asm/compiler.h>`

### `include/linux/kconfig.h`

This file provides macros and functions related to the kernel configuration system, serving as an interface for accessing and manipulating configuration options that are defined through the `Kconfig` system and set during the kernel build process.

### `include/uapi`

This folder contains user-space API (UAPI) headers which refers to the interfaces and data structures that the kernel exposes to user-space programs.
- These headers are intended to be included in user-space programs. They define the API for communication between the kernel and user-space, ensuring that user-space applications can make system calls, use ioctl commands, and interact with kernel subsystems.
- These headers are designed to maintain **backward compatibility**. This ensures that user-space applications can continue to work with newer kernel versions without needing modifications.
- The folder contains sub-folders and headers for various kernel subsystems, such as networking, filesystems, device drivers, etc. Each subsystem exposes its specific API to user-space through these headers.

For example:
- `include/uapi/linux/`: Contains headers related to general kernel APIs, networking, filesystems, and more.
- `include/uapi/asm-generic/`: Contains architecture-independent headers that are shared across different hardware architectures.
- `include/uapi/asm/`: Contains architecture-specific headers for different hardware platforms (e.g., x86, ARM).

### `scripts/basic/fixdep.c`

The comment in `fixdep.c` explains the purpose of this tool:

```c
/*
 * ...
 *
 * gcc produces a very nice and correct list of dependencies which
 * tells make when to remake a file.
 *
 * To use this list as-is however has the drawback that virtually
 * every file in the kernel includes autoconf.h.
 *
 * If the user re-runs make *config, autoconf.h will be
 * regenerated.  make notices that and will rebuild every file which
 * includes autoconf.h, i.e. basically all files. This is extremely
 * annoying if the user just changed CONFIG_HIS_DRIVER from n to m.
 *
 * So we play the same trick that "mkdep" played before. We replace
 * the dependency on autoconf.h by a dependency on every config
 * option which is mentioned in any of the listed prerequisites.
 * ...
 */
```

After compilation, the executable `fixdep` is created directly under `scripts/basic`.

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

### `acpidbg`

The source files are under `jammy/tools/power/acpi`. `acpidbg` is a tool for developers and system administrators who need to debug and interact with the ACPI firmware on Linux systems. By providing access to ACPI tables and methods, it helps diagnose and resolve ACPI-related issues, ensuring better power management and system configuration.

### `cpupower`

The source files are under `jammy/tools/power/cpupower`. `cpupower` is a command-line utility that provides various functionalities for managing CPU power states and performance. It is useful for tuning and optimizing the power consumption and performance of CPUs on a Linux system. Features and use cases include:
- CPU Frequency Scaling: Adjust the CPU frequency and governor to optimize power consumption or performance.
- Inspect CPU Information: Retrieve details about the CPU, including supported frequencies, governors, and power states.
- Set Power Policies: Configure power management policies to balance performance and power usage according to the system's needs.

### `include/asm-generic/int-ll64.h`

This file defines the following data types:

```c
typedef __s8  s8;
typedef __u8  u8;
typedef __s16 s16;
typedef __u16 u16;
typedef __s32 s32;
typedef __u32 u32;
typedef __s64 s64;
typedef __u64 u64;
```

### `include/linux`

On 2024-06-16, I needed to add the file `include/linux/circ_buf.h`. Then it occurred to me that `include/linux` probably has all the interface header files for Linux.

### `scripts/dtc`

This directory contains the source files for the Device Tree Compiler (DTC). The DTC is a tool used to compile and decompile device tree source files. Device trees are a data structure for describing the hardware components of a system, used particularly in embedded systems and ARM-based platforms.

A device tree is a hierarchical data structure that describes the hardware components of a system. It is used by the operating system to understand the hardware it is running on, allowing it to load appropriate drivers and manage hardware resources properly.
- Device Tree Source (DTS): This is a human-readable file written in a specific syntax that describes the hardware layout.
- Device Tree Blob (DTB): This is the compiled, binary version of the DTS file that the kernel can read at boot time.

Purpose and use cases of DTC:
- Compiling Device Trees: Convert human-readable DTS files into binary DTB files that the kernel can use.
- Decompiling Device Trees: Convert binary DTB files back into human-readable DTS files for analysis or modification.
- Validation: Ensure the syntax and structure of DTS files are correct before they are used.

Key Files in `scripts/dtc`:
- `dtc.c`: The main source file for the Device Tree Compiler. It contains the main function and the primary logic for compiling and decompiling device trees.
- `flattree.c`: Handles the manipulation of flattened device trees, which is an intermediate format used by the DTC.
- `fstree.c`: Manages the file system tree representation of device trees.
- `livetree.c`: Deals with the live tree structure, which is used during the parsing and validation phases.
- `srcpos.c`: Manages source position tracking, which helps in generating meaningful error messages during compilation.
- `treesource.c`: Handles the conversion between the source (DTS) and internal representations of device trees.
- `util.c`: Contains utility functions used throughout the DTC codebase.
- `yamltree.c`: Provides support for handling device trees written in YAML format.

### `scripts/kallsyms.c`

`kallsyms` stands for "Kernel All Symbols." It is a feature in the Linux kernel that provides a way to map kernel symbols (functions and variable names) to their addresses in memory. This mapping is helpful for debugging, as it allows developers to see human-readable names in kernel logs and debugging outputs.

Purpose and use cases:
- Debugging: When a kernel panic or other serious error occurs, the backtrace can show the symbolic names of the functions rather than raw memory addresses, making it easier to understand where the error occurred.
- Profiling: Tools like `perf` and `ftrace` use `kallsyms` to map addresses to function names, providing more readable and useful output.
- Kernel Development: Developers can use `kallsyms` to get insights into the kernel's behavior, identify bottlenecks, and understand the execution flow.

How `kallsyms` Works: During the kernel build process, the `kallsyms` utility generates a symbol table that includes all the symbols (functions, variables) in the kernel. This symbol table is then embedded into the kernel image. The `scripts/kallsyms.c` file in the kernel source code is responsible for generating this symbol table.

`scripts/kallsyms.c` in detail:
- Extract Symbols: It extracts symbols from the compiled kernel object files.
- Sort Symbols: It sorts these symbols by address.
- Remove Unnecessary Symbols: It removes symbols that are not needed for debugging, such as local symbols.
- Generate Table: It generates a compact symbol table that is included in the final kernel binary.

### `scripts/sorttable.c`

This file is compiled with the following command:

```
gcc -Wp,-MMD,scripts/.sorttable.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89      -I./tools/include -I./tools/arch/x86/include -DUNWINDER_ORC_ENABLED   -o scripts/sorttable scripts/sorttable.c   -lpthread
```

This file requires the following header files:

- `<sys/types.h>`
- `<sys/mman.h>`
- `<sys/stat.h>`
- `<getopt.h>`
- `<elf.h>`
- `<fcntl.h>`
- `<stdio.h>`
- `<stdlib.h>`
- `<string.h>`
- `<unistd.h>`
- `<tools/be_byteshift.h>`
- `<tools/le_byteshift.h>`
- `"sorttable.h"`
  - `<errno.h>`
  - `<pthread.h>`
  - `<asm/orc_types.h>`
    - `<linux/types.h>`
      - `<stdbool.h>`
      - `<stddef.h>`
      - `<stdint.h>`
      - `<asm/types.h>`
      - `<asm/posix_types.h>`
    - `<linux/compiler.h>`
    - `<asm/byteorder.h>`

### `scripts/asn1_compiler.c`

["ASN.1"](https://en.wikipedia.org/wiki/ASN.1) is "Abstract Syntax Notation One (ASN.1)", which is "a standard interface description language (IDL) for defining data structures that can be serialized and deserialized in a cross-platform way."

This file is compiled with the following command:

```
gcc -Wp,-MMD,scripts/.asn1_compiler.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89      -I./include   -o scripts/asn1_compiler scripts/asn1_compiler.c
```

### `scripts/extract-cert.c`

(TODO)

### `scripts/Kbuild.include`

This is a common include file used by various Makefiles throughout the kernel build system. It contains a collection of definitions, macros, and helper functions that streamline and standardize the build process. For example:
- Common variables:

```
# Convenient variables
comma   := ,
quote   := "
squote  := '
...
```

- Helper macros:

```
###
# Name of target with a '.' as filename prefix. foo/bar.o => foo/.bar.o
dot-target = $(dir $@).$(notdir $@)
```

- Shorthand notations:

```
###
# Shorthand for $(Q)$(MAKE) -f scripts/Makefile.build obj=
# Usage:
# $(Q)$(MAKE) $(build)=dir
build := -f $(srctree)/scripts/Makefile.build obj
```

#### The `build` shorthand notation

Search "$(Q)$(MAKE) $(build)=" and you will find a lot of such uses in `jammy/Makefile`:

```make
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic

config: outputmakefile scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

prepare0: archprepare
	$(Q)$(MAKE) $(build)=scripts/mod
	$(Q)$(MAKE) $(build)=.
```

The commands get expanded to the full command. For example, `$(Q)$(MAKE) $(build)=scripts/mod` is expanded to as `make -f ./scripts/Makefile.build obj=scripts/mod`.

This is also where `scripts/Makefile.build` is used.

### `scripts/Makefile.build`

This file is used to define the rules and dependencies for building individual files and modules within the kernel. It is included by other Makefiles in the kernel source tree to standardize and simplify the build process. For example:

- Building individual files:
  - It defines how to compile source files (`.c`, `.S`, etc.) into object files (`.o`).
- Handling dependencies:
  - It specifies dependencies between source files and headers to ensure that changes are properly tracked, and only the necessary parts are rebuilt.
- Module compilation:
  - It provides rules for compiling and linking kernel modules. Modules are typically built from one or more source files and need to be linked into a single loadable module.
- Optimization and debugging flags:
  - It sets the appropriate compiler and linker flags for optimization, debugging, and other build options.

### `scripts/mod`

The building of this part of code is triggered by the following section in `Makefile`:

```makefile
prepare0: archprepare
	$(Q)$(MAKE) $(build)=scripts/mod
	$(Q)$(MAKE) $(build)=.
```

The command `$(Q)$(MAKE) $(build)=scripts/mod` is expanded to `make -f ./scripts/Makefile.build obj=scripts/mod`.

The expanded `gcc` command is as follows:

```
make -f ./scripts/Makefile.build obj=scripts/mod
  gcc -Wp,-MMD,scripts/mod/.devicetable-offsets.s.d -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/11/include -I./arch/x86/include -I./arch/x86/include/generated -I./include -I./arch/x86/include/uapi -I./arch/x86/include/generated/uapi -I./include/uapi -I./include/generated/uapi -include ./include/linux/compiler-version.h -include ./include/linux/kconfig.h -I./ubuntu/include -include ./include/linux/compiler_types.h -D__KERNEL__ -fmacro-prefix-map=./= -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Wno-format-security -std=gnu89 -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -fcf-protection=none -m64 -falign-jumps=1 -falign-loops=1 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -mtune=generic -mno-red-zone -mcmodel=kernel -Wno-sign-compare -fno-asynchronous-unwind-tables -mindirect-branch=thunk-extern -mindirect-branch-register -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -fno-jump-tables -fno-delete-null-pointer-checks -Wno-frame-address -Wno-format-truncation -Wno-format-overflow -Wno-address-of-packed-member -O2 -fno-allow-store-data-races -Wframe-larger-than=2048 -fstack-protector-strong -Wimplicit-fallthrough=5 -Wno-main -Wno-unused-but-set-variable -Wno-unused-const-variable -fomit-frame-pointer -fno-stack-clash-protection -fno-inline-functions-called-once -Wdeclaration-after-statement -Wvla -Wno-pointer-sign -Wno-stringop-truncation -Wno-zero-length-bounds -Wno-array-bounds -Wno-stringop-overflow -Wno-restrict -Wno-maybe-uninitialized -Wno-alloc-size-larger-than -fno-strict-overflow -fno-stack-check -fconserve-stack -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wno-packed-not-aligned -DKBUILD_MODFILE='"scripts/mod/devicetable-offsets"' -DKBUILD_BASENAME='"devicetable_offsets"' -DKBUILD_MODNAME='"devicetable_offsets"' -D__KBUILD_MODNAME=kmod_devicetable_offsets -fverbose-asm -S -o scripts/mod/devicetable-offsets.s scripts/mod/devicetable-offsets.c
```

The order of header file inclusion is:
- `-I./arch/x86/include`
- `-I./arch/x86/include/generated`
- `-I./include`
- `-I./arch/x86/include/uapi`
- `-I./arch/x86/include/generated/uapi`
- `-I./include/uapi`
- `-I./include/generated/uapi`
- `-I./ubuntu/include`

On 2024-06-29, I successfully compiled `scripts/mod` but received the following warnings:

```
gcc -Wp,-MMD,scripts/mod/.devicetable-offsets.s.d -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/11/include -H -I./arch/x86/include -I./arch/x86/include/generated -I./include -I./arch/x86/include/uapi -I./arch/x86/include/generated/uapi -I./include/uapi -I./include/generated/uapi -include ./include/linux/compiler-version.h -include ./include/linux/kconfig.h -I./ubuntu/include -include ./include/linux/compiler_types.h -D__KERNEL__ -fmacro-prefix-map=./= -Wall -Wundef -Werror=strict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -fshort-wchar -fno-PIE -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Wno-format-security -std=gnu89 -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -fcf-protection=none -m64 -falign-jumps=1 -falign-loops=1 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -mtune=generic -mno-red-zone -mcmodel=kernel -Wno-sign-compare -fno-asynchronous-unwind-tables -mindirect-branch=thunk-extern -mindirect-branch-register -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -fno-jump-tables -fno-delete-null-pointer-checks -Wno-frame-address -Wno-format-truncation -Wno-format-overflow -Wno-address-of-packed-member -O2 -fno-allow-store-data-races -Wframe-larger-than=2048 -fstack-protector-strong -Wimplicit-fallthrough=5 -Wno-main -Wno-unused-but-set-variable -Wno-unused-const-variable -fomit-frame-pointer -fno-stack-clash-protection -fno-inline-functions-called-once -Wdeclaration-after-statement -Wvla -Wno-pointer-sign -Wno-stringop-truncation -Wno-zero-length-bounds -Wno-array-bounds -Wno-stringop-overflow -Wno-restrict -Wno-maybe-uninitialized -Wno-alloc-size-larger-than -fno-strict-overflow -fno-stack-check -fconserve-stack -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wno-packed-not-aligned -DKBUILD_MODFILE='"scripts/mod/devicetable-offsets"' -DKBUILD_BASENAME='"devicetable_offsets"' -DKBUILD_MODNAME='"devicetable_offsets"' -D__KBUILD_MODNAME=kmod_devicetable_offsets -fverbose-asm -S -o scripts/mod/devicetable-offsets.s scripts/mod/devicetable-offsets.c
. ./include/linux/kbuild.h
. ./include/linux/mod_devicetable.h
.. ./include/linux/types.h
... ./include/uapi/linux/types.h
.... ./arch/x86/include/generated/uapi/asm/types.h
..... ./include/uapi/asm-generic/types.h
...... ./include/asm-generic/int-ll64.h
....... ./include/uapi/asm-generic/int-ll64.h
........ ./arch/x86/include/generated/uapi/asm/bitsperlong.h
......... ./include/asm-generic/bitsperlong.h
.......... ./include/uapi/asm-generic/bitsperlong.h
.... ./include/uapi/linux/posix_types.h
..... ./include/linux/stddef.h
...... ./include/uapi/linux/stddef.h
....... ./include/linux/compiler_types.h
..... ./arch/x86/include/generated/uapi/asm/posix_types.h
...... ./include/uapi/asm-generic/posix_types.h
....... ./arch/x86/include/generated/uapi/asm/bitsperlong.h
.. ./include/linux/uuid.h
... ./include/uapi/linux/uuid.h
... ./include/linux/string.h
.... ./include/linux/compiler.h
..... ./arch/x86/include/generated/asm/rwonce.h
...... ./include/asm-generic/rwonce.h
....... ./include/linux/kasan-checks.h
....... ./include/linux/kcsan-checks.h
.... ./include/linux/errno.h
..... ./include/uapi/linux/errno.h
...... ./arch/x86/include/generated/uapi/asm/errno.h
....... ./include/uapi/asm-generic/errno.h
........ ./include/uapi/asm-generic/errno-base.h
.... ./include/linux/stdarg.h
.... ./include/uapi/linux/string.h
.... ./arch/x86/include/asm/string.h
..... ./arch/x86/include/asm/string_64.h
...... ./include/linux/jump_label.h
....... ./arch/x86/include/asm/jump_label.h
........ ./arch/x86/include/asm/asm.h
......... ./include/linux/stringify.h
......... ./arch/x86/include/asm/extable_fixup_types.h
........ ./arch/x86/include/asm/nops.h
In file included from ./arch/x86/include/asm/string.h:5,
                 from ./include/linux/string.h:20,
                 from ./include/linux/uuid.h:12,
                 from ./include/linux/mod_devicetable.h:13,
                 from scripts/mod/devicetable-offsets.c:3:
./arch/x86/include/asm/string_64.h:14:14: warning: conflicting types for built-in function 'memcpy'; expected 'void *(void *, const void *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   14 | extern void *memcpy(void *to, const void *from, size_t len);
      |              ^~~~~~
./arch/x86/include/asm/string_64.h:7:1: note: 'memcpy' is declared in header '<string.h>'
    6 | #include <linux/jump_label.h>
  +++ |+#include <string.h>
    7 |
./arch/x86/include/asm/string_64.h:18:7: warning: conflicting types for built-in function 'memset'; expected 'void *(void *, int,  long unsigned int)' [-Wbuiltin-declaration-mismatch]
   18 | void *memset(void *s, int c, size_t n);
      |       ^~~~~~
./arch/x86/include/asm/string_64.h:18:7: note: 'memset' is declared in header '<string.h>'
./arch/x86/include/asm/string_64.h:58:7: warning: conflicting types for built-in function 'memmove'; expected 'void *(void *, const void *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   58 | void *memmove(void *dest, const void *src, size_t count);
      |       ^~~~~~~
./arch/x86/include/asm/string_64.h:58:7: note: 'memmove' is declared in header '<string.h>'
./arch/x86/include/asm/string_64.h:61:5: warning: conflicting types for built-in function 'memcmp'; expected 'int(const void *, const void *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   61 | int memcmp(const void *cs, const void *ct, size_t count);
      |     ^~~~~~
./arch/x86/include/asm/string_64.h:61:5: note: 'memcmp' is declared in header '<string.h>'
./arch/x86/include/asm/string_64.h:62:8: warning: conflicting types for built-in function 'strlen'; expected 'long unsigned int(const char *)' [-Wbuiltin-declaration-mismatch]
   62 | size_t strlen(const char *s);
      |        ^~~~~~
./arch/x86/include/asm/string_64.h:62:8: note: 'strlen' is declared in header '<string.h>'
In file included from ./include/linux/uuid.h:12,
                 from ./include/linux/mod_devicetable.h:13,
                 from scripts/mod/devicetable-offsets.c:3:
./include/linux/string.h:26:15: warning: conflicting types for built-in function 'strncpy'; expected 'char *(char *, const char *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   26 | extern char * strncpy(char *,const char *, __kernel_size_t);
      |               ^~~~~~~
./include/linux/string.h:21:1: note: 'strncpy' is declared in header '<string.h>'
   20 | #include <asm/string.h>
  +++ |+#include <string.h>
   21 |
./include/linux/string.h:42:15: warning: conflicting types for built-in function 'strncat'; expected 'char *(char *, const char *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   42 | extern char * strncat(char *, const char *, __kernel_size_t);
      |               ^~~~~~~
./include/linux/string.h:42:15: note: 'strncat' is declared in header '<string.h>'
./include/linux/string.h:51:12: warning: conflicting types for built-in function 'strncmp'; expected 'int(const char *, const char *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   51 | extern int strncmp(const char *,const char *,__kernel_size_t);
      |            ^~~~~~~
./include/linux/string.h:51:12: note: 'strncmp' is declared in header '<string.h>'
./include/linux/string.h:57:12: warning: conflicting types for built-in function 'strncasecmp'; expected 'int(const char *, const char *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   57 | extern int strncasecmp(const char *s1, const char *s2, size_t n);
      |            ^~~~~~~~~~~
./include/linux/string.h:91:24: warning: conflicting types for built-in function 'strnlen'; expected 'long unsigned int(const char *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
   91 | extern __kernel_size_t strnlen(const char *,__kernel_size_t);
      |                        ^~~~~~~
./include/linux/string.h:100:24: warning: conflicting types for built-in function 'strspn'; expected 'long unsigned int(const char *, const char *)' [-Wbuiltin-declaration-mismatch]
  100 | extern __kernel_size_t strspn(const char *,const char *);
      |                        ^~~~~~
./include/linux/string.h:100:24: note: 'strspn' is declared in header '<string.h>'
./include/linux/string.h:103:24: warning: conflicting types for built-in function 'strcspn'; expected 'long unsigned int(const char *, const char *)' [-Wbuiltin-declaration-mismatch]
  103 | extern __kernel_size_t strcspn(const char *,const char *);
      |                        ^~~~~~~
./include/linux/string.h:103:24: note: 'strcspn' is declared in header '<string.h>'
./include/linux/string.h:159:12: warning: conflicting types for built-in function 'bcmp'; expected 'int(const void *, const void *, long unsigned int)' [-Wbuiltin-declaration-mismatch]
  159 | extern int bcmp(const void *,const void *,__kernel_size_t);
      |            ^~~~
./include/linux/string.h:162:15: warning: conflicting types for built-in function 'memchr'; expected 'void *(const void *, int,  long unsigned int)' [-Wbuiltin-declaration-mismatch]
  162 | extern void * memchr(const void *,int,__kernel_size_t);
      |               ^~~~~~
./include/linux/string.h:162:15: note: 'memchr' is declared in header '<string.h>'
Multiple include guards may be useful for:
././include/linux/compiler-version.h
./arch/x86/include/asm/string.h
./arch/x86/include/generated/asm/rwonce.h
./arch/x86/include/generated/uapi/asm/errno.h
./arch/x86/include/generated/uapi/asm/posix_types.h
./arch/x86/include/generated/uapi/asm/types.h
./include/generated/autoconf.h
./include/linux/compiler-gcc.h
./include/uapi/linux/errno.h
```

As an effort to figure out the cause of these warnings, I added three `#pragma message` directives:
- In `arch/x86/include/asm/string_64.h` which uses `size_t` for the 3rd parameter, and `size_t` is also the type that's considered conflicting with the built-in function:

```c
#define __HAVE_ARCH_MEMCPY 1
#pragma message("[ywen] __HAVE_ARCH_MEMCPY is defined here")
extern void *memcpy(void *to, const void *from, size_t len);
```

- As the warning messages say, the built-in functions are defined in some "string.h". Among all the code I have so far (as of 2024-06-30), the most possible file is `include/linux/string.h` because it has the declaration `extern void *memcpy(void *, const void *, __kernel_size_t);` where `__kernel_size_t` is expanded to `long unsigned int` which matches the type that's mentioned in the warning messages:

```c
#ifndef __HAVE_ARCH_MEMCPY
extern void *memcpy(void *, const void *, __kernel_size_t);
#pragma message "[ywen] Defining/declaring memcpy"
#elif
#pragma message "[ywen] __HAVE_ARCH_MEMCPY is already defined"
#endif
```

However, a clean build resulted in the following build logs regarding these `#pragma message` directives:

```
./arch/x86/include/asm/string_64.h:14:9: note: '#pragma message: [ywen] __HAVE_ARCH_MEMCPY is defined here'
   14 | #pragma message("[ywen] __HAVE_ARCH_MEMCPY is defined here")
      |         ^~~~~~~
...
./include/linux/string.h:150:9: note: '#pragma message: [ywen] __HAVE_ARCH_MEMCPY is already defined'
  150 | #pragma message "[ywen] __HAVE_ARCH_MEMCPY is already defined"
      |         ^~~~~~~
```

Therefore, the declaration `extern void *memcpy(void *to, const void *from, size_t len);` in `arch/x86/include/asm/string_64.h` was used and this declaration's 3rd parameter was `size_t` which conflicted with the built-in function's 3rd parameter type `long unsigned int`. The declaration `extern void *memcpy(void *, const void *, __kernel_size_t);` in `include/linux/string.h`, although it matches the built-in function's 3rd parameter type because `__kernel_size_t` was an alias of `long unsigned int`, it was not used.

So I had to say I was confused as of 2024-06-24:
- On one hand, I couldn't find the source file that has the built-in function that uses `long unsigned int` as the type of the 3rd parameter. So I thought this built-in function came from the standard header file `string.h` in the C standard library.
- On the other hand, the use of the `gcc` option `-nostdinc` excludes the standard inclusion folders, so the standard C header file `string.h` should not be included.
- As a result, I couldn't figure out where this "built-in function type" came from. So my current decision was to ignore these warnings and move on.

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

## 2024-06-23 (Sun)

My next compilation error is this:

```
need-modorder=
  gcc -Wp,-MMD,scripts/selinux/mdp/.mdp.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89     -I./include/uapi -I./include -I./security/selinux/include -I./include    -o scripts/selinux/mdp/mdp scripts/selinux/mdp/mdp.c
  gcc -Wp,-MMD,scripts/.kallsyms.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89         -o scripts/kallsyms scripts/kallsyms.c
  gcc -Wp,-MMD,scripts/.sorttable.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89      -I./tools/include -I./tools/arch/x86/include -DUNWINDER_ORC_ENABLED   -o scripts/sorttable scripts/sorttable.c   -lpthread
In file included from scripts/sorttable.h:89,
                 from scripts/sorttable.c:195:
./tools/arch/x86/include/asm/orc_types.h:10:10: fatal error: linux/compiler.h: No such file or directory
   10 | #include <linux/compiler.h>
      |          ^~~~~~~~~~~~~~~~~~
compilation terminated.
```

Note there are multiple `compiler.h` files. The one I should copy is `tools/include/linux/compiler.h`, not `include/linux/compiler`. The `-I` options of the `gcc` command is the clue to solve the issue.

## 2024-06-25 (Mon)

Now I have to tackle the error "Compiler lacks asm-goto support." This error message is printed in `jammy/arch/x86/Makefile`:

```makefile
archprepare: checkbin
checkbin:
ifndef CONFIG_CC_HAS_ASM_GOTO
	@echo Compiler lacks asm-goto support.
	@exit 1
endif
```

So I will need to figure out how `CONFIG_CC_HAS_ASM_GOTO` is defined. In the comparison project `ubuntu-kernel-jammy`, it's defined here:

```
debian.master/config/config.common.ubuntu:CONFIG_CC_HAS_ASM_GOTO=y
```

Probably I need to figure out how `debian.master/config/config.common.ubuntu` is included. Next clue: It looks like the build config is created at `jammy/debian/build/tools-perarch/.config` (but there is also `debian/tmp-headers/.config`), so I need to figure out how this `.config` is created. Perhaps I should check the build log. Next clue: It may have something to do with the following part of log (see the command `scripts/kconfig/conf`):

```
make -f ./scripts/Makefile.build obj=scripts/kconfig defconfig
scripts/kconfig/conf  --defconfig=arch/x86/configs/x86_64_defconfig Kconfig
#
# configuration written to .config
#
make[1]: Leaving directory '/lab/learn-linux-kernel/jammy/debian/build/tools-perarch'
mv /lab/learn-linux-kernel/jammy/debian/build/tools-perarch/.config /lab/learn-linux-kernel/jammy/debian/build/tools-perarch/.config.old
```

Eventually, I figured `CONFIG_CC_HAS_ASM_GOTO` is set in `init/Kconfig`:

```
config CC_HAS_ASM_GOTO
	def_bool $(success,$(srctree)/scripts/gcc-goto.sh $(CC))
```

So I should have copied `scripts/gcc-goto.sh` into the source folder. The `init/Kconfig` file uses several other scripts and I should check them as well. See the section above about `init/Kconfig`.

## 2024-06-30 (Sun)

See the section `scripts/mod` about the warnings about conflicting built-in function type. As of today, my current decision was to ignore those warnings and move on because I couldn't figure out the cause after some efforts.

The next build error I needed to work on was as follows:

```
mkdir -p ./tools
make LDFLAGS= MAKEFLAGS=" " O=/lab/learn-linux-kernel/jammy/debian/build/tools-perarch subdir=tools -C ./tools/ objtool
make[2]: *** No rule to make target 'objtool'.  Stop.
make[1]: *** [Makefile:1454: tools/objtool] Error 2
make[1]: Leaving directory '/lab/learn-linux-kernel/jammy/debian/build/tools-perarch'
make: *** [debian/rules.d/2-binary-arch.mk:744: /lab/learn-linux-kernel/jammy/debian/stamps/stamp-build-perarch] Error 2
```
