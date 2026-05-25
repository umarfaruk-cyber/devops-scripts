#!/bin/bash
echo "==== USER PROFILE CREATOR ===="
read -p "Enter your first name: " firstname
read -p "Enter your last name: " lastname
read -p "Enter your age: " age
read -p "Enter your role (developer/devops/sysadmin): " role
read -p "Enter years of experience: " experience

# String manipulation
full_name="$firstname $lastname"
upper_name=${full_name^^}
name_length=${#full_name}

# Numeric operations
next_age=$((age + 1))
birth_year=$((2026 - age))

# Conditional for seniority level
if [ $experience -ge 10 ]; then
	level="senior"
elif [ $experience -ge 5 ]; then
	level="Mid-level"
elif [ $experience -ge 1 ]; then
	level="junior"
else
	level="beginner"
fi

# Case for role description
case $role in
	developer)
		description="Writes and maintains application code"
		;;
	devops)
		description="Manages infrastructure and deployment pipelines"
		;;
	sysadmin)
		description="Manages and maintains computer systems"
		;;
	*)
		description="General IT professional"
		;;
esac

echo " "
echo "=========================================="
echo "         YOUR PROFILE SUMMARY          "
echo "=========================================="
echo "Full name: $upper_name"
echo "Name length: $name_length characters"
echo "Age: $age (turning $next_age this year)"
echo "Birth Year: $birth_year"
echo "Role: $role"
echo "Description: $description"
echo "Experience: $experience year"
echo "Level: $level"
echo "=========================================="
