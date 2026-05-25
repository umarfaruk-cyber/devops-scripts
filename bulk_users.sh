#!/bin/bash

# Arrays of users to create
users=("alice" "bob" "charlie" "diana" "eve")

# Arrays of admin users
admins=("alice" "diana")

echo "===== BULK USER CREATION ====="
echo "Users to create ${#users[@]}"
echo " "

# Loop through and create each user
for user in ${users[@]}; do
	# check if user already exist
	if id "$user" &>/dev/null; then
		echo "SKIP: User $user already exists"
	else
		# Create the user
		sudo adduser --disabled-password --gecos "" $user
		echo "CREATED: User $user"
	fi
done

echo " "
echo "==== ASSIGNING ADMIN ROLE ===="

# Loop through admin array and grant sudo
for admin in ${admins[@]}; do
	sudo usermod -aG sudo $admin
	echo "ADMIN: $admin granted sudo access"
done

echo " "
echo "==== VERIFICATION ===="

# Verify all users were created

for user in ${users[@]}; do
	if id "$user" &>/dev/null; then
		echo "OK: $user exists"
	else
		echo "FAILED: $user was not created"
	fi
done

echo " "
echo "Bulk user creation complete!"
