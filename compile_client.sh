#!/bin/bash

# Compile the application using grunt
(cd manager-client && grunt dist)

# Remove old assets
rm assets/docker-manager-*

cp manager-client/dist/assets/app.min.css assets/docker-manager-app.css
cp manager-client/dist/assets/app.min.js assets/docker-manager-app.js
cp manager-client/dist/assets/vendor.min.js assets/docker-manager-vendor.js
cp manager-client/dist/assets/config.min.js assets/docker-manager-config.js

# font files
cp manager-client/public/assets/css/font-awesome/assets/fonts/fontawesome-webfont.eot assets/fonts/fontawesome-webfont.eot
cp manager-client/public/assets/css/font-awesome/assets/fonts/fontawesome-webfont.svg assets/fonts/fontawesome-webfont.svg
cp manager-client/public/assets/css/font-awesome/assets/fonts/fontawesome-webfont.ttf assets/fonts/fontawesome-webfont.ttf
cp manager-client/public/assets/css/font-awesome/assets/fonts/fontawesome-webfont.woff assets/fonts/fontawesome-webfont.woff
cp manager-client/public/assets/css/font-awesome/assets/fonts/fontawesome.otf assets/fonts/fontawesome.otf
