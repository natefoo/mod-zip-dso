# mod-zip-dso

Some [Galaxy](http://galaxyproject.org) servers run a version of nginx recompiled from the EPEL spec using
[Starforge](https://github.com/galaxyproject/starforge/tree/master/nginx) to include the nginx upload module. RPMs are
hosted on the "[GPEL](https://depot.galaxyproject.org/yum/)" at https://depot.galaxyproject.org/yum/.

The upload module should no longer be necessary thanks to the integration of [tus](http://tus.io) in Galaxy. However,
until tus support is added to [Pulsar](https://github.com/galaxyproject/pulsar), the upload module may still be used for
Pulsar staging.

It is also possible to serve Galaxy collection dataset downloads using [mod_zip](https://github.com/evanmiller/mod_zip/)
(see [documentation](https://docs.galaxyproject.org/en/latest/admin/nginx.html#creating-archives-with-mod-zip)), but I
didn't want to recompile and release new nginx-galaxy packages since they should no longer be needed soon anyway. So
this repository exists as a place to put the build script for a dynamic mod_zip against nginx-galaxy, as well as the
module itself so that I can install it to my Galaxy servers using Ansible.

See also, other ways people are building the upload module, which also removes the need for my outdated packages:

- https://github.com/mtangaro/nginx-upload-module-build from @mtangaro for building the module for EL
- https://github.com/usegalaxy-au/infrastructure/tree/master/roles/nginx-upload-module from @cat-bro for building the
  module for Debian/Ubuntu
