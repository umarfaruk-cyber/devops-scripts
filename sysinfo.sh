#!/bin/bash
hostname=$(hostname)
current_user=$(whoami)
current_date=$(date)
os_version=$(uname -a)
uptime_info=$(uptime -p)
disk_usage=$(df -h / |tail -1 | awk '{print $5}')
memory_total=$(free -h | grep Mem | awk '{print $2}')
memory_used=$(free -h | grep Mem | awk '{print $3}')
ip_address=$(hostname -I | awk '{print $1}')
cpu_cores=$(nproc)


echo "============================"
echo "SYSTEM INFORMATION REPORT"
echo "============================" 
echo "Hostname: $hostname"
echo "Current User: $current_user"
echo "Date & Time: $current_date"
echo "OS Version: $os_version"
echo "Uptime: $uptime_info"
echo "Disk Usage: $disk_usage"
echo "Memory Total: $memory_total"
echo "Memory Used: $memory_used"
echo "IP Address: $ip_address"
echo "CPU Cores: $cpu_cores"
echo "============================"
