#!/bin/bash

# start cron service
/etc/init.d/cron start
# start nginx
/opt/nginx/sbin/nginx

/bin/bash
