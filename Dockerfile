FROM debian:bookworm-slim

# Install the packages we need. Avahi will be included
RUN apt-get update && apt-get install -y cups \
	gcc \
	cups-pdf \
	cups-client \
	cups-filters \
	libcups2-dev \
	ghostscript \
	avahi-daemon \
	inotify-tools \
	python3-setuptools \
	python3 \
	python3-dev \
	wget \
	rsync \
	perl \
	git \
	printer-driver-cups-pdf \
	gettext \
	cmake \
	pkg-config

RUN git clone https://github.com/OpenPrinting/pycups.git && \
	cd pycups && \
	make && \
	make install

# Build and install brlaser from source
# RUN git clone https://github.com/pdewacht/brlaser.git && \
#     cd brlaser && \
#     cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 . && \
#     make && \
#     make install && \
#     cd .. && \
#     rm -rf brlaser

# Build and install gutenprint from source
# RUN wget -O gutenprint-5.3.5.tar.xz https://sourceforge.net/projects/gimp-print/files/gutenprint-5.3/5.3.5/gutenprint-5.3.5.tar.xz/download && \
#     tar -xJf gutenprint-5.3.5.tar.xz && \
#     cd gutenprint-5.3.5 && \
#     # Patch to rename conflicting PAGESIZE identifiers to GPT_PAGESIZE in all files in src/testpattern
#     find src/testpattern -type f -exec sed -i 's/\bPAGESIZE\b/GPT_PAGESIZE/g' {} + && \
#     ./configure && \
#     make -j$(nproc) && \
#     make install && \
#     cd .. && \
#     rm -rf gutenprint-5.3.5 gutenprint-5.3.5.tar.xz && \
#     # Fix cups-genppdupdate script shebang
#     sed -i '1s|.*|#!/usr/bin/perl|' /usr/sbin/cups-genppdupdate

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
 	sed -i 's/IdleExitTimeout/#IdleExitTimeout/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
	echo "ReadyPaperSizes A4,TA4,4X6FULL,T4X6FULL,2L,T2L,A6,A5,B5,L,TL,INDEX5,8x10,T8x10,4X7,T4X7,Postcard,TPostcard,ENV10,EnvDL,ENVC6,Letter,Legal" >> /etc/cups/cupsd.conf && \
	echo "DefaultPaperSize Letter" >> /etc/cups/cupsd.conf && \
	echo "pdftops-renderer ghostscript" >> /etc/cups/cupsd.conf
