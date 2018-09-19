#!/bin/bash

# If no env var for FTP_USER has been specified, use 'admin':
if [ "$FTP_USER" = "**String**" ]; then
    export FTP_USER='admin'
fi

# If no env var has been specified, generate a random password for FTP_USER:
if [ "$FTP_PASS" = "**Random**" ]; then
    export FTP_PASS=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-16}`
fi

# Do not log to STDOUT by default:
if [ "$LOG_STDOUT" = "**Boolean**" ]; then
        export LOG_STDOUT=''
else
        export LOG_STDOUT='Yes.'
fi

# Create home dir and update vsftpd user db:
mkdir -p /etc/vsftpd/user/conf
rm -f /etc/vsftpd/virtual_users.txt
rm -f /etc/vsftpd/virtual_users.db

if [ ! -f /etc/vsftpd/user/users.txt ]; then
    echo "${FTP_USER}:${FTP_PASS}" > /etc/vsftpd/user/users.txt
fi

while read -r line
do
    user=(${line//:/ })

    if [ ! -f "/etc/vsftpd/user/conf/${user[0]}" ]; then
        cp /etc/vsftpd/user_config "/etc/vsftpd/user/conf/${user[0]}"
    fi

    if [ ! -d "/home/vsftpd/${user[0]}" ]; then
        mkdir -p "/home/vsftpd/${user[0]}"
    fi

    echo -e "${user[0]}\n${user[1]}" >> /etc/vsftpd/virtual_users.txt
done < /etc/vsftpd/user/users.txt

chown -R ftp:ftp /home/vsftpd/

/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
    export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.run
echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf.run
echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf.run
echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf.run
# Get log file path
export LOG_FILE=`grep xferlog_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# stdout server info:
if [ ! $LOG_STDOUT ]; then
cat << EOB
	*************************************************
	*                                               *
	*    Docker image: fauria/vsftd                 *
	*    https://github.com/fauria/docker-vsftpd    *
	*                                               *
	*************************************************

	SERVER SETTINGS
	---------------
	· FTP User: $FTP_USER
	· FTP Password: $FTP_PASS
	· Log file: $LOG_FILE
	· Redirect vsftpd log to STDOUT: No.
EOB
else
    /usr/bin/ln -sf /dev/stdout $LOG_FILE
fi

# Run vsftpd:
&>/dev/null /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf.run
