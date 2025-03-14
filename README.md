# train_app 🚆

## Overview 🚀
`train_app` is a mobile train ticket management system built with Flutter. Users can search, book, and manage train tickets, while admins handle routes, destinations, and ticket verification.

## Features 📌

### User Features 🎟️
**Ticket Booking:**
- Search trains by origin, destination, date, and passengers
- View available trains with timings, prices, and seats
- Book tickets without authentication
- Generate unique ticket IDs

**Ticket Management:**
- View purchased tickets
- Check train details, journey date, and status (valid/used/expired)
- Share tickets via messaging apps or email
- Download tickets as PDFs
- Optional 30-minute pre-departure notification

**Ticket Validation:**
- Display digital tickets
- Verify with a reference number
- Show validity status

### Admin Features 🔧
**Authentication:**
- Secure admin login

**Destination Management:**
- Add, edit, or toggle destinations
- Set distances between stations

**Train Management:**
- Create/edit routes, schedules, and pricing
- Manage seat availability

**Ticket Verification:**
- Validate ticket IDs manually
- View details and mark as used

## Tech Stack 🛠️
- **Frontend:** Flutter (Dart)
- **State Management:** GetX (`get: ^4.7.2`)
- **Database:** Firebase Firestore (`cloud_firestore: ^5.6.5`), Hive (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`)
- **Authentication:** Firebase Auth (`firebase_auth: ^5.5.1`)
- **Notifications:** Flutter Local Notifications (`flutter_local_notifications: ^18.0.1`)
- **PDF & Sharing:** `pdf: ^3.10.8`, `share_plus: ^10.1.4`
- **Connectivity:** `connectivity_plus: ^6.1.3`
- **Extras:** `flutter_typeahead: ^5.2.0` (search), `uuid: ^4.5.1` (IDs), `intl: ^0.20.2` (dates)

## Setup & Installation 🔨
1. Clone the repository:
   ```bash
   git clone https://github.com/benouarAbdou
   cd train_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```


