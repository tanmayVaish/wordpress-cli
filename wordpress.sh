#!/bin/bash


# if $2 is not valid, then exit
if [ ! -z "$2" ] && [ "$2" != "start" ] && [ "$2" != "stop" ] && [ "$2" != "delete" ]; then
    echo "Invalid subcommand. Valid subcommands are: start, stop, delete."
    exit 1
fi

# Check if docker is installed

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "Docker has been installed."
else
    echo "Docker is already installed."
fi

# Check if docker compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose has been installed."
else
    echo "Docker Compose is already installed."
fi

echo "=================================================="

# check if site name is provided as command-line argument
if [ -z "$1" ]; then
    echo "Site name not provided. Please provide the site name as a command-line argument."
    exit 1
fi

site_name=$1

# Check if sitename already exists in /etc/hosts file
if grep -q "$site_name" "/etc/hosts"; then
    echo "The entry for $site_name already exists in /etc/hosts."
else
    # Create a /etc/hosts entry for the site name
    sh -c "echo '127.0.0.1 $site_name' >> /etc/hosts"
    # if above command fails, echo error and exit
    if [ $? -ne 0 ]; then
        echo "Failed to add the entry for $site_name to /etc/hosts. Try sudo"
        exit 1
    fi
    echo "The entry for $site_name has been added to /etc/hosts."
fi

# Create a directory for the WordPress site
mkdir -p $site_name


# Check if docker-compose.yml file exists
if [ ! -f "$site_name/docker-compose.yml" ]; then
    # Create a docker-compose.yml file
    cat << EOF > $site_name/docker-compose.yml
    version: '3'
    services:
      db:
        image: mysql:5.7
        volumes:
          - ./db_data:/var/lib/mysql
        restart: always
        environment:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: wordpress
          MYSQL_USER: wordpress
          MYSQL_PASSWORD: wordpress
    
      wordpress:
        depends_on:
          - db
        image: wordpress:latest
        volumes:
          - ./wordpress:/var/www/html
        restart: always
        environment:
          WORDPRESS_DB_HOST: db:3306
          WORDPRESS_DB_USER: wordpress
          WORDPRESS_DB_PASSWORD: wordpress
    
      nginx:
        image: nginx:latest
        ports:
          - "80:80"
        volumes:
          - ./nginx:/etc/nginx/conf.d
          - ./wordpress:/var/www/html
        restart: always
EOF

    echo "docker-compose.yml file created."
elif [ -f "$site_name/docker-compose.yml" ]; then
    echo "docker-compose.yml file already exists."
else
    echo "Failed to create docker-compose.yml file. Try sudo!"
    exit 1
fi

# Creating Nginx configuration
nginx_conf_file="$site_name/nginx/default.conf"
if [ ! -f "$nginx_conf_file" ]; then
    mkdir -p $site_name/nginx
    cat << EOF > $nginx_conf_file
    server {
        listen 80;
        server_name $site_name;

        location / {
            proxy_pass http://wordpress;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
EOF

    echo "Nginx configuration file created."
elif [ -f "$nginx_conf_file" ]; then
    echo "Nginx configuration file already exists."
else
    echo "Failed to create Nginx configuration. Try sudo!"
    exit 1
fi

echo "=================================================="

# Function to start containers
start_containers() {
    cd $site_name
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "=================================================="
        echo "WordPress site '$site_name' has been created and is accessible at http://$site_name"
    else
        echo "Failed to create the WordPress site."
    fi
}

# Function to stop the containers
stop_containers() {
    cd $site_name

    docker-compose down
    if [ $? -eq 0 ]; then
        echo "WordPress site '$site_name' has been stopped."

        # Remove entry from /etc/hosts
        sed -i "/$site_name/d" /etc/hosts
        echo "Removed entry for $site_name from /etc/hosts."
    else
        echo "Failed to stop the WordPress site."
    fi
}

# Function to delete site
delete_site() {
    stop_containers
    cd ..
    docker-compose rm -f
    rm -rf $site_name
    echo "WordPress site '$site_name' has been deleted."
}

# Check the subcommand
if [ -z "$2" ]; then
    start_containers
else
    subcommand=$2
    case $subcommand in
        "start")
            start_containers
            ;;
        "stop")
            stop_containers
            ;;
        "delete")
            delete_site
            ;;
        *)
            echo "Invalid subcommand. Valid subcommands are: start, stop, delete."
            exit 1
            ;;
    esac
fi
