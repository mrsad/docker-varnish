# Varnish
# Use phusion/baseimage as base image
FROM ubuntu:trusty
MAINTAINER Peter S. "mrsad.info@gmail.com"

# make sure the package repository is up to date
RUN apt-get update
RUN apt-get install git pkg-config dpkg-dev autoconf curl make autotools-dev automake libtool libpcre3-dev libncurses-dev python-docutils bsdmainutils debhelper dh-apparmor gettext gettext-base groff-base html2text intltool-debian libbsd-dev libbsd0 libcroco3 libedit-dev libedit2 libgettextpo0 libpipeline1 libunistring0 man-db po-debconf xsltproc -y

# install varnish
RUN cd /opt && curl -s http://varnish-cache.org/_downloads/varnish-3.0.7.tgz | tar zxvf -
RUN cd /opt/varnish-3.0.7 && ./autogen.sh && ./configure && make -j3 && make install

# install varnish libvmod-throttle
#RUN git clone https://github.com/nand2/libvmod-throttle.git /opt/libvmod-throttle
#RUN cd /opt/libvmod-throttle && ./autogen.sh && ./configure VARNISHSRC=/opt/varnish-3.0.7 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib && make -j3 && make install

ENV LISTEN_ADDR 0.0.0.0
ENV LISTEN_PORT 6081
ENV TELNET_ADDR 0.0.0.0
ENV TELNET_PORT 6083
ENV CACHE_SIZE 25MB
ENV THROTTLE_LIMIT 150req/30s
ENV VCL_FILE /etc/varnish/default.vcl
ENV GRACE_TTL 30s
ENV GRACE_MAX 1h

# Keep config
ADD config/default.vcl /etc/varnish/default.vcl.source


# Create a runit entry for your app
RUN mkdir -p /usr/local/bin
ADD bin/run.sh /usr/local/bin/varnish.sh
RUN chown root /usr/local/bin/varnish.sh
RUN chmod +x /usr/local/bin/varnish.sh
#RUN echo "#!/bin/bash" > /etc/rc.local
#RUN echo "/usr/local/bin/varnish.sh" >> /etc/rc.local

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /opt/varnish-3.0.7 /opt/libvmod-throttle

EXPOSE 6081

CMD ["/usr/local/bin/varnish.sh"]
