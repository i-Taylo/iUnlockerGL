#!/system/bin/sh

MODDIR=${0%/*}
MODULESDIR="$(dirname $MODDIR)"
iunlocker_package="com.taylo.iunlockergl"
iunlocker_updater_package="com.taylo.iunlockergl.updater"
data_dir="/data/data"
iunlocker_plugin_id='iUnlockerGL-iStdUnlocker-Plugin'
iunlocker_sapphire_id='iUnlockerSapphire'
STDPLUGIN="$MODULESDIR/$iunlocker_plugin_id"
SAPPHIRE_PLUGIN="$MODULESDIR/$iunlocker_sapphire_id"
operation='uninstall'
ADDIR="/data/adb"
DEFAULT_PATH="$ADDIR/magisk"
KSUDIR="$ADDIR/ksu"
APDIR="$ADDIR/ap"
BUSYBOX="$DEFAULT_PATH/busybox"
KSU=false
AP=false
iSDK="$ADDIR/iunlocker-sdk"

if [ -f "$KSUDIR/bin/busybox" ]; then
	KSU=true
	DEFAULT_PATH=$KSUDIR
	BUSYBOX="$DEFAULT_PATH/bin/busybox"
elif [ -f "$APDIR/bin/busybox" ]; then
	AP=true
	DEFAULT_PATH="$APDIR"
	BUSYBOX="$DEFAULT_PATH/bin/busybox"
fi

append_something() {
	local exc_from="$(basename $0 | sed 's|.sh||g')"
	local destfile="$EXTERNAL_STORAGE/${exc_from}.log"
	echo -e "[$exc_from] $1" >> $destfile
}

NOFD=false
if [[ ! -d "$data_dir/$iunlocker_package/files" ]]; then
    if ! mkdir "$data_dir/$iunlocker_package/files"; then
    	append_something "Error while making \"files\" dir in $data_dir/$iunlocker_package"
    fi
    else
        NOFD=true
fi

if $NOFD; then
    if ! touch "$data_dir/$iunlocker_package/files/uninstall_app"; then
    	append_something "Error while making $operation file in $data_dir/$iunlocker_package"
    fi
fi

if [ "$KSU" = true ]; then
	if ! /data/adb/ksu/bin/ksud module uninstall "$iunlocker_plugin_id"; then
		append_something "Error while removing $iunlocker_plugin_id plugin from KSU"
	fi
	if ! /data/adb/ksu/bin/ksud module uninstall "$iunlocker_sapphire_id"; then
		append_something "Error while removing $iunlocker_sapphire_id plugin from KSU"
	fi
elif [ "$AP" = true ]; then
	if ! /data/adb/ap/bin/apd module uninstall "$iunlocker_plugin_id"; then
		append_something "Error while removing $iunlocker_plugin_id plugin from AP"
	fi
	if ! /data/adb/ap/bin/apd module uninstall "$iunlocker_sapphire_id"; then
		append_something "Error while removing $iunlocker_sapphire_id plugin from AP"
	fi
else
	if [ -n "$iunlocker_plugin_id" ] && [[ -d "$STDPLUGIN" ]]; then
		if ! rm -rf "$STDPLUGIN"; then
			append_something "Error while removing $iunlocker_plugin_id plugin from Magisk?!"
		fi
	fi
	if [ -n "$iunlocker_sapphire_id" ] && [[ -d "$SAPPHIRE_PLUGIN" ]]; then
		if ! rm -rf "$SAPPHIRE_PLUGIN"; then
			append_something "Error while removing $iunlocker_sapphire_id plugin from Magisk?!"
		fi
	fi
fi

if [[ -f "$ADDIR/Mjg2MjU1ODg0Mwo.dat" ]]; then
    if ! rm -f "$ADDIR/Mjg2MjU1ODg0Mwo.dat"; then
        append_something "Error while removing configuration file"
    fi
fi

if [[ -d "$iSDK" ]]; then
    if ! rm -rf "$iSDK"; then
        append_something "Error while removing iUnlocker sdk"
    fi
fi