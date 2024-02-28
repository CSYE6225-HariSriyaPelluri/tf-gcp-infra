#!/bin/bash

# content to overwrite .env file

SCRIPT_CONTENT="
"HOST=${hostname}"
"USER_NAME=${username}"
"PASSWORD=${password}"
"DATABASE=${db}"
"PORT=${port}"
"

echo "$SCRIPT_CONTENT" | sudo tee /home/csye6225/webapp/webapp_develop/.env > /dev/null
