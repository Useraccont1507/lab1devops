#!/bin/bash

PROJECT_NAME="lab1devops"
PROJECT_DIR="/home/creator/lab1devops"
DB_HOST="127.0.0.1"
DB_NAME="inventory_db"
DB_USER="inventory_user"
DB_PASS="1111"
NGINX_LISTEN_PORT=80
NGINX_PORT=8000

echo "🔄 Install dependencies"
sudo apt-get update
sudo apt-get install -y \
  binutils git unzip gnupg2 libc6-dev libcurl4-openssl-dev \
  libedit2 libgcc-13-dev libpython3-dev libsqlite3-dev \
  libstdc++-13-dev libxml2-dev libz3-dev pkg-config \
  tzdata zlib1g-dev libncurses6 nginx mariadb-server

echo "🔄 Install Swift"
if [ ! -d "/opt/swift" ]; then
    cd /tmp
    wget https://download.swift.org/swift-6.0.1-release/ubuntu2404-aarch64/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-ubuntu24.04-aarch64.tar.gz
    tar -xzf swift-6.0.1-RELEASE-ubuntu24.04-aarch64.tar.gz
    sudo mv swift-6.0.1-RELEASE-ubuntu24.04-aarch64 /opt/swift
    echo 'export PATH=/opt/swift/usr/bin:$PATH' | sudo tee /etc/profile.d/swift.sh
    source /etc/profile.d/swift.sh
else
    echo "✅ Swift has already installed in /opt/swift"
fi

echo "🔄 Setup MariaDB"
sudo systemctl enable --now mariadb
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON ${DB_USER}.* TO '${DB_USER}'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

echo "🔄 Creating users"
for u in student teacher operator app; do
    if ! id "$u" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$u"
        echo "$u:1111" | sudo chpasswd
    fi
done

echo "🔄 Building project and migrations"
cd $PROJECT_DIR

/opt/swift/usr/bin/swift build -c release
sudo cp .build/release/$PROJECT_NAME /usr/local/bin/

DB_HOST=${DB_HOST} DB_USER=${DB_USER} DB_PASSWORD=${DB_PASS} DB_NAME=${DB_NAME} /usr/local/bin/$PROJECT_NAME migrate --yes

echo "🔄 Setup Systemd (Socket Activation)"
cat <<EOF | sudo tee /etc/systemd/system/$PROJECT_NAME.socket
[Socket]
ListenStream=NGINX_PORT

[Install]
WantedBy=sockets.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/$PROJECT_NAME.service
[Unit]
Description=Vapor Inventory App
Requires=$PROJECT_NAME.socket

[Service]
User=app
Environment="LD_LIBRARY_PATH=/opt/swift/usr/lib"

Environment="DB_HOST=${DB_HOST}"
Environment="DB_USER=${DB_USER}"
Environment="DB_PASSWORD=${DB_PASS}"
Environment="DB_NAME=${DB_NAME}"

ExecStart=/usr/local/bin/$PROJECT_NAME serve --hostname ${DB_HOST} --port ${NGINX_PORT}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Setup rights for operator"
echo "operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart $PROJECT_NAME.service, /usr/bin/systemctl stop $PROJECT_NAME.service, /usr/bin/systemctl start $PROJECT_NAME.service" | sudo tee /etc/sudoers.d/operator
sudo chmod 0440 /etc/sudoers.d/operator

echo "🔄 Setup Nginx"
cat <<EOF | sudo tee /etc/nginx/sites-available/$PROJECT_NAME
server {
    listen ${NGINX_LISTEN_PORT};
    
    location / {
        proxy_pass http://${DB_HOST}:${NGINX_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Accept \$http_accept;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "🔄 Launching services and Gradebook"
sudo systemctl daemon-reload
sudo systemctl enable --now $PROJECT_NAME.socket

echo "8" | sudo tee /home/student/gradebook

echo "✅ Complete: http://192.168.64.9"
