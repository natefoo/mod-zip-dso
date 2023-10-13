#!/bin/bash
# stopgap to build mod_zip DSO for nginx-galaxy before that package goes away entirely
set -euo pipefail

nginx_version='1.12.2'
upload_module_version='2.255-nfs'
auth_pam_module_version='1.4'
mod_zip_version='1.3.0'
gid=$(id -g)
uid=$(id -u)

curl -LO "http://nginx.org/download/nginx-${nginx_version}.tar.gz"
curl -LO "https://github.com/natefoo/nginx-upload-module/archive/${upload_module_version}.tar.gz"
curl -LO "https://github.com/sto/ngx_http_auth_pam_module/archive/refs/tags/v${auth_pam_module_version}.tar.gz"
curl -LO "https://github.com/evanmiller/mod_zip/archive/refs/tags/${mod_zip_version}.tar.gz"

tar zxf "nginx-${nginx_version}.tar.gz"
tar zxf "${upload_module_version}.tar.gz" -C "nginx-${nginx_version}"
tar zxf "v${auth_pam_module_version}.tar.gz" -C "nginx-${nginx_version}"
tar zxf "${mod_zip_version}.tar.gz" -C "nginx-${nginx_version}"

# nginx build args from nginx -V on galaxy07
cat >build-mod-zip-dso-root.sh <<EOF
#!/bin/bash
set -euo pipefail

groupadd -g ${gid} build
useradd -u ${uid} -g ${gid} -d /build build

yum install -y '@development tools' openssl-devel pcre-devel zlib-devel pam-devel libxslt-devel gd-devel perl-devel perl-ExtUtils-Embed GeoIP-devel gperftools-devel

su - build -c '/bin/bash /build/build-mod-zip-dso-build.sh'
EOF

cat >build-mod-zip-dso-build.sh <<EOF
#!/bin/bash
set -euo pipefail

cd /build/nginx-${nginx_version}
./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-file-aio --with-ipv6 --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream=dynamic --with-stream_ssl_module --with-google_perftools_module --add-module=nginx-upload-module-${upload_module_version} --add-module=ngx_http_auth_pam_module-${auth_pam_module_version} --with-debug --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' --add-dynamic-module=mod_zip-${mod_zip_version}
make
cp objs/ngx_http_zip_module.so ..
EOF

docker run --rm --name=build-mod-zip-dso -v ${PWD}:/build centos:7 /bin/sh /build/build-mod-zip-dso-root.sh
