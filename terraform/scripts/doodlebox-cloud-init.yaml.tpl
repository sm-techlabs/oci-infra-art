#cloud-config
package_update: true
package_upgrade: true

packages:
  - nodejs
  - npm
  - git
  - curl
  - apt-transport-https
  - gnupg2
  - ca-certificates

write_files:
  - path: /etc/systemd/system/doodlebox-backend.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Doodlebox Backend
      After=network.target

      [Service]
      ExecStart=/usr/bin/node /opt/doodlebox/backend/server.js
      WorkingDirectory=/opt/doodlebox/backend
      Restart=always
      User=www-data
      Group=www-data
      Environment=PORT=3000
      Environment=JWT_SECRET=${jwt_secret}
      Environment=APP_ID=1749361
      Environment=PRIVATE_KEY_PATH="/opt/keys/doodlebox-dispatcher.private-key.pem"
      Environment=INSTALLATION_ID=79896278
      Environment=GITHUB_REPO_OWNER=sm-techlabs
      Environment=GITHUB_REPO_NAME=oci-infra-art

      [Install]
      WantedBy=multi-user.target

  - path: /etc/caddy/Caddyfile
    permissions: '0644'
    content: |
      https://${frontend_subdomain}.${domain} {
          root * /opt/doodlebox/frontend
          file_server
      }

      https://${api_subdomain}.${domain} {
          reverse_proxy localhost:3000
      }
  - path: /opt/keys/doodlebox-dispatcher.private-key.pem
    permissions: '0600'
    content: |
      {{ base64decode(doodlebox_github_app_private_key) }}
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

  # Clone the source code (default branch: main)
  - git clone --depth 1 https://github.com/sm-techlabs/doodlebox /opt/doodlebox

  # Replace the frontend config with the correct API URL
  - API_BASE_URL='https://${api_subdomain}.${domain}'
  - sed -i -E "s|(API_BASE_URL[[:space:]]*:[[:space:]]*\")[^\"]*(\")|\1https://$${API_BASE_URL}\2|" /opt/doodlebox/frontend/index.html

  # Set permissions (directories: 755, files: 644)
  - find /opt/doodlebox -type d -exec chmod 755 {} \;
  - find /opt/doodlebox -type f -exec chmod 644 {} \;
  - chown -R www-data:www-data /opt/doodlebox

  # Backend setup
  - cd /opt/doodlebox/backend
  - npm install --omit=dev

  # Enable and start backend service
  - systemctl daemon-reload
  - systemctl enable --now doodlebox-backend

  # Restart Caddy
  - systemctl restart caddy

final_message: "The system is now configured and ready to use."
