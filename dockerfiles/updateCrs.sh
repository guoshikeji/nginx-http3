#!/bin/bash

# download latest owasp-modsecurity-crs
cd /opt 
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git &
wait

# update nginx config
rm -r /opt/nginx/conf/rules
mv owasp-modsecurity-crs/rules /opt/nginx/conf
mv owasp-modsecurity-crs/crs-setup.conf.example /opt/nginx/conf/crs-setup.conf
rm -r owasp-modsecurity-crs

/opt/nginx/sbin/nginx -s reload

