#!/bin/sh

# Default values for option variables
rotate=1

# Usage info
usage() {
  cat << EOF
Usage: mondobackup OPTIONS

General options:

  -c, --client               Client name (prefix of ISO file).
  -d, --dir                  Directory name (matches FTP folder).
  -r, --rotate               Amount of backups to keep (backup rotation) [default=1].
  -u, --username             Username for FTP upload.
  -p, --password             Password for FTP upload.
                             Encapsulate inside '' to avoid command substitution.
  -U, --url                  FTP location to upload (FQDN only).
  -R, --rate                 Bandwidth to allocate upload, check curl manual.
                             Put number followed with K (KB) or M (MB), no space, small letters OK.
  -h, --help                 Display this help and exit.

EOF
}

# Parse options
optspec=":c:d:r:u:p:U:R:h-:"
while getopts "$optspec" optchar; do
   case "${optchar}" in

      # Short options
      c) client=${OPTARG};;
      d) dir=${OPTARG};;
      r) rotate=${OPTARG};;
      u) usr=${OPTARG};;
      p) passwd=${OPTARG};;
      U) url=${OPTARG};;
      R) rate=${OPTARG};;
      h) usage; exit 0;;

      -)
         case "${OPTARG}" in
            # Long options
            client) client=${OPTARG};;
            dir) dir=${OPTARG};;
            rotate) rotate=${OPTARG};;
            username) usr=${OPTARG};;
            password) passwd=${OPTARG};;
            url) url=${OPTARG};;
            rate) rate=${OPTARG};;

            *)
               echo "Unknown option --${OPTARG}" >&2
               usage >&2;
               exit 1
               ;;
         esac;;
  
      *)
         echo "Unknown option -${OPTARG}" >&2
         usage >&2
         exit 1
         ;;
   esac
done
if [ $# -eq 0 ]; then
  echo "No options specified."
  usage
  exit 1
fi

shift "$((OPTIND-1))"

if [ -z "$client" ] || [ -z "$dir" ] || [ -z "$usr" ] || [ -z "$passwd" ] || [ -z "$url" ] || [ -z "$rate" ]; then
   echo "Missing or invalid argument."
   echo
   usage
   exit 1
fi

# Current date
currentDate=$(date +%y%m)

# Check rotation
if [ ! -f /var/cache/mondo/rotate.txt ]; then
   mkdir -p /var/cache/mondo
   touch /var/cache/mondo/rotate.txt
   chmod 666 /var/cache/mondo/rotate.txt
fi

# Creating archive
/usr/sbin/mondoarchive -OVi9Fp $client-$currentDate -s 4480m -d /var/cache/mondo -E "/var/cache/mondo|/var/spool/asterisk/voicemail/"

# Helper - Unmounting Mundo ISOs / temp files (cleanup)
umount /run/media/root/*
mount | grep mpt && (
   for i in $(mount | grep mpt | awk {'print $4'}); do
      umount $i
   done
   rm -Rf /tmp/mondo.tmp.*
)

# Sending archive(s)
for i in /var/cache/mondo/$client-$currentDate* ; do
   curl -u $usr:$passwd --limit-rate $rate -T $i ftp://$url/$dir/
   echo -n ${i##*/} >> /var/cache/mondo/rotate.txt
   echo -n ' ' >> /var/cache/mondo/rotate.txt
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
         curl -u $usr:$passwd ftp://$url/ -Q "DELE $dir/$i" >/dev/null 2>&1 || break 4
      done
      sed -i '1d' /var/cache/mondo/rotate.txt
   done
   exit 0
fi
echo Did not terminate gracefully
exit 1

