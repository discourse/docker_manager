#!/bin/bash

# Compile the application using ember-cli
(cd manager-client && ember build --environment=production)

# Remove old assets
rm assets/docker-manager-*

cp manager-client/dist/assets/manager-client.css assets/docker-manager-app.css
cp manager-client/dist/assets/manager-client.js assets/docker-manager-app.js
cp manager-client/dist/assets/vendor.js assets/docker-manager-vendor.js
cp manager-client/dist/assets/vendor.css assets/docker-manager-vendor.css

# font files
cp manager-client/dist/fonts/fontawesome-webfont.eot assets/fonts/fontawesome-webfont.eot
cp manager-client/dist/fonts/fontawesome-webfont.svg assets/fonts/fontawesome-webfont.svg
cp manager-client/dist/fonts/fontawesome-webfont.ttf assets/fonts/fontawesome-webfont.ttf
cp manager-client/dist/fonts/fontawesome-webfont.woff assets/fonts/fontawesome-webfont.woff

# fix invalid paths
sed -i '' 's/\.\.\/fonts/fonts/g' assets/docker-manager-vendor.css
