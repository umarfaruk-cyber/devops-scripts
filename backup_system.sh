#!/bin/bash

# ==== CONFIGURATION ====#

BACKUP_DIR="/home/$(whoami)/backups"
SOURCE_DIR="/home/$(whoami)/projects"
LOG_FILE="/home/$(whoami)/backups/backup.log"
MAX_BACKUPS=5
DATE=$(date '+%Y-%m-%d_%H-%M-%S')


# ==== FUNCTIONS ====


setup_backup_dir() {
	if [ ! -d "$BACKUP_DIR" ]; then
		mkdir -p $BACKUP_DIR
		echo "Backup directory created: $BACKUP_DIR"
	fi
}

log_message() {
	local type=$1
	local message=$2
	echo "[$type] $(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOG_FILE
}

perform_backup() {
	local backup_name="backup_${DATE}.tar.gz"
	local backup_path="$BACKUP_DIR/$backup_name"

	log_message "INFO" "Starting backup of $SOURCE_DIR"

	if [ ! -d "$SOURCE_DIR" ]; then
		log_message "ERROR" "source directory does not exist: $SOURCE_DIR"
		return 1
	fi

# CREATE COMPRESSED BACKUP

	tar -czf $backup_path $SOURCE_DIR 2>/dev/null

	if [ $? -eq 0 ]; then
		local size=$(du -sh $backup_path | awk '{print $1}')
		log_message "SUCCESS" "Backup created: $backup_name (Size: $size)"
		return 0
	else
		log_message "ERROR" "Backup failed"
		return 1
	fi
}

cleanup_old_backups() {
	local backup_count=$(ls $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | wc -l)

	log_message "INFO" "Current backup count: $backup_count"

	if [ $backup_count -gt $MAX_BACKUPS ]; then
		local excess=$((backup_count - MAX_BACKUPS))
		log_message "INFO" "Removing $excess old backup(s)"

		ls -t $BACKUP_DIR/backup_*.tar.gz | tail -$excess | while read old_backup; do
			rm $old_backup
			log_message "INFO" "Removed old backup: $(basename $old_backup)"
		done
	fi
}

show_backup_history() {
	echo " "
	echo "==== Backup History ===="
	if ls $BACKUP_DIR/backup_*.tar.gz &>/dev/null; then
		for backup in $( ls -t $BACKUP_DIR/backup_*.tar.gz ); do
			local size=$(du -sh $backup | awk '{print $1}')
			echo " $(basename $backup) - $size"
		done
	else
		echo "No backups found"
	fi
	echo "======================"
}

# ==== MAIN MENU ====

echo "==== Automated Backup system ===="
echo "1. Run backup now"
echo "2. View backup history"
echo "3. Cleanup old backups"
echo "4. View backup logs"
echo "5. Exit"
echo "=================================="

read -p "Enter choice: " choice

setup_backup_dir

case $choice in
	1)
		perform_backup
		cleanup_old_backups
		show_backup_history
		;;
	2)
		show_backup_history
		;;
	3)
		cleanup_old_backups
		show_backup_history
		;;
	4)
		if [ -f "LOG_FILE" ]; then
			cat $LOG_FILE
		else
			echo "NO LOG FILE FOUND"
		fi
		;;
	5)
		echo "Goodbye!"
		exit 0
		;;
	*)
		echo "Invalid choice"
		;;
esac

