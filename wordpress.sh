#!/bin/bash

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker has been installed."
else
    echo "Docker is already installed."
fi

# Check if docker compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose has been installed."
else
    echo "Docker Compose is already installed."
fi

# check if site name is provided as commandline argument
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
    sudo -- sh -c "echo '127.0.0.1 $site_name' >> /etc/hosts"
    echo "The entry for $site_name has been added to /etc/hosts."
fi

# Create a directory for the WordPress site
mkdir -p $site_name

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

# Creating Nginx configuration
mkdir -p $site_name/nginx
cat << EOF > $site_name/nginx/default.conf
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

# function to start containers
start_containers() {
    cd $site_name
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "WordPress site '$site_name' has been created and is accessible at http://$site_name"
    else
        echo "Failed to create the WordPress site."
    fi
}

# function to stop the containers
stop_containers() {
    cd $site_name

    docker-compose down
    if [ $? -eq 0 ]; then
        echo "WordPress site '$site_name' has been stopped."
        
        # Remove entry from /etc/hosts
        sudo sed -i "/$site_name/d" /etc/hosts
        echo "Removed entry for $site_name from /etc/hosts."
    else
        echo "Failed to stop the WordPress site."
    fi
}


# function to delete site
delete_site() {
    stop_containers
    cd ..
    docker-compose rm -f
    sudo rm -rf $site_name
    echo "WordPress site '$site_name' has been deleted."
}

# check the subcommand
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
