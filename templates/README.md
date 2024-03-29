<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [packer-templates](#packer-templates)
  - [Purpose](#purpose)
  - [Information](#information)
  - [Requirements](#requirements)
    - [Software](#software)
  - [Usage](#usage)
    - [Building a box](#building-a-box)
      - [Select distro](#select-distro)
      - [Build distro](#build-distro)
    - [Testing a box](#testing-a-box)
      - [Add box to Vagrant](#add-box-to-vagrant)
      - [Create Vagrantfile](#create-vagrantfile)
      - [Spin it up](#spin-it-up)
      - [Test it out](#test-it-out)
      - [Tear it down](#tear-it-down)
    - [Cleaning up](#cleaning-up)
    - [Using pre-built and ready for consumption Vagrant templates](#using-pre-built-and-ready-for-consumption-vagrant-templates)
  - [License](#license)
  - [Author Information](#author-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# packer-templates

## Purpose

This repository is for maintaining my personal
[Vagrant Box Templates](https://github.com/mrlesmithjr/vagrant-box-templates)
using [Packer](https://www.packer.io).

## Information

All builds are based on the following providers:

- [virtualbox](https://www.virtualbox.org)
- [vmware_desktop](https://www.vmware.com)

- You can find my collection of builds [here](https://app.vagrantup.com/mrlesmithjr)

> NOTE: All builds are base builds and follow the Vagrant [guidelines](https://www.vagrantup.com/docs/boxes/base.html) of how a Vagrant
> box should be built.

## Requirements

All of my Packer templates are configured to upload to Vagrant Cloud after a successful build has been executed. In order to upload a box version to Vagrant Cloud, you will need to create a `private_vars.json` file in the root of this repo with the following info:

```json
{
  "vagrant_cloud_token": "Your Vagrant Cloud private API token",
  "vagrant_cloud_username": "Your Vagrant Cloud username"
}
```

If you do not want this functionality, you will need to edit the respective template within the distro folder and remove the following:

```json
{
  "type": "vagrant-cloud",
  "box_tag": "{{ user `box_tag` }}",
  "access_token": "{{ user `vagrant_cloud_token` }}",
  "version": "{{ timestamp }}"
}
```

### Software

- [Packer](https://www.packer.io)
- [Virtualbox](https://www.virtualbox.org)

## Usage

### Building a box

To build a [Vagrant](https://www.vagrantup.com) box with [Packer](https://packer.io)
for [Virtualbox](https://www.virtualbox.org):

#### Select distro

Choose which distro you are interested in building.

#### Build distro

> NOTE: This example we will have chosen Ubuntu Xenial

```bash
cd Ubuntu/xenial64/server
packer build -var-file=../../../private_vars.json -var-file=ubuntu1604.json ../../ubuntu-server.json
```

Now watch your build kick off and run through the building process. Once it has
completed you will be ready to test it out.

### Testing a box

Once your build has completed you are ready to test it out.

#### Add box to Vagrant

> Note: The number at the end is the epoch time of the build. Replace this accordingly.

```bash
cd Ubuntu/xenial64/server
vagrant box add xenial64-server-packer-template-virtualbox-1542509766 xenial64-server-packer-template-virtualbox-1542509766.box
```

#### Create Vagrantfile

```bash
cd ~
mkdir -p packer/vagrant/xenial64-server
cd packer/vagrant/xenial64-server
vagrant init xenial64-server-packer-template-virtualbox-1542509766
```

#### Spin it up

```bash
vagrant up
```

#### Test it out

```bash
vagrant ssh
```

Now do some basic tests to validate all is good.

#### Tear it down

```bash
vagrant destroy -f
```

### Cleaning up

When you need to clean up any of the lingering files/folers generated during
building, you can execute the [cleanup_builds.sh](cleanup_builds.sh) script.

### Using pre-built and ready for consumption Vagrant templates

The majority of these templates are used to test [ansible-datacenter VM provisioning playbooks](https://github.com/lj020326/ansible-datacenter) using the [packer-box-templates](https://github.com/lj020326/vm-templates) repo. I would highly recommend leveraging this repo for testing ansible playbook and etc.

## Commands

```shell
build_vm_template.sh
build_vm_template.json.sh

## upgrading json formatted inputs to new HCL2 format
packer hcl2_upgrade -with-annotations common-vars.vars.json 
packer hcl2_upgrade common-vars.json
packer hcl2_upgrade test-vars.json 

VARS_JSON=$(jq --argjson varInfo "$(<common-vars.json)" '.variables += $varInfo' -n '{variables: $varInfo }')
echo $VARS_JSON | packer hcl2_upgrade -with-annotations
echo $VARS_JSON | packer hcl2_upgrade -with-annotations -output-file=foo

## Running packer build for CentOS
env PACKER_LOG=1 BUILD_TAG=build_vm_template.json.sh-test packer build \
    -only vsphere-iso \
    -on-error=ask \
    -var-file=common-vars.json \
    -var-file=CentOS/distribution-vars.json \
    -var-file=CentOS/8/server/box_info.json \
    -var-file=CentOS/8/server/template.json \
    -var vm_name=vm-template-CentOS-8-test \
    -var iso_dir=CentOS/8 \
    -var iso_file=CentOS-8.5.2111-x86_64-dvd1.iso \
    -force \
    CentOS/build-config.json

## Running packer build for CentOS
packer validate \
    -only vsphere-iso.* \
    -var-file=CentOS/distribution-vars.json.pkrvars.hcl \
    -var-file=CentOS/8/server/box_info.json.pkrvars.hcl \
    -var-file=CentOS/8/server/template.json.pkrvars.hcl \
    -var vm_name=vm-template-centos8 \
    -var iso_dir=CentOS/8 \
    -var iso_file=CentOS-8.5.2111-x86_64-dvd1.iso \
    CentOS/

packer validate \
    -only vsphere-iso.* \
    -var-file=CentOS/distribution-vars.json.pkrvars.hcl \
    -var-file=CentOS/8/server/server/box_info.json.pkrvars.hcl \
    -var-file=CentOS/8/server/server/template.json.pkrvars.hcl \
    -var vm_name=vm-template-centos8 \
    -var iso_dir=CentOS/8 \
    -var iso_file=CentOS-8.5.2111-x86_64-dvd1.iso \
    CentOS/

packer validate \
    -only vsphere-iso.* \
    -var-file=Ubuntu/distribution-vars.json.pkrvars.hcl \
    -var-file=Ubuntu/22.04/server/box_info.json.pkrvars.hcl \
    -var-file=Ubuntu/22.04/server/template.json.pkrvars.hcl \
    -var vm_name=vm-templates-ubuntu-22.04-0001 \
    -var iso_dir=Ubuntu/22.04 \
    -var iso_file=ubuntu-22.04-live-server-amd64.iso \
    Ubuntu/
ssh packer@10.10.100.173
ssh packer@10.10.100.73
```

## Reference

* https://github.com/chef/bento
* https://github.com/burkeazbill/ubuntu-22-04-packer-fusion-workstation/blob/master/http/user-data
* https://github.com/williamsanmartin/packer-template-ubuntu/blob/main/http/user-data
* [vagrant-box-templates](https://github.com/mrlesmithjr/vagrant-box-templates)
* https://github.com/mwrock/packer-templates
* https://github.com/jacqinthebox/packer-templates
* https://github.com/geerlingguy/packer-boxes
* 