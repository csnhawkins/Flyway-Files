#!/bin/bash

echo "Flyway CLI - Validate and Clean"
# Flyway CLI - Project Settings # 
TARGET_ENVIRONMENT="Build"
TARGET_DATABASE_JDBC="jdbc:sqlserver://localhost;databaseName=Westwind_Build;encrypt=true;integratedSecurity=false;trustServerCertificate=true"
TARGET_DATABASE_USERNAME="sa"
TARGET_DATABASE_PASSWORD="Redg@te1"
FLYWAY_LICENSE_KEY=""
FLYWAY_PROJECT_LOCATION="/mnt/c/Redgate/GIT/Repos/GitHub/AutoPilot-Development/Flyway-AutoPilot-FastTrack_Forked"

# Optional - Flyway Pipeline #
FLYWAY_PUBLISH_RESULT="false"
FLYWAY_EMAIL=""
FLYWAY_TOKEN=""

flyway validate \
-environment="$TARGET_ENVIRONMENT" \
-url="$TARGET_DATABASE_JDBC" \
-user="$TARGET_DATABASE_USERNAME" \
-password="$TARGET_DATABASE_PASSWORD" \
-configFiles="$FLYWAY_PROJECT_LOCATION/flyway.toml" \
-locations="filesystem:$FLYWAY_PROJECT_LOCATION/migrations" \
-ignoreMigrationPatterns="*:pending" \
-email="$FLYWAY_EMAIL" \
-token="$FLYWAY_TOKEN"
if [ $? -ne 0 ]; then
flyway clean \
-environment="$TARGET_ENVIRONMENT" \
-url="$TARGET_DATABASE_JDBC" \
-user="$TARGET_DATABASE_USERNAME" \
-password="$TARGET_DATABASE_PASSWORD" \
-configFiles="$FLYWAY_PROJECT_LOCATION/flyway.toml" \
-locations="filesystem:$FLYWAY_PROJECT_LOCATION/migrations" \
-cleanDisabled="false" \
-email="$FLYWAY_EMAIL" \
-token="$FLYWAY_TOKEN"
fi