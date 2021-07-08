#!/bin/sh
mindi_conf=/etc/mindi/mindi.conf
extra_space=600000
boot_size=327680
mondocron=/etc/cron.d/mondobackup

install() {
  cp -f mondobackup.sh /usr/bin/mondobackup
  chmod 744 /usr/bin/mondobackup
  sed -i "/EXTRA_SPACE/c EXTRA_SPACE = $extra_space" $mindi_conf
  if grep -q BOOT_SIZE $mindi_conf; then
    sed -i "/BOOT_SIZE/c BOOT_SIZE = $boot_size" $mindi_conf
  else
    sed -i "/^EXTRA_SPACE.*/a BOOT_SIZE = $boot_size" $mindi_conf
  fi
  exit 0
}

uninstall() {
	rm -f /usr/bin/mondobackup
	(crontab -l | sed -e '/mondobackup/d') | crontab -
}

if [ $# -eq 0 ]; then
  # Migrate
  if [ -f "$mondocron" ]; then
    crontab -l | grep -v mondobackup > cron.tmp
    crontab -l | grep mondobackup | cut -d' ' -f 1-5 > cron.tmpa
    echo mondobackup >> cron.tmpa
    echo "-c $(grep client= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    echo "-d $(grep folder= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    echo "-r $(grep rotate= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    echo "-u $(grep usr= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    echo -ne "'" >> cron.tmpa
    echo -ne "-p $(grep passwd= $mondocron | cut -d'=' -f2-)" >> cron.tmpa
    echo "'" >> cron.tmpa
    echo "-U $(grep url= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    echo "-R $(grep rate= $mondocron | cut -d'=' -f2)" >> cron.tmpa
    tr '\n' ' ' < cron.tmpa >> cron.tmp
    echo -ne '\n' >> cron.tmp
    crontab cron.tmp
    rm -f $mondocron
    rm -f cron.tmp*
  fi
  install
fi

# Parse options
optspec="-"
while getopts "$optspec" optchar; do
  case "${optchar}" in
    
    -)
      case "${OPTARG}" in
        # Long options
	uninstall) uninstall;;

	*)
          echo "Unknown option --${OPTARG}" >&2
	  exit 1
	  ;;
      esac;;

    *)
      echo "Unknown option -${OPTARG}" >&2
      exit 1
      ;;
  esac
done

