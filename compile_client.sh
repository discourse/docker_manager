#!/bin/bash

# Compile the application using grunt
(cd manager-client && grunt dist)

# Remove old assets
rm assets/docker-manager-*

cp manager-client/dist/assets/app.min.css assets/docker-manager-app.css
cp manager-client/dist/assets/app.min.js assets/docker-manager-app.js
cp manager-client/dist/assets/vendor.min.js assets/docker-manager-vendor.js
cp manager-client/dist/assets/config.min.js assets/docker-manager-config.js
