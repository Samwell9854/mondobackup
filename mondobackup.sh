#!/bin/sh
# Set at least 744 permissions on this file to run properly

#############################################################################
# NEED TO SET THESE VALUES
# Client name (prefix of ISO file)
client=
# Folder name (matches FTP folder)
folder=
# Amount of backups to keep (backup rotation)
rotate=2
# Username for FTP upload
usr=
# Password for FTP upload
passwd=
# FTP location to upload
url=
# Bandwidth to allocate upload, check curl manual
# Put number followed with K (KB) or M (MB), no space, small letters OK
spd=
#############################################################################

# Current date
currentDate=$(date +%y%m)

# Check rotation
if [ ! -f /var/cache/mondo/rotate.txt ]; then
	mkdir -p /var/cache/mondo
	touch /var/cache/mondo/rotate.txt
	chmod 666 /var/cache/mondo/rotate.txt
fi

# Creating archive and unmounting Mundo ISOs (cleanup)
/usr/sbin/mondoarchive -OVi9Fp $client-$currentDate -s 4480m -d /var/cache/mondo -E /var/cache/mondo
umount /run/media/root/*

# Sending archive(s)
for i in /var/cache/mondo/$client-$currentDate* ; do
	curl -u $usr:$passwd --limit-rate $spd -T $i ftp://$url/$folder/ && echo -n ${i##*/} >> /var/cache/mondo/rotate.txt && echo -n ' ' >> /var/cache/mondo/rotate.txt
done
echo -ne \\n >> /var/cache/mondo/rotate.txt

# Cleaning up local ISO files
rm -f /var/cache/mondo/*.iso

# Rotation of backup
if [ $(wc -l /var/cache/mondo/rotate.txt | awk '{print $1}') -le $rotate ]; then
	exit 0
else
	while [ $(wc -l /var/cache/mondo/rotate.txt | awk '{print $1}') -gt $rotate ]; do
		for i in $(sed -n 1p /var/cache/mondo/rotate.txt); do
			curl -u $usr:$passwd ftp://$url/$folder/$i -Q "-DELE $i" >/dev/null 2>&1 || break 4
		done
		sed -i '1d' /var/cache/mondo/rotate.txt
	done
	exit 0
fi
echo Did not terminate gracefully
exit 1
