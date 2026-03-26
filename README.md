# Ice Ice Baby – Retail Hub Application

## Overview

Ice Ice Baby – Retail Hub is a cloud-connected B2C ecosystem designed to connect a Retail Administrator with Consumers through a modern mobile interface. The system enables real-time product management, browsing, and purchasing using Firebase as the backend.

This project demonstrates a full-stack application integrating frontend UI, backend services, and real-time database synchronization.

---

## Core System Features

* Firebase Realtime Database integration
* Real-time data synchronization
* Cloud-based storage
* Scalable architecture

---

## Tech Stack

### Frontend

* Flutter / FlutterFlow
* Dart

### Backend

* Firebase Realtime Database
* Firebase Authentication
* Firebase CLoud Storage

---

## Installation & Setup

### Prerequisites

* Flutter SDK installed
* Firebase project configured
* Android Studio or VS Code

### Steps

1. Clone the repository:

```bash
git clone https://github.com/your-repo/Ice-Ice-Baby_RetailHub.git
```

2. Navigate into the project:

```bash
cd Ice-Ice-Baby_RetailHub
```

3. Install dependencies:

```bash
flutter pub get
```

4. Set up Firebase:

* Create a Firebase project
* Enable Realtime Database
* Download `google-services.json`
* Place it in the appropriate directory

5. Run the application:

```bash
flutter run
```

---

## Database Structure (Firebase)

Example structure:

```
products/
  product_id/
    name: string
    sku: string
    category: string
    basePrice: number
    discountedPrice: number
    stockQuantity: number
    description: string
    supplier: string
    dateAdded: timestamp
    imageUrl: string
```

---

## Usage

### Admin Workflow

1. Log in as admin
2. Navigate to product management
3. Add or update products
4. Monitor inventory and user orders

### Consumer Workflow

1. Browse products
3. View product details
4. Add to cart and purchase

---

## Notes

This project is part of the coursework requirement for Mobile Application Develoment 2, demonstrating full-stack mobile application development using Firebase and Flutter/FlutterFlow.
