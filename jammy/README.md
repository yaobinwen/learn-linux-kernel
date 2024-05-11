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
  - 4.3 Build in one of the following ways:
    - 4.3.1 (Quicker build) `LANG=C fakeroot debian/rules binary-headers binary-generic binary-perarch`
    - 4.3.2 (Need linux-tools or lowlatency kernel) `LANG=C fakeroot debian/rules binary`
