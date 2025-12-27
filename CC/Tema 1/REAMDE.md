# Azure Static Web App Dashboard

## Student Information
**Name:** Andrei-Stefanel Murariu

## Live Website
**URL:** https://xrmt1stg.z6.web.core.windows.net/

## About This mini-Project

![Dashboard Screenshot](assets/dashboard.png)

### Features

- **Real-time Clock** - Live time and date display that updates every second
- **Dynamic Weather Data** - Weather information for any city worldwide using Open-Meteo API
- **Location Selection** - Interactive city search with geocoding and persistent storage
- **Live Statistics** - Page view counter, random numbers, and system information
- **Modern Dark Theme** - Clean, minimalist design with glassmorphism effects
- **Responsive Design** - Optimized for desktop, tablet, and mobile devices

### Technologies Used

- **Frontend:** HTML5, CSS3, Vanilla JavaScript
- **APIs:** Open-Meteo Weather API, Open-Meteo Geocoding API
- **Icons:** Font Awesome 6.4.0
- **Deployment:** Azure Storage Static Website Hosting
- **Automation:** Bash deployment script with Azure CLI

### Deployment

The application is deployed using a custom bash script (`deploy.sh`) that:
- Creates Azure Storage accounts
- Enables static website hosting
- Uploads files with proper error handling
- Manages storage account lifecycle
