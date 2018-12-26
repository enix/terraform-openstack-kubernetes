#!/bin/bash

CLOUD_INIT_BOOT_FINISHED=/var/lib/cloud/instance/boot-finished

while [ ! -s $CLOUD_INIT_BOOT_FINISHED ];
do
	echo "INFO: waiting for cloud-init boot process to finish"
	sleep 3 #might take a long time so the longer, the less verbose
done

echo "SUCCESS: cloud-init boot process finished"