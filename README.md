# Hotel Booking Project | Snowflake Data Pipeline + Dashboard

A production-style data engineering project demonstrating the **Medallion Architecture** (Bronze → Silver → Gold) on Snowflake, with an interactive Streamlit dashboard for business intelligence.

---

## Pipeline Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌────────────────┐
│  CSV File   │────▶│  Snowflake   │────▶│    Bronze    │────▶│    Silver    │────▶│     Gold       │
│  (Source)   │     │    Stage     │     │  (Raw Data)  │     │  (Cleaned)   │     │ (Aggregated)   │
└─────────────┘     └──────────────┘     └──────────────┘     └──────────────┘     └────────────────┘
                                                                                           │
                                                                                           ▼
                                                                                   ┌────────────────┐
                                                                                   │   Streamlit    │
                                                                                   │   Dashboard    │
                                                                                   └────────────────┘
```

---

## Project Structure

```
hotel-booking-project-snowflake/
│
├── hotel-bookings.sql                        # Complete SQL pipeline (Bronze → Silver → Gold)
├── README.md
│
└── hotel-dashboard/                 # Streamlit dashboard application
    ├── .streamlit/config.toml       # App theme configuration
    ├── pyproject.toml               # Python dependencies
    ├── snowflake.yml                # Snowflake app deployment config
    └── streamlit_app.py             # Dashboard source code
```

---

## Data Layers

### Bronze — Raw Ingestion

| Table | Description |
|-------|-------------|
| `BRONZE_HOTEL_BOOKING` | Raw CSV data loaded as-is (all STRING columns) |

### Silver — Cleaned and Validated

| Table | Description |
|-------|-------------|
| `SILVER_HOTEL_BOOKINGS` | Type-cast, trimmed, validated, and filtered records |

**Transformations applied:**
- Standardized city and customer names (TRIM + INITCAP)
- Email validation (regex pattern check, lowercased)
- Date conversion (STRING → DATE) with NULL handling
- Negative amounts corrected (ABS)
- Typo fix: "Confirmeeed" → "Confirmed"
- Removed records with invalid or illogical date ranges

### Gold — Business-Ready Aggregations

| Table | Purpose |
|-------|---------|
| `GOLD_AGG_DAILY_BOOKING` | Daily revenue and booking count by check-in date |
| `GOLD_AGG_HOTEL_CITY_SALES` | Total revenue breakdown by city |
| `GOLD_BOOKING_CLEAN` | Final clean dataset with all booking details |
| `GOLD_AGG_BOOKING_STATUS` | Revenue and bookings by room type, status, and date |

---

## Dashboard KPIs

| KPI | Visualization |
|-----|---------------|
| Total Bookings | Metric Card |
| Total Revenue | Metric Card |
| Average Booking Value | Metric Card |
| Total Guests | Metric Card |
| Revenue per Month | Line Chart |
| Bookings per Month | Line Chart |
| Top Cities by Revenue | Bar Chart |
| Bookings by Room Type | Bar Chart |
| Bookings by Status | Bar Chart |

---

## Setup Instructions

### Prerequisites

- Snowflake account with `ACCOUNTADMIN` role
- Warehouse: `COMPUTE_WH`

### Step 1: Run the Data Pipeline

1. Open a **SQL Worksheet** in Snowsight
2. Execute `hotel-bookings.sql` end-to-end
3. This creates the database, stage, and all Bronze/Silver/Gold tables

### Step 2: Launch the Dashboard

1. Navigate to **Projects > Workspaces** in Snowsight
2. Open `hotel-dashboard/streamlit_app.py`
3. Click **Run**

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Data Warehouse | Snowflake |
| Data Ingestion | Snowflake Stages + COPY INTO |
| Data Pipeline | SQL (Medallion Architecture) |
| Dashboard | Streamlit in Snowflake |
| Language | SQL, Python |

---

## Dashboard Output Screenshots

### Total Bookings, Total Revenue, Avg Booking Value, Total Guests, Revenue per Month, Bookings per Month



<img width="1757" height="807" alt="dashboard-output" src="https://github.com/user-attachments/assets/9ab78a89-bc73-4ce6-ad57-d379cd7f0e7e" />





### Top Cities by Revenue, Bookings by Room Type, Bookings by Status



<img width="1755" height="796" alt="dashboard-output1" src="https://github.com/user-attachments/assets/c318faac-978b-4d21-a8f5-19327bc25cd4" />









