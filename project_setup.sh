#!/bin/bash

read -p "Enter project name: " project_name
read -p "Enter environment (dev/staging/prod): " environment

#Define folder structure as array
folders=("src" "src/app" "src/config" "tests" "tests/unit" "tests/integration" "scripts" "scripts/deploy" "scripts/backup" "logs" "docs" ".github/workflows")

#Define file structure as array
files=("README.md" "src/app/main.sh" "src/config/settings.conf" "scripts/deploy/deploy.sh" "scripts/backup/backup.sh" ".github/workflows/ci.yml" "logs/app.log")

base_dir="/home/$(whoami)/projects/${project_name}"

echo " "
echo "==== Creating project: $project_name ===="
echo "Environment: $environment"
echo "Location: $base_dir"
echo " "

#check if project already exists
if [ -d "$base_dir" ]; then
	echo "WARNING: Project $project_name already exists"
	read -p "overwrite? (yes/no): " overwrite
	if [ "$overwrite" != "yes" ]; then
		echo "Aborted"
		exit 0
	else
		echo "Proceeding with overwrite..."
	fi
fi

#create all directories
echo "Creating directories...."
for folder in ${folders[@]}; do
	mkdir -p "$base_dir/$folder"
	echo " Created: $folder"
done

#create all files
echo " "
echo "Creating all files...."
for file in ${files[@]}; do
	touch "$base_dir/$file"
	echo "Created: $file"
done

#Add shebang line to shell scripts
for script in $(find $base_dir -name "*.sh"); do
	echo "#!/bin/bash" > $script
	echo "# Script: $script" >> $script
	echo "# Environment: $environment" >> $script
	echo "# Created: $(date)" >> $script
done

#Add environment info to settings
echo "PROJECT NAME=$project_name" > "$base_dir/src/config/settings.conf"
echo "ENVIRONMENT=$environment" >> "$base_dir/src/config/settings.conf"
echo "CREATED=$(date)" >> "$base_dir/src/config/settings.conf"

echo " "
echo "===== PROJECT STRUCTURE ====="
find $base_dir | sed "s|$base_dir/||"
echo " "
echo "Project $project_name setup complete!"
