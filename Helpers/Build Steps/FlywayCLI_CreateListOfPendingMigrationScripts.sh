#!/bin/bash

echo "Flyway CLI - Validate Pending Scripts And Create List"
# Flyway CLI - Project Settings # 
TARGET_ENVIRONMENT="Build"
TARGET_DATABASE_JDBC="jdbc:sqlserver://localhost;databaseName=Westwind_Build;encrypt=true;integratedSecurity=false;trustServerCertificate=true"
TARGET_DATABASE_USERNAME="sa"
TARGET_DATABASE_PASSWORD="Redg@te1"
FLYWAY_LICENSE_KEY=""
FLYWAY_PROJECT_LOCATION="/mnt/c/Redgate/GIT/Repos/GitHub/AutoPilot-Development/Flyway-AutoPilot-FastTrack_Forked"
FLYWAY_FIRST_UNDO="002"

# Optional - Flyway Pipeline #
FLYWAY_PUBLISH_RESULT="false"
FLYWAY_EMAIL=""
FLYWAY_TOKEN=""

# Run the Flyway validate command and capture the output
pending_versions=$(flyway info -environment="$TARGET_ENVIRONMENT" -url="$TARGET_DATABASE_JDBC" -user="$TARGET_DATABASE_USERNAME" -password="$TARGET_DATABASE_PASSWORD" -configFiles="$FLYWAY_PROJECT_LOCATION/flyway.toml" -locations="filesystem:$FLYWAY_PROJECT_LOCATION/migrations" -email="$FLYWAY_EMAIL" -token="$FLYWAY_TOKEN" -infoOfState="Pending" -infoOfState="pending" -infoSinceVersion="$$FLYWAY_FIRST_UNDO" -migrationIds)

# Split the versions into a list, sort them in reverse numeric order, and join them into a comma-separated string
reversed_versions=$(echo "$pending_versions" | grep -oP '\d+' | sort -rV | paste -sd "," -)

# Set the variable with the comma-separated list of pending versions
echo "Pending versions: $pending_versions"
echo "Reversed Order List: $reversed_versions"

# Save the reversed list to the GitHub environment variable
#echo "FLYWAY_PENDING_MIGRATIONS=$reversed_versions" >> $GITHUB_ENV