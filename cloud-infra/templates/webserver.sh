#!/bin/bash
set -e
set -x  # Show the comments in execution
# Update and install Apache
sudo apt-get update -y
sudo apt-get install -y apache2

# Enable and start Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Adjust UFW firewall to allow HTTP and HTTPS (optional)
if command -v ufw &> /dev/null
then
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
fi

sudo a2enmod ssl
sudo a2ensite default-ssl
sudo systemctl restart apache2
# Create a self-signed SSL certificate
#skip first
# Create a simple index.html page
echo "<html><body><h1>This is web server</h1></body></html>" | sudo tee /var/www/html/index.html
