#!/bin/bash

# Compile the application using ember-cli
(cd manager-client && ember build --environment=production)

# Remove old assets
rm assets/docker-manager-*

cp manager-client/dist/assets/manager-client.css assets/docker-manager-app.css
cp manager-client/dist/assets/manager-client.js assets/docker-manager-app.js
cp manager-client/dist/assets/vendor.js assets/docker-manager-vendor.js
cp manager-client/dist/assets/vendor.css assets/docker-manager-vendor.css

# fix invalid paths
sed -i '' 's/\.\.\/fonts/fonts/g' assets/docker-manager-vendor.css
