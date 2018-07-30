#!/bin/sh
#

# NEED TO SET THESE VALUES
# Client name (prefix of ISO file)
client=lauserco
# Folder name (matches FTP folder of ftp.lauserco.com)
folder=lauserco
# Amount of backups to keep (backup rotation)
rotate=2
# Change these values in script:
# CHANGE_USR (username for ftp upload)
# CHANGE_PWD (password for ftp upload)
# CHANGE_FTP (ftp location to upload)

# Current date
currentDate=$(date +%y%m)

# Check rotation
if [ ! -f /var/cache/mondo/rotate.txt ]; then
	mkdir -p /var/cache/mondo
	touch /var/cache/mondo/rotate.txt
	chmod 666 /var/cache/mondo/rotate.txt
fi

# Creating archive and unmounting Mundo ISOs (cleanup)
mondoarchive -OVi9FLp $client-$currentDate -s 4470m -d /var/cache/mondo -E /var/cache/mondo
umount /run/media/root/*

# Sending archive(s) to Lauserco
for i in /var/cache/mondo/$client-$currentDate* ; do
	curl -u 'CHANGE_USR:CHANGE_PWD' --limit-rate 3M -T $i ftp://CHANGE_FTP/$folder/ && echo -n ${i##*/} >> /var/cache/mondo/rotate.txt && echo -n ' ' >> /var/cache/mondo/rotate.txt
	echo -n ${i##*/} >> /var/cache/mondo/rotate.txt && echo -n ' ' >> /var/cache/mondo/rotate.txt
done
echo -ne \\n >> /var/cache/mondo/rotate.txt

# Rotation of backup
if [ $(wc -l /var/cache/mondo/rotate.txt | awk '{print $1}') -le $rotate ]; then
	exit 0
else
	while [ $(wc -l /var/cache/mondo/rotate.txt | awk '{print $1}') -gt $rotate ]; do
		for i in $(sed -n 1p /var/cache/mondo/rotate.txt); do
			curl -u 'CHANGE_USR:CHANGE_PWD' ftp://CHANGE_FTP/$folder/$i -Q "-DELE $i" >/dev/null 2>&1 || break 4
		done
		sed -i '1d' /var/cache/mondo/rotate.txt
	done
	exit 0
fi
echo Did not terminate gracefully
exit 1
