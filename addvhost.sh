#!/bin/bash
#
# Script adds new virtual host on local machine

# check arguments
if [[ $# -eq 0 ]]; then
	echo 'Not enough arguments. Insert name of the virtual host. For help type "--help"'
	exit
elif [[ $1 = '--help' ]]; then
	echo 'Script adds new virtual host on local machine. Usage: ./addvhost vhost_name (e.g. mysite). This will create new vhost "mysite.user.local"'
	exit
elif [[ -f "/etc/apache2/sites-available/$1" ]]; then
	echo "Virtual host $1 already exists"
	exit
fi

# define vars
VHOST_NAME="$1"
#USER_NAME="$(whoami)"
USER_NAME="mike"
PROJECT_DIR="/home/$USER_NAME/sites"

if [[ -z "$2" ]]; then
    VHOST_DIR="$VHOST_NAME"
else
    VHOST_DIR="$VHOST_NAME/$2"
fi

# create vhost config
touch "/etc/apache2/sites-available/$VHOST_NAME"
cat > "/etc/apache2/sites-available/$VHOST_NAME" <<EOL
<VirtualHost *:80>
    ServerAdmin $USER_NAME@$VHOST_NAME.$USER_NAME.local
    ServerName $VHOST_NAME.$USER_NAME.local

    DocumentRoot $PROJECT_DIR/$VHOST_DIR
    <Directory $PROJECT_DIR/$VHOST_DIR/>
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
echo "Configuration file /etc/apache2/sites-available/$VHOST_NAME created"

# enable new vhost
a2ensite $VHOST_NAME
service apache2 reload
echo "Virtual host $VHOST_NAME.$USER_NAME.local enabled. Apache was reloaded in order changes to take effect"

# append new vhost address to hosts file
cat >> "/etc/hosts" <<EOL
127.0.0.1	$VHOST_NAME.$USER_NAME.local
EOL

# create folder for new vhost
if [[ ! -d $PROJECT_DIR/$VHOST_NAME ]]; then
	mkdir $PROJECT_DIR/$VHOST_NAME
	chown $USER_NAME:$USER_NAME $PROJECT_DIR/$VHOST_NAME
	echo "Project folder $PROJECT_DIR/$VHOST_NAME created"
fi