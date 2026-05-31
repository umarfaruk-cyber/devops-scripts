#!/bin/bash

# Author: Faruk
# Description: deployment sript

# ==== CONFIG ====
APP_NAME="myapp"
DEPLOY_DIR="/home/$(whoami)/deployments"
LOG_FILE="$DEPLOY_DIR/deploy.log"
ENVIRONMENT=("develoment" "staging" "production")

#FUNCTIONS

log() {
	echo "$(date '+%H:%M:%S') - $1" | tee -a $LOG_FILE
}

setup() {
	mkdir -p $DEPLOY_DIR
}

run_tests() {
	log "[TEST] Running unit tests...."
	sleep 1
	log "[TEST] Running integration tests...."
	sleep 1
	log "[TEST] all tests passed"
	return 0
}

build_app() {
	log "[BUILD] Building application..."
	sleep 1
	log "[BUILD] Installing dependencies..."
	sleep 1
	log "[BUILD] Compiling assets..."
	sleep 1
	log "[BUILD] Build successful"
	return 0
}

deploy_to_env() {
	local env=$1
	log "[DEPLOY] Deploy $APP_NAME to $env..."
	sleep 1
	log "[DEPLOY] Coping files..."
	sleep 1
	log "[DEPLOY] Restarting services..."
	sleep 1
	log "[DEPLOY] Running health check..."
	sleep 1
	log "[DEPLOY] Deployment to $env successful"
	return 0
}

rollback() {
	local env=$1
	log "[ROLLBACK] Rolling back $APP_NAME in $env..."
	sleep 1
	log "[ROLLBACK] Restoring previous version..."
	sleep1
	log "[ROLLBACK] Rollback complete"
}

full_pipeline() {
	local env=$1


	log "=============================="
	log "STARTING PIPELINE FOR: $APP_NAME"
	log "Environment: $env"
	log "=============================="

	# Run tests
	run_tests
	if [ $? -ne 0 ]; then
		log "[FAILED] Tests failed, stopping pipeline"
		exit 1
	fi

	# Build
	build_app
	if [ $? -ne 0 ]; then
		log "[FAILED] Build failed - stopping pipeline"
		exit 1
	fi

	# Deploy
	deploy_to_env $env
	if [ $? -ne 0 ]; then
		log "[FAILED] Deployment failed - initiating rollback"
		rollback $env
		exit 1
	fi

	log "====================================="
	log "PIPELINE COMPLETE - $APP_NAME deployed"
	log "======================================"
}

# ==== MAIN MENU ====

setup

echo "===== DEPLOYMENT SYSTEM ===="
echo "Application: $APP_NAME"
echo " "
echo "1. Deploy to Development"
echo "2. Deploy to Staging"
echo "3. Deploy to Production"
echo "4. Run tests only"
echo "5. View deployment log"
echo "6. Exit"
echo "============================"

read -p "Enter choice: " choice

case $choice in
	1)
		full_pipeline "development"
		;;
	2)
		full_pipeline "staging"
		;;
	3)
		echo " "
		echo "WARNING: You are deploying to PRODUCTION"
		read -p "Type CONFIRM to proceed: " confirm
		if [ "$confirm" == "CONFIRM" ]; then
			full_pipeline "production"
		else
			echo "Production deployment cancelled"
		fi
		;;
	4)
		run_tests
		;;
	5)
		if [ -f "$LOG_FILE" ]; then
			cat $LOG_FILE
		else
			echo "No deployment log found"
		fi
		;;
	6)
		echo "Goodbye!"
		exit 0
		;;
	*)
		echo "Invalid choice"
		;;
esac
