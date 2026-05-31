#!/bin/bash

# Author: Faruk
# Description: Health monitor report
# Date: Did this 31th of may,2026. 10:32:45

LOG_FILE="/home/$(whoami)/health_monitor.log"
CHECK_INTERVAL=10
DISK_THRESHOLD=80
MEMORY_THRESHOLD=80


log() {
	echo "$(date '+%Y-%m-%d_%H:%M:%S') - $1" | tee -a $LOG_FILE
}

check_disk() {
	local usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
	if [ $usage -gt "$DISK_THRESHOLD" ]; then
		log "WARNING: Disk usage critical - ${usage}%"
	else
		log "OK: Disk usage normal - ${usage}%"
	fi
}

check_memory() {
	local total=$(free | grep Mem | awk '{print $2}')
	local used=$(free | grep Mem | awk '{print $3}')
	local percent=$((used * 100 / total))

	if [ $percent -ge $MEMORY_THRESHOLD ]; then
		log "WARNING: Memory usage critical - ${percent}%"
	else
		log "OK: Memory usage normal - ${percent}%"
	fi
}

check_cpu() {
	local load=$(uptime | awk '{print $10}' | tr -d ',')
	log "INFO: CPU load average - ${load}"
}

check_users() {
	local user_count=$(who | wc -l)
	log "INFO: Logged in users - ${user_count}"
}

run_monitor() {
	local rounds=$1
	local count=0

	while [ $count -lt $rounds ]; do
		count=$((count + 1))
		echo " "
		log "====== HEALTH CHECK #$count ======"
		check_disk
		check_memory
		check_cpu
		check_users

		if [ $count -lt $rounds ]; then
			log "Next check in ${CHECK_INTERVAL} seconds..."
			sleep $CHECK_INTERVAL
		fi
	done

	log "===== MONITORING COMPLETE ====="
}

echo "====== SERVER HEALTH MONITOR ======"
echo "1. Run 3 health checks"
echo "2. Run 5 health checks"
echo "3. Run single health check"
echo "4. View health log"
echo "==================================="

read -p "Enter choice: " option

case $option in
	1)
		log "Starting monitoring - 3 rounds"
		run_monitor 3
		;;
	2)
		log "Starting monitoring - 5 rounds"
		run_monitor 5
		;;
	3)
		log "Running single health check"
		run_monitor 1
		;;
	4)
		if [ -f "$LOG_FILE" ]; then
			tail -50 $LOG_FILE
		else
			echo "No log file found yet"
		fi
		;;
	*)
		echo "Invalid option"
		;;
esac
