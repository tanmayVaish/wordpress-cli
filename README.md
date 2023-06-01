# WordPress Setup Script
This script automates the setup of a WordPress development environment using Docker and Docker Compose. It sets up a local WordPress site with a MySQL database and an Nginx web server (LEMP Stack)

## Prerequisites
Docker: Make sure Docker is installed on your system. If not, the script will attempt to install Docker for you.
Docker Compose: Make sure Docker Compose is installed on your system. If not, the script will attempt to install Docker Compose for you.

## Usage

1. Clone this repository or download the script file.

2. Open a terminal and navigate to the directory where the script is located.

3. Make the script executable, if necessary:

    ```
    chmod +x wordpress.sh
    ```
4. Run the script with the following command:

    ```
    sudo ./wordpress.sh <site_name> [start|stop|delete]
    ```
    Replace <site_name> with the desired name for your WordPress site. The script will create a directory with the specified name to store the site files and configurations.

    Optionally, you can specify a subcommand [start|stop|delete] to start, stop, or delete the WordPress site. If no subcommand is provided, the script will start the containers by default.


    ### Example

    - Create and start a WordPress site:

        ```
        ./wordpress.sh mysite.com
        ```

    - Start an existing WordPress site:

        ```
        ./wordpress.sh mysite.com start
        ```

    - Stop a running WordPress site:

        ```
        ./wordpress.sh mysite.com stop
        ```

    - Delete a WordPress site:

        ```
        ./wordpress.sh mysite.com delete
        ```
5. Access your WordPress site:

    After running the script, the WordPress site will be accessible at 
    `http://<site_name>`. Replace `<site_name>` with the name you provided during setup.

