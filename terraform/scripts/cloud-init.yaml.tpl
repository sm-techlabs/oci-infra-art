#cloud-config
package_update: true
package_upgrade: true

packages:
  - nodejs
  - npm
  - sqlite3
  - git
  - curl
  - apt-transport-https
  - gnupg2
  - ca-certificates

write_files:
  - path: /etc/systemd/system/budgeteer-backend.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Budgeteer Backend
      After=network.target

      [Service]
      ExecStart=/usr/bin/node /opt/budgeteer/backend/index.js
      WorkingDirectory=/opt/budgeteer/backend
      Restart=always
      User=www-data
      Group=www-data
      Environment=NODE_ENV=production
      Environment=PORT=3000
      Environment=JWT_SECRET=${jwt_secret}

      [Install]
      WantedBy=multi-user.target

  - path: /etc/caddy/Caddyfile
    permissions: '0644'
    content: |
      https://${frontend_subdomain}.${domain} {
          root * /opt/budgeteer/frontend
          file_server
      }

      https://${api_subdomain}.${domain} {
          reverse_proxy localhost:3000
      }

  - path: /opt/budgeteer/frontend/config.js
    permissions: '0644'
    content: |
      window.APP_CONFIG = {
        API_URL: 'https://${api_subdomain}.${domain}'
      };

runcmd:
  # Allow new incoming TCP connections on port 80 (HTTP)
  - iptables -I INPUT 5 -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
  # Allow new incoming TCP connections on port 443 (HTTPS)
  - iptables -I INPUT 6 -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

  # Install Caddy
  - curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  - curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/deb.debian.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
  - apt-get update
  - apt-get install -y -o Dpkg::Options::="--force-confold" caddy

  # Clone the specified branch (default: main)
  - git clone --depth 1 --branch ${git_branch} https://github.com/sammosios/budgeteer.git /opt/budgeteer

  # Set permissions (directories: 755, files: 644)
  - find /opt/budgeteer -type d -exec chmod 755 {} \;
  - find /opt/budgeteer -type f -exec chmod 644 {} \;
  - chown -R www-data:www-data /opt/budgeteer

  # Backend setup
  - cd /opt/budgeteer/backend
  - npm install --omit=dev

  # Enable and start backend service
  - systemctl daemon-reload
  - systemctl enable --now budgeteer-backend

  # Restart Caddy
  - systemctl restart caddy

final_message: "The system is now configured and ready to use."
