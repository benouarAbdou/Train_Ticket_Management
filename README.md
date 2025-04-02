# Train Ticket System 

Project by Benouar Abdelouaheb, March 18, 2025  
For detailed documentation, see the full project report: [PDF Link](https://drive.google.com/file/d/1ThMW5SbOKL2TxEXUNpNkPxYNJDSNcaOC/view?usp=sharing)

## Overview
- A basic train ticket booking app built to learn and test skills.
- Combines familiar concepts with new challenges.

## Features

### Client Side
- **Search Ticket**
  - Input: departure city, arrival city, passengers, travel date.
  - Filters: excludes expired tickets, insufficient seats, inactive stations.
  - Displays: distance, price, seats left, times.

- **Booking Ticket**
  - Modify passengers, enter full names.
  - Total price calculated dynamically.
  - Generates unique ticket/passenger IDs (UUID).
  - Stores tickets in Firestore and locally for offline access.
  - Schedules notification 30 mins before departure (flutter_local_notifications: 18.0.1).

- **Booked Tickets**
  - View tickets offline/online (connectivity_plus: 8.1.3).
  - Syncs local and Firestore data.
  - Status: expired, used, confirmed (not used).

- **Ticket Details Page**
  - Shows: cities, times, price, status, IDs, barcode.
  - Share via text (share_plus: 10.1.4).
  - Download PDF (pdf: 3.10.8, path_provider: 2.1.3, open_file: 3.3.2).
  - Barcode generation (barcode_widget: 2.0.4).

- **Settings and Login**
  - Displays user ID, login button.
  - Email/password login via Firebase Authentication.

### Admin Side
- **Ticket Verification**
  - Scan barcodes via camera (simple_barcode_scanner: 0.3.0, permission_handler: 11.3.1).
  - Mark tickets as "used."

- **Station Management**
  - Create/edit stations: name, distances, active/inactive status.
  - Auto-updates reverse distances (e.g., a-b sets b-a).

- **Routes Management**
  - View/add/edit routes.
  - Reorder stations via drag-and-drop.

- **Trains Management**
  - View/add/edit trains: route, date, seats, price, schedule.
  - Reuse trains by updating details.

## Technical Details

### Security Rules (Firestore)
- Public read access for trains, bookings, stations, routes.
- Admin-only: create/update/delete (trains, stations, routes), update/delete (bookings).

### Platform Support
- Fully adaptive for Android (phones and tablets).

### Performance
- Loads in 1-2 seconds (release mode).
- Search results in <5 seconds.
- Dark theme and lazy loading for battery efficiency.

### Security
- Data stored locally and on Firebase.
- Firebase Authentication for admins (email/password).

### Connectivity
- Offline support: view tickets, details, notifications.

## Dependencies
- flutter_local_notifications: 18.0.1
- connectivity_plus: 8.1.3
- barcode_widget: 2.0.4
- share_plus: 10.1.4
- pdf: 3.10.8
- path_provider: 2.1.3
- open_file: 3.3.2
- simple_barcode_scanner: 0.3.0
- permission_handler: 11.3.1

## Challenges
- Structuring Firebase collections for scalability.
- Implementing Firestore security rules.

## Final Notes
- A functional app blending existing skills with new learning.
- Feedback welcome!