#!/bin/bash

#Author: Faruk
#Description: use functions script

# Load the functions library
source ~/scripts/exercises/functions_lib.sh

echo "==== SYSTEM HEALTH CHECK ===="
echo " "

# Use logging functions
log_info "Starting system health check"

# Check disk space with 80% threshold
check_disk_space 80

# Check memory
memory_percent=$(check_memory)
	if [ $memory_percent -ge 80 ]; then
		log_warning "Memory usage is high: ${memory_percent}%"
	else
		log_success "Memory usage is normal: ${memory_percent}%"
	fi

# Get uptime
log_info "System uptime: $(get_uptime)"

echo " "
echo "==== USER OPERATIONS ===="

# Create a test user using our function
create_user "testuser1" "no"
create_user "testuser2" "yes"

echo " "
echo "==== FILE OPERATIONS ===="

# Create a file using our function
create_file_with_content "/home/$(whoami)/testfile.txt" "This was created by our function"

# Backup the file
backup_file "/home/$(whoami)/testfile.txt"

echo " "
log_success "Health Check Complete!"
