FROM centos:7

LABEL maintainer="Fer Uria <fauria@gmail.com>" \
      description="vsftpd Docker image based on Centos 7. Supports passive mode and virtual users." \
      license="Apache License 2.0" \
      usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd fauria/vsftpd" \
      version="1.0"

RUN yum -y update && yum clean all
RUN yum install -y \
	vsftpd \
	db4-utils \
	db4 \
	&& yum clean all

ENV FTP_USER=**String** \
    FTP_PASS=**Random** \
    PASV_ADDRESS=**IPv4** \
    PASV_MIN_PORT=21100 \
    PASV_MAX_PORT=21110 \
    LOG_STDOUT=**Boolean**

COPY vsftpd.conf user_config /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/

RUN mkdir -p /home/vsftpd \
    && chown -R ftp:ftp /home/vsftpd \
	&& chmod +x /usr/sbin/run-vsftpd.sh

EXPOSE 20 21
VOLUME [ "/home/vsftpd", "/var/log/vsftpd", "/etc/vsftpd/user" ]
CMD [ "/usr/sbin/run-vsftpd.sh" ]
