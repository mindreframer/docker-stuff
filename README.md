# docker cookbook

This is a docker.io cookbook that can be used to install docker, pull base
images (with a `docker_image` LWRP), and if necessary upgrade your kernel
to one support AUFS.

On Rackspace Cloud this cookbook will also optionally install a menu.lst to
boot the AUFS supporting Kernel.

# Requirements

* Ohai and Chef

## Cookbooks

* ohai
* apt

## Platforms

* Ubuntu 12.04

## Clouds

* Rackspace Cloud

# Usage

# Attributes

## Installation

* `node['docker']['install_method']` - Method to install, currently only `ppa`.
* `node['docker']['kernel_package']` - The name of an AUFS supporting kernel
    package that will be installed if AUFS is not available.  Default: `linux-image-3.8.0-21-generic`
* `node['docker']['menu_lst?']` - Should we install a menu.lst for the above
    kernel if on Rackspace Cloud?  Default: `true`

### Warning

If `kernel_package` is changed then `menu_lst?` should be disabled and on Rackspace Cloud you should manage your own `/boot/grub/menu.lst` file.

# Recipes

* `docker::default` - Install docker.io using `node['docker']['install_method']`.
* `docker::install-ppa` - Install docker.io with the dotcloud PPAs.
* `docker::aufs` - Install an AUFS capable kernel.
* `docker::test` - Testing usages of the `docker_image` LWRP.

# LWRPs

## docker_image

### Example:

```
docker_image "ubuntu" do
  tag "precise"
  action :add
end
```

### Actions

* `:add` - pull an new image.
* `:delete` - Remove an image.

### Attributes

* `name` - The name of the image to download.
* `tag` - A specific tag of a named image.  Default: `nil`
* `registry` - The base registry URL, if none is specified index.docker.io will
    be used.  Default: `nil`.

# Author

Author:: David Reid (<dreid@dreid.org>)
