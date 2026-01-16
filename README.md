# Smart Restaurant Management System

**Smart Restaurant Management System** is a hybrid, real-time restaurant automation platform designed to bridge the gap between dining customers and kitchen staff. By combining a web-based interface for customers with high-performance native mobile apps for staff, the system eliminates communication errors, reduces wait times, and streamlines the entire order lifecycle.

## 🚀 Project Overview

Traditional restaurant workflows rely on manual ticketing or static KOT systems. This system introduces a fully synchronized ecosystem where a customer's digital order updates the kitchen screens instantly.
* **For Customers:** No app download required. Scan a QR code and order via the web.
* **For Staff:** Dedicated mobile applications for Chefs and Waiters to manage workflow efficiently.

## 🔄 System Flow

The data flows in real-time across different platforms using **Supabase**:

1.  **Order Creation:** Customer scans QR code -> Opens Web Menu -> Places Order.
2.  **Sync:** Order data is pushed to the **Supabase** database.
3.  **Kitchen Trigger:** The KDS App (Flutter) listens to the database and instantly displays the new ticket (Green status).
4.  **Preparation:** Chef marks item as "Ready" -> Database updates status.
5.  **Service:** Waiter App (Flutter) receives a notification to pick up and serve the food.
6.  **Bill Generation:** Waiter App (Flutter) and admin dashboard generates the final bill for checkout and payment.

## 🛠 Tech Stack

### Frontend (Web)
* **Framework:** React.js + TailwindCSS
* **Use Case:** Customer Ordering Interface & Admin Dashboard.
* **Reasoning:** Accessibility for customers (no install needed) and complex data visualization for admins.

### Frontend (Mobile)
* **Framework:** Flutter (Dart)
* **Use Case:** Kitchen Display System (KDS) & Waiter Application.
* **Reasoning:** Native performance, reliable offline handling, and ease of deployment on tablets/phones.

### Backend & Database
* **Platform:** Supabase (BaaS)
* **Database:** PostgreSQL
* **Features:**
    * **Real-time Subscriptions:** To push orders to the kitchen instantly.
    * **Relational Data:** To handle complex relations between Tables, Orders, and Menu Items.

---

## 📱 Modules & Features

### 1. Customer Module (Web Client)
* **QR Code Access:** Instant access to the menu via browser.
* **Smart Filtering:** Filter by Veg/Non-Veg, Spicy Level, or Category.
* **Live Status:** Customers can see if their food is "Preparing" or "Ready" without asking staff.
* **Cart Management:** Add/Remove items and customize instructions (e.g., "No Cheese").
* **QR Payment Integration:** Secure digital payments (UPI/Card) integrated directly into the checkout flow.
* **Feedback System:** Prompt customers to rate food quality and service after the bill is settled.

### 2. Admin Dashboard (Web Client)
* **Menu Management:** Add, edit, or delete dishes and update prices in real-time.
* **User Management:** Create cook profiles, update permissions, and view ongoing activity (e.g., 3-hour window monitoring).
* **Stock Toggle:** Instantly mark items as "Out of Stock" to prevent ordering.
* **Sales Overview:** View daily order logs and table occupancy.
* **Bill Generation:** Consolidate customer orders and generate the final bill for checkout.

### 3. Kitchen Display System (KDS) (Flutter App)
* **Real-Time Ticketing:** Orders appear instantly without refreshing.
* **Ticket Aging Logic:** Visual cues to prioritize orders:
    * 🟢 **Green:** New Order
    * 🟡 **Yellow:** 15+ mins waiting
    * 🔴 **Red:** 30+ mins (Priority)
* **Station Routing:** Categorizes items for different stations (e.g., Drinks vs. Main Course).

### 4. Waiter Application (Flutter App)
* **Service Notifications:** Alerts the waiter when a specific table's food is ready.
* **Manual KOT:** Allows waiters to place orders manually for customers who prefer not to use digital ordering.
* **Table Status:** View which tables are occupied, waiting for food, or ready for billing.

---

## 🔮 Future Enhancements
* **Inventory Management:** Automated deduction of ingredients based on orders.
* **AI Recommendations:** Suggesting pairings (e.g., "Coke with Pizza") during checkout.
* **Multi-Branch Support:** SaaS architecture to manage multiple restaurant locations.