#!/bin/bash

# Setup Docker Secrets for Production
# This script helps you generate secure passwords for production deployment

set -e

SECRETS_DIR="./secrets"
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}Docker Secrets Setup for Production${NC}"
echo -e "${GREEN}====================================${NC}\n"

# Check if secrets directory exists
if [ ! -d "$SECRETS_DIR" ]; then
    echo -e "${RED}Error: secrets directory not found!${NC}"
    exit 1
fi

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d '\n'
}

# Function to prompt for value or generate
prompt_or_generate() {
    local prompt_text="$1"
    local secret_file="$2"
    local can_generate="$3"

    if [ -f "$secret_file" ]; then
        echo -e "${YELLOW}File $secret_file already exists.${NC}"
        read -p "Overwrite? (y/N): " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            echo "Skipping $secret_file"
            return
        fi
    fi

    if [ "$can_generate" = "yes" ]; then
        echo -e "\n${GREEN}$prompt_text${NC}"
        echo "1) Generate secure random password (recommended)"
        echo "2) Enter password manually"
        read -p "Choose option (1/2): " choice

        case $choice in
            1)
                password=$(generate_password)
                echo "$password" > "$secret_file"
                echo -e "${GREEN}✓ Generated and saved to $secret_file${NC}"
                ;;
            2)
                read -sp "Enter password: " password
                echo
                echo "$password" > "$secret_file"
                echo -e "${GREEN}✓ Saved to $secret_file${NC}"
                ;;
            *)
                echo -e "${RED}Invalid choice. Skipping.${NC}"
                return
                ;;
        esac
    else
        echo -e "\n${GREEN}$prompt_text${NC}"
        read -p "Enter value: " value
        echo "$value" > "$secret_file"
        echo -e "${GREEN}✓ Saved to $secret_file${NC}"
    fi

    # Set secure permissions
    chmod 600 "$secret_file"
}

echo -e "${YELLOW}This script will help you set up Docker secrets for production.${NC}\n"

# Setup MySQL User
prompt_or_generate \
    "MySQL Username (for application)" \
    "$SECRETS_DIR/mysql_user.txt" \
    "no"

# Setup MySQL Password
prompt_or_generate \
    "MySQL User Password (for application)" \
    "$SECRETS_DIR/mysql_password.txt" \
    "yes"

# Setup MySQL Root Password
prompt_or_generate \
    "MySQL Root Password" \
    "$SECRETS_DIR/mysql_root_password.txt" \
    "yes"

echo -e "\n${GREEN}====================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}====================================${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the generated secret files in $SECRETS_DIR/"
echo "2. Deploy to production:"
echo -e "   ${GREEN}docker compose -f compose.prod.yaml up -d${NC}"
echo ""
echo -e "${YELLOW}Security reminders:${NC}"
echo "• Keep these files secure and never commit them to git"
echo "• Backup passwords in a secure password manager"
echo "• Consider rotating passwords regularly (every 90 days)"
echo ""
echo -e "${GREEN}For more information, see PRODUCTION.md${NC}"
