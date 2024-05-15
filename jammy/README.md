# Ubuntu Jammy

## Overview

The main reference is [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy).

My approach of learning is simple & stupid:
- I know the code [`~ubuntu-kernel-stable/jammy`](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy) builds.
- I know the build process starts with the file [debian/rules](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian/rules) (See the section "How to build").

So I'm doing it this way: Copy the whole [`debian` folder](https://git.launchpad.net/~ubuntu-kernel-stable/+git/jammy/tree/debian) into this repository, and run `debian/rules` repeatedly. Surely I'll run into a lot of build errors, but I'll resolve them one by one until I get the kernel built. This way, I'll probably end up with the minimal set of needed source files.

Note: Because I work on `x86` machines, I will focus on building the code on `x86` platforms, so I may not copy the source files that are only needed for building on other platforms.

## How to build

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
      - Because the target `binary` depends on two sub-targets: `binary-indep` and `binary-arch`, one can start with `LANG=C fakeroot debian/rules binary-indep`.

## How to resume the previous work

Because I can't finish the kernel building in one sitting, I need to write down how to resume the work:
- 1). `cd ~/yaobin/code/linux-lab`.
- 2). `vagrant up` to start up the VM `ywen-linux-lab`. (See `Linux-Lab` for more details.)
- 3). `vagrant ssh` to log into the VM.
- 4). `cd /lab/learn-linux-kernel/jammy`: This is where I've been building the kernel code.
- 5). `cd /lab/ubuntu-kernel-jammy`: This is the folder I built successfully before so it can be used as a reference.

## Build verbosity

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

## Build progress

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
          - [ ] `jammy/Makefile`.
            - [ ] `__sub-make`
              - [ ] `defconfig` in `jammy/Makefile`
                - [ ] `defconfig` in `jammy/scripts/kconfig/Makefile`
                  - [ ] `x86_64_defconfig` in `jammy/Makefile`
                    - [ ] `x86_64_defconfig` in `jammy/scripts/kconfig/Makefile`
            - [ ] WIP: L116: "# Call a source code checker (by default, "sparse") as part of the"
- [ ] (To be continued)

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
