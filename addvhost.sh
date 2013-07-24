#!/bin/bash
#
# Script adds new virtual host on local machine

# check arguments
if [ $# -lt 1 ]; then
    echo 'Not enough arguments. Insert name of the virtual host. For help type "--help"'
    exit
elif [ $1 = "--help" ]; then
    cat <<EOL
Script adds new virtual host on local machine. Requires sudo permissions. Usage:

    sudo ./addvhost -n vhost_name [-u user_name]
                   [-d vhost_public_dir] [-p project_dir]

Examples:

    sudo ./addvhost -n mysite

Creates vhost "mysite.root.local" in /var/www/mysite

    sudo ./addvhost -n mysite -u webdev -d public -p projects/php

This will create new vhost "mysite.user.local" in /home/webdev/projects/php/mysite with project root directory in /home/webdev/projects/php/mysite/public

EOL
    exit
fi

# define default vars
VHOST_ROOT="/etc/apache2/sites-available"
VHOST_NAME=
VHOST_DIR=
USER_NAME=$(whoami)
PROJECT_DIR=

# handle arguments
for (( i = 1, j = 2; i < $#; i++, j++ )); do
    KEY=${!i}
    VAL=${!j}
    case $KEY in
        -n)
            VHOST_NAME="$VAL"
            ;;
        -d)
            VHOST_DIR="$VAL"
            ;;
        -u)
            USER_NAME="$VAL"
            USER_HOME=$(getent passwd $USER_NAME | cut -d: -f6)
            ;;
        -p)
            PROJECT_DIR="$VAL"
            ;;
    esac
done

# define project path and vhost url
if [[ -z $PROJECT_DIR ]] || [[ "$USER_NAME" == "root" ]]; then
    PROJECT_PATH="/var/www/$VHOST_NAME"
else
    USER_HOME=$(getent passwd $USER_NAME | cut -d: -f6)
    PROJECT_PATH="$USER_HOME/$PROJECT_DIR/$VHOST_NAME"
fi
VHOST_URL="$VHOST_NAME.$USER_NAME.local"

# check required vars
if [[ -z "$VHOST_NAME" ]]; then
    echo "Host name not specified. Run ./addvhost --help for help."
    exit
fi

# check if vhost exists
if [[ -f "$VHOST_ROOT/$VHOST_NAME" ]]; then
    echo "Virtual host $VHOST_NAME already exists."
    exit
fi

# create vhost config
touch "$VHOST_ROOT/$VHOST_NAME"
cat > "$VHOST_ROOT/$VHOST_NAME" <<EOL
<VirtualHost *:80>
    ServerAdmin $USER_NAME@$VHOST_URL
    ServerName $VHOST_URL

    DocumentRoot $PROJECT_PATH/$VHOST_DIR
    <Directory $PROJECT_PATH/$VHOST_DIR/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$VHOST_NAME-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel notice

    CustomLog \${APACHE_LOG_DIR}/$VHOST_NAME-access.log combined

</VirtualHost>
EOL
echo "Configuration file $VHOST_ROOT/$VHOST_NAME created."

# enable new vhost
a2ensite "$VHOST_NAME"
service apache2 reload
echo "Virtual host $VHOST_URL enabled. Apache was reloaded in order changes to take effect."

# append new vhost address to hosts file
cat >> "/etc/hosts" <<EOL
127.0.0.1	$VHOST_URL
EOL

# create folder for new vhost
if [[ ! -d $PROJECT_PATH ]]; then
	mkdir -p $PROJECT_PATH
	chown -R $USER_NAME:$USER_NAME $PROJECT_PATH
	echo "Project folder $PROJECT_PATH created."
fi