#! /usr/bin/env bash
packer build -except=qemu -var-file=../../../private_vars.json \
  -var-file=box_info.json -var-file=template.json ../../ubuntu-server.json

command -v qemu-system-x86_64 --version >/dev/null 2>&1
QEMU_CHECK=$?
if [ $QEMU_CHECK -eq 0 ]; then
  if [[ $(uname) == "Darwin" ]]; then
    QEMU_ACCEL="hvf"
  elif [[ $(uname) == "Linux" ]]; then
    QEMU_ACCEL="kvm"
  fi
  packer build -only=qemu -var qemu_accelerator=$QEMU_ACCEL \
    -var-file=../../../private_vars.json -var-file=box_info.json \
    -var-file=template.json ../../ubuntu-server.json
fi
