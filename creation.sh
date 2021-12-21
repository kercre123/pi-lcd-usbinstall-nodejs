#!/bin/bash

set -e

function detectDrive() {
   if [[ ! -b /dev/sda ]]; then
      if [[ ! -b /dev/sdb ]]; then
        if [[ ! -b /dev/sdc ]]; then
          if [[ ! -b /dev/sdd ]]; then
            echo "no usb"
            exit 0
          else
            echo "using sdd"
            drive="/dev/sdd"
          fi
        else
         echo "using sdc"
         drive="/dev/sdc"
        fi
      else
          echo "using sdb"
          drive="/dev/sdb"
      fi
   else
       echo "using sda"
       drive="/dev/sda"
   fi
}

if [[ $1 = 0 ]]; then
   detectDrive
   sleep 1
   echo "erasing drive"
   sgdisk --zap-all "$drive" && partprobe > /dev/null
   sleep 1
   echo "starting dd"
   sleep 1
   (dd if=manjaro-gnome-21.2.iso | pv -fb | dd of=${drive}) 2>&1
   echo "syncing..."
   sleep 1
   sync &
   echo "completed"
fi

if [[ $1 = 1 ]]; then
   detectDrive
   sleep 1
   echo "erasing drive"
   sgdisk --zap-all "$drive" && partprobe > /dev/null
   sleep 1
   echo "starting dd"
   sleep 1
   (dd if=pop-os_21.10.iso | pv -fb | dd of=${drive}) 2>&1
   echo "syncing..."
   sleep 1
   sync &
   echo "completed"
fi

if [[ $1 = 2 ]]; then
   detectDrive
   sleep 1
   echo "erasing drive"
   sgdisk --zap-all "$drive" && partprobe > /dev/null
   echo "partitioning"
   parted --script ${drive} mklabel msdos
   parted --script ${drive} mkpart primary ntfs 4Mib -- -2049s
   mkfs.ntfs --quick --label Win1021H2 ${drive}1
   echo "waiting"
   sleep 3
   blockdev --rereadpt ${drive}
   echo "uefi workaround"
   sleep 1
   parted --align none --script ${drive} mkpart primary fat16 -- -2048s -1s
   sleep 1
   dd if=uefi-ntfs.img of=${drive}2
   echo "mounting"
   mount "$drive"1 /mnt
   if [ ! -d "/media/winiso" ]
   then
     mkdir /media/winiso
   else
     umount /media/winiso || :; rm -rf /media/winiso; mkdir /media/winiso
   fi
   mount -o loop Win*.iso /media/winiso
   echo "rsyncing..."
   rsync -a --info=progress2 -h --no-links --no-perms --no-owner --no-group /media/winiso/ /mnt/
   #| gawk '1;{fflush()}' RS='\r|\n' | while read -r i; do  echo $i; done | awk '{print $1 "/5.5GB"}'
   echo "wait for sync"
   sleep 2
   umount /media/winiso || :; rm -rf /media/winiso
   umount "$drive"1 &
   pid=$!
   while kill -0 $pid 2> /dev/null; do
      seeDirty=$(grep -e Dirty: -e Writeback: /proc/meminfo | awk '{print $2}' | tr '\n' ' ' | awk '{print $1 "/" $2 " KiB"}')
      echo ${seeDirty}
      sleep 1
   done
   echo "making bootable"
   parted --script ${drive} set 1 boot on
   sync
   echo "completed"
fi
