#!/bin/bash

# ====== CONFIGURATION ======
APP_NAME="devops_app"
BASE_DIR="/home/$(whoami)/deployments"
LOG_DIR="$BASE_DIR/logs"
DEPLOY_LOG="$LOG_DIR/deploy_$(date '%Y%m%d').log"
ENVIRONMENTS=("development" "staging" "production")
VERSION_FILE="$BASE_DIR/version.txt"

# === SETUP ===
setup() {
	mkdir -p $BASE_DIR
	mkdir -p $LOG_DIR
	for env in ${ENVIRONMENTS[@]}; do
		mkdir -p "$BASE_DIR/$env"
	done
	if [ ! -f $VERSION_FILE ];then
		echo "1.0.0" > $VERSION_FILE
	fi
}

# ===== LOGGING =====
log() {
	local type=$1
	local message=$2
	echo "[$type] $(date  '+%H:%M:%S') - $message" | tee -a $DEPLOY_LOG
}

# ===== VERSION MANAGEMENT =====
get_version() {
	cat $VERSION_FILE
}

bump_version() {
	local current=$(get_version)
	local major=$(echo $current | cut -d, -f1)
	local minor=$(echo $current | cut -d, -f2)
	local patch=$(echo $current | cut -d, -f3)

	case $1 in
		major)
			major=$((major + 1))
			minor=0
			patch=0
			;;
		minor)
			minor=$((minor + 1))
			patch=0
			;;
		patch)
			patch=$((patch + 1))
			;;
		*)
			log "ERROR" "Invalid bump type: $1"
			return 1
			;;
	esac

	local new_version="$major.$minor.$patch"
	echo $new_version > $VERSION_FILE
	log "INFO" "Version bumped to new_version"
}

# ===== DEPLOYMENT FUNCTIONS =====
validate_environment() {
	local env=$1
	for valid_env in ${ENVIRONMENTS[@]}; do
		if [ "env" == "$valid_env" ]; then
			return 0
		fi
	done
	return 1
}

pre_deploy_checks() {
	local env=$1
	log "INFO" "Running pre-deployment checks for $env"

	if [ ! "$env" ]; then
		log "ERROR" "Invalid environment $env"
		return 1
	fi

	if [ ! -d "$BASE_DIR/$env" ]; then
		log "ERROR" "Environment directory missing $env"
		return 1
	fi

	log "OK" "Pre-deployment checks passed for $env"
	return 0
}

deploy() {
	local env=$1
	local version=$(get_version)

	log "INFO" "======================================"
	log "INFO" "Deploying $APP_NAME $version to $env"
	log "INFO" "======================================"

	pre_deploy_checks $env
	if [ $? -ne 0 ]; then
		log "ERROR" "Pre-deployment checks failed - aborting"
		return 1
	fi

	log "INFO" "Step 1: Creating deployment package..."
	local deploy_package="$BASE_DIR/$env/${APP_NAME}_${version}_$(date '+%Y%m%d%H%M%S')"
	mkdir -p $deploy_package
	sleep 1

	log "INFO" "Step 2: Running tests..."
	sleep 1
	local test_result=$((RANDOM % 5))

	if [ $test_result -eq 0 ] && [ "$env" != "development" ]; then
		log "ERROR" "Tests failed for $env development"
		rm -rf "$deploy_package"
		return 1
	fi

	log "OK" "Tests passed"

	log "INFO" "Step 3: Deploying to $env..."
	echo "APP_NAME=$APP_NAME" > "$deploy_package/config.env"
	echo "VERSION=$version" >> "$deploy_package/config.env"
	echo "ENVIRONMENT=$env" >> "$deploy_package/config.env"
	echo "DEPLOYED_AT=$(date)" >> "$deploy_package/config.env"
	echo "DEPLOYED_BY=$(whoami)" >> "$deploy_package/config.env"
	sleep 1

	log "OK" "Deployment package created: $(basename $deploy_package)"

	log "INFO" "Step 4: Post-deployment verification..."
	if [ -f "$deploy_package/config.env" ]; then
		log "OK" "Deployment verified successfully"
	else
		log "ERROR" "Deployment verification failed"
		return 1
	fi

	log "OK" "===== DEPLOYMENT COMPLETE ====="
	log "INFO" "$APP_NAME v$version successfully deployed to $env"
	return 0
}

