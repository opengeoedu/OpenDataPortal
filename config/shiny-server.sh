#!/bin/bash

# make sure the directory for individual app logs exists
mkdir -p /home/shiny/logs
#chown shiny:ogeportal /var/log/shiny-server
# pre-render data and generate export files

cd /home/shiny
#runuser -l shiny -c "Rscript '/home/shiny/portal/R/generate_all_data.R'"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> /usr/local/lib/R/etc/Renviron
echo "POSTGRES_DB=${POSTGRES_DB}" >> /usr/local/lib/R/etc/Renviron
echo "POSTGRES_USER=${POSTGRES_USER}" >> /usr/local/lib/R/etc/Renviron

#runuser -l shiny -c "export POSTGRESQL_PASSWORD=${POSTGRES_PASSWORD}"

# oreoare oistgrest ´daemon mode
 cat /opt/postgrest/postgrest.conf  | sed 's/)/}/g' | sed 's/(/{/g' | envsubst >> /opt/postgrest/postgrest-static.conf
service postgrest.init start
exec shiny-server >> /home/shiny/portal/logs/shiny-server.log
