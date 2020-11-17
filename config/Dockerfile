FROM rocker/geospatial
LABEL maintainer="OpenGeoEdu"


#---- Thanks to rocker-org (from https://github.com/rocker-org/shiny/blob/master/Dockerfile)
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget

# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    . /etc/environment && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='$MRAN')" && \
    chown shiny:shiny /var/lib/shiny-server
#------

#RUN ["installGithub.r", "o2r-project/containerit"]
RUN ["installGithub.r", "matthiashinz/containerit@dev"]
#---- install odbs/postgres drivers
RUN apt-get update && apt-get install -y  unixodbc unixodbc-dev --install-suggests && apt-get install odbc-postgresql

RUN ["installGithub.r", "r-dbi/odbc"]
#---- install odbs/postgres drivers
EXPOSE 80

COPY config/shiny-server.sh /usr/bin/shiny-server.sh
COPY config/shiny-server.conf /etc/shiny-server/shiny-server.conf
#---- POSTGREST

ENV POSTGREST_VERSION v7.0.1
RUN apt-get -qq update && \
   apt-get -qqy --no-install-recommends install \
   curl ca-certificates build-essential \
   libpq-dev vim gettext && \
   curl -sSL https://get.haskellstack.org/ | bash && \
   apt-get -qq clean
RUN cd /tmp && \
    curl -SLO https://github.com/PostgREST/postgrest/releases/download/${POSTGREST_VERSION}/postgrest-${POSTGREST_VERSION}-linux-x64-static.tar.xz && \
    tar -xJvf postgrest-${POSTGREST_VERSION}-linux-x64-static.tar.xz && \
    mv postgrest /usr/local/bin/postgrest && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/
#RUN mkdir /home/postgres && chown -R postgres /home/postgres/
COPY config/postgrest.conf /opt/postgrest/
#COPY config/postgrest.service /etc/systemd/system/
COPY config/run-postgrest.sh /usr/sbin/
COPY config/postgrest.init /etc/init.d/
RUN chmod 755 /usr/sbin/run-postgrest.sh && chmod 755 /etc/init.d/postgrest.init && cd /etc/init.d/ && update-rc.d postgrest.init defaults 97 03
#RUN apt-get install --reinstall systemd && systemctl enable postgrest


CMD ["/usr/bin/shiny-server.sh"]
