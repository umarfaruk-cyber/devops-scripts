#!/bin/bash

# ===== CONFIGURATION =====
REPORT_DIR=/home/$(whoami)/reports
REPORT_FILE=$REPORT_DIR/audit_$(date '+%Y-%m-%d')
ALERT_THRESHOLD_DISK=80
ALERT_THRESHOLD_MEM=75
ALERT_THRESHOLD_LOAD=2


# ===== LOGGING =====
log() {
	local level=$1
	local message=$2
	echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $REPORT_FILE
}

# ==== SETUP ====
setup() {
	mkdir -p $REPORT_DIR
	echo " " > $REPORT_FILE
	log "INFO" "Audit started by $(whoami)"
}

# ==== FUNCTIONS ====

check_os_info() {
	log "INFO" "===== OS INFORMATION ====="
	local os=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)
	local kernel=$(uname -r)
	local hostname=$(hostname)
	local uptime=(uptime -p)

	log "INFO" "OS: $os"
	log "INFO" "Kernel: $kernel"
	log "INFO" "Hostname: $hostname"
	log "INFO" "Uptime: $uptime"
}

check_cpu() {
	log "INFO" "====== CPU INFORMATION ======"
	local cores=$(nproc)
	local load=$(uptime | awk '{print $10}' | tr -d ',')

	log "INFO" "CPU Cores: $cores"
	log "INFO" "Load Average: $load"

	if (( $(echo "$load > $ALERT_THRESHOLD_LOAD" | bc -l) )); then
		log "ALERT" "CPU load is high: $load"
	else
		log "OK" "CPU load is normal: $load"
	fi
}

check_disk() {
	log "INFO" "===== DISK USAGE ====="
	while read line; do
		local usage=$(echo $line | awk '{print $5}' | tr -d '%')
		local mount=$(echo $line | awk '{print $6}')

		if [ $usage -gt $ALERT_THRESHOLD_DISK ]; then
			log "ALERT" "Disk usage critical on $mount: ${usage}%"
		else
			log "OK" "Disk usage normal on $mount: ${usage}%"
		fi
	done < <(df -h | tail -n +2)
}

check_memory() {
	log "INFO" "====== MEMORY USAGE ======"
	local total=$(free | grep Mem | awk '{print $2}')
	local used=$(free | grep Mem | awk '{print $3}')
	local percent=$((used * 100 / total))
	local free_mem=$(free -h | grep Mem | awk '{print $4}')

	log "INFO" "Total Memory: $(free -h | grep Mem | awk '{print $2}')"
	log "INFO" "Used Memory: $(free -h | grep Mem | awk '{print $3}')"
	log "INFO" "Free Memory: $free_mem"
	log "INFO" "Used percentage: ${percent}%"

	if [ $percent -gt $ALERT_THRESHOLD_MEM ]; then
		log "ALERT" "Memory usage is high: ${percent}%"
	else
		log "OK" "Memory usage normal: ${percent}%"
	fi
}

check_users() {
	log "INFO" "====== USER AUDIT ======"
	local total_users=$(cat /etc/passwd | grep "/bin/bash" | wc -l)
	local logged_in=$(who | wc -l)
	local sudo_users=$(grep -c "sudo" /etc/group)

	log "INFO" "Total bash users: $total_users"
	log "INFO" "Currently logged in: $logged_in"
	log "INFO" "Sudo group members: $sudo_users"

	log "INFO" "--- Sudo Users List ---"
	for user in $(grep "sudo" /etc/group | cut -d: -f4 | tr "," " "); do
		log "INFO" "Admin user: $user"
	done
}

check_services() {
	log "INFO" "===== SERVICE STATUS ====="
	local services=("ssh" "cron" "ufw")

	for service in ${services[@]}; do
		if systemctl is-active --quiet $service; then
			log "OK" "Service running: $service"
		else
			log "ALERT" "Service is not running: $service"
		fi
	done
}

check_network(){
	log "INFO" "====== NETWORK INFORMATION ======"
	local ip=$(hostname -I | awk '{print $1}')
	local gateway=$(ip route | grep default | awk '{print $3}')

	log "INFO" "IP Address: $ip"
	log "INFO" "Gateway: $gateway"

	if ping -c 1 8.8.8.8 &>/dev/null; then
		log "OK" "Internet connectivity confirmed"
	else
		log "ALERT" "No internet connectivity"
	fi
}

generate_summary() {
	log "INFO" "===== AUDIT SUMMARY ====="
	local alerts=$(grep -c "ALERT" $REPORT_FILE)
	local oks=$(grep -c "OK" $REPORT_FILE)

	log "INFO" "Total OK checks: $oks"
	log "INFO" "Total Alerts: $alerts"

	if [ $alerts -gt 0 ]; then
		log "WARN" "system has $alerts alert(s) requiring attention"
	else
		log "INFO" "all system healthy"
	fi

	log "INFO" "Full report saved: $REPORT_FILE"
}


# ==== MAIN ====

setup

echo "==============================="
echo "RUNNING FULL SYSTEM AUDIT"
echo "==============================="

check_os_info
check_cpu
check_disk
check_memory
check_users
check_services
check_network
generate_summary

echo " "
echo "Audit complete. Report saved to: $REPORT_FILE"
