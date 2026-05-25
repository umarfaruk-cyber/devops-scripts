#!/bin/bash

# ===== LOGGING FUNCTIONS =====

log_info() {
	echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
	echo "[OK] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
	echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
	echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}


# ===== USER FUNCTIONS =====

user_exists() {
	if id "$1" &>/dev/null; then
		return 0
	else
		return 1
	fi
}

create_user() {
	local username=$1
	local make_admin=$2

	if user_exists $username; then
		log_warning "user $username already exists - skipping"
	else
		sudo adduser --disabled-password --gecos " " $username
		log_success "User $username created"
		if [ "make_admin" = "yes" ]; then
			sudo usermod -aG sudo $username
			log_success "User $username granted admin access"
		fi
	fi
}

delete_user() {
	local username=$1

	if user_exists $username; then
		sudo deluser --remove-home $username
		log_success "user $username deleted"
	else
		log_error "user $username does not exist"
	fi
}


# ==== FILE FUNCTIONS ====

file_exists() {
	if [ -f "$1" ]; then
		return 0
	else
		return 1
	fi
}

create_file_with_content() {
	local filepath=$1
	local content=$2

	echo "$content" > $filepath
	log_success "File created: $filepath"
}

backup_file() {
	local filepath=$1
	local backup_path="${filepath}.backup.$(date '%Y%m%d%H%M%S')"

	if file_exists $filepath; then
		cp $filepath $backup_path
		log_success "Backup created: $backup_path"
	else
		log_error "File not found: $filepath"
	fi
}


# ==== SYSTEM FUNCTIONS ====

check_disk_space() {
	local threshold=$1
	local usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

	if [ $usage -ge $threshold ]; then
		log_warning "Disk usage is ${usage}% - above threshold of ${threshold}%"
		return 1
	else
		log_info "Disk usage is ${usage}% - within acceptable range"
		return 0
	fi
}

check_memory() {
	local total=$(free | grep Mem | awk '{print $2}')
	local used=$(free | grep Mem | awk '{print $3}')
	local percentage=$((used * 100 / total))

	log_info "Memory usage: ${percentage}%"
	echo $percentage
}

get_uptime() {
	echo $(uptime -p)
}
