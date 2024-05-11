#!/bin/sh

if test "$(id -u)" -ne 0; then
    echo "Please run this script as root." >&2
    exit 1
fi

apt-get update || exit
apt-get install -y --no-install-recommends ansible || exit
