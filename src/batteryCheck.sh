#!/bin/sh
################################################################################
# Incredibly simple battery status checker.  Depends on acpi.
#
# Released under GPLv2
# (c) 2008-2010 dleonard@dleonard.net
################################################################################

ACPI_DIR="/proc/acpi/battery"
SYSFS_DIR="/sys/class/power_supply"

################################################################################
# battery_state_sysfs
# I: battery name
# Look up state of the battery, calculate useful info, and output it
################################################################################
battery_state_sysfs() {
 battery=$1;

 echo "Battery: $battery"

 remaining=`cat $SYSFS_DIR/$battery/energy_now`
 capacity=`cat $SYSFS_DIR/$battery/energy_full`

 percent=`echo "scale=4;($remaining/$capacity)*100" | bc | sed 's/[0-9][0-9]$//'`
 echo "$percent% charged"
   
 status=`cat $SYSFS_DIR/$i/status`
 if [ "$status" = "Discharging" ]; then
  rate=`cat $SYSFS_DIR/$battery/power_now`
  estimated_life=`echo "scale=2;$remaining/$rate" | bc`
  echo "Estimated hours remaining: $estimated_life"
 else
  echo "Not on battery"
 fi
}

################################################################################
# battery_state_acpi
# I: battery name (optional)
# Look up state of the battery, calculate useful info, and output it
################################################################################
battery_state_acpi() {
 battery=$1;

 if [ "$battery" != "" ]; then
  echo "Battery: $battery"
 fi

 remaining=`awk '/remaining/ {print $3}' $STATE`
 capacity=`awk '/last full capacity/ {print $4}' $INFO`
 
 percent=`echo "scale=4;($remaining/$capacity)*100" | bc | sed 's/[0-9][0-9]$//'`
 echo "$percent% charged"

 on_battery=`awk '/charging state/ {print $3}' $STATE`
 if [ "$on_battery" = "discharging" ]; then
  rate=`awk '/present rate/ {print $3}' $STATE`
  estimated_life=`echo "scale=2;($remaining/$rate)" | bc`
  echo "Estimated hours remaining: $estimated_life"
 else
  echo "Not on battery"
 fi
}

batteries=`ls $SYSFS_DIR`
if [ "$batteries" != "" ]; then
 for i in $batteries; do
  if [ "$i" != "AC" ]; then
   battery_state_sysfs $i
  fi
 done
 exit 0
else
 batteries=`ls $ACPI_DIR`
 if [ "$batteries" != "" ]; then
  for i in $batteries; do
   STATE="$ACPI_DIR/$i/state"
   INFO="$ACPI_DIR/$i/info"

   if [ ! -f "$STATE" -o ! -f "$INFO" ]; then
    echo "Unable to get state or info of battery $i from ACPI under /proc"
    exit 1
   fi

   if [ "$i" = "BAT0" ]; then
    battery_state_acpi
   else
    battery_state_acpi $i
   fi
  done
  exit 0
 fi
fi

echo "Unable to look up battery info via sysfs or ACPI under /proc"
exit 1