rollback() {
	local env=$1
	log "INFO" "Initiating rollback for $env..."

	local deployments=($(ls -t $BASE_DIR/$env/ 2>/dev/null))

	if [ ${#deployments[@]} -lt 2 ]; then
		log "ERROR" "No previous deployment found to rollback to"
		return 1
	fi


	local current=${deployments[0]}
	local previous=${deployments[1]}

	log "INFO" "Rolling back from $(basename $current) to $(basename $previous)"
	rm -rf "$BASE_DIR/$env/$current"
	log "OK" "Rollback complete - now running: $(basename $previous)"
}

show_deployments() {
	local env=$1
	log "INFO" "===== DEPLOYMENTS IN $env ====="

	if [ ! -d "$BASE_DIR/$env" ]; then
		log "ERROR" "Environment not found: $env"
		return 1
	fi


	local count=0
	for deployment in $(ls -t $BASE_DIR/$env/ 2>/dev/null); do
		count=$((count + 1))
		local config="$BASE_DIR/$env/$deployment/config.env"
		if [ -f $config ]; then
			local ver=$(grep VERSION $config | cut -d= -f2)
			local deployed_at=$(grep DEPLOYED_AT $config | cut -d= -f2)
			log "INFO" "[$count] $deployment - v$ver - $deployed_at"
		fi
	done

	if [ $count -eq 0 ]; then
		log "INFO" "No deployments found in $env"
	fi
}

# ==== MAIN MENU ====
setup

while true; do
	echo " "
	echo "=========================================="
	echo "       $APP_NAME DEPLOYMENT MANAGER      "
	echo "=========================================="
	echo "Current Version: $(get_version)"
	echo " "
	echo "1. Deploy to Development"
	echo "2. Deploy to staging"
	echo "3. Deploy to production"
	echo "4. Rollback Deployment"
	echo "5. View Deployments"
	echo "6. Bump Version (patch)"
	echo "7. Bump Version (minor)"
	echo "8. Bump Version (major)"
	echo "9. View Deploy log"
	echo "10. Exit"
	echo "========================================="

	read -p "Enter choice: " choice

	case $choice in
		1)
			deploy "development"
			;;
		2)
			deploy "staging"
			;;
		3)
			echo " "
			read -p "Deploying to PRODUCTION. Type CONFIRM: " confirm
			case $confirm in
				CONFIRM)
					deploy "production"
					;;
				*)
					echo "Production deployment cancelled"
					;;
			esac
			;;
		4)
			echo "Select environment to rollback:"
			echo "1. development 2. staging 3. production"
			read -p "Choice: " env_choice
			case $env_choice in
				1) rollback "development" ;;
				2) rollback "staging" ;;
				3) rollback "production" ;;
				*) echo "Invalid choice" ;;
			esac
			;;
		5)
			echo "Select environment to view:"
			echo "1. development 2. staging 3. production"
			read -p "Choice: " env_choice
			case $env_choice in
				1) show_deployments "deployment" ;;
				2) show_deployments "staging" ;;
				3) show_deployments "production" ;;
				*)echo "Invalid choice" ;;
			esac
			;;
		6) bump_version "patch" ;;
		7) bump_version "minor" ;;
		8) bump_version "major" ;;
		9)
			if [ -f $DEPLOY_LOG ]; then
				cat $DEPLOY_LOG
			else
				echo "No log found"
			fi
			;;
		10)
			log "INFO" "Deployment manager exited by $(whoami)"
			echo "Goodbye!"
			exit 0
			;;
		*)
			echo "Invalid choice"
			;;
	esac
done
