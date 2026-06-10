import os
import streamlit as st

st.set_page_config(page_title="Hotel Bookings Dashboard", page_icon=":hotel:", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data
def load_data():
    return conn.query("""
        SELECT
            booking_id,
            hotel_city,
            check_in_date,
            check_out_date,
            room_type,
            num_guests,
            total_amount,
            booking_status
        FROM HOTEL_DB.PUBLIC.SILVER_HOTEL_BOOKINGS
    """)


st.title("Hotel Bookings Dashboard")

with st.spinner("Loading data..."):
    df = load_data()

# --- KPI Metrics ---
total_bookings = len(df)
total_revenue = df["TOTAL_AMOUNT"].sum()
avg_booking_value = df["TOTAL_AMOUNT"].mean()
total_guests = df["NUM_GUESTS"].sum()

with st.container(horizontal=True):
    st.metric("Total Bookings", f"{total_bookings:,}", border=True)
    st.metric("Total Revenue", f"{total_revenue:,.0f}", border=True)
    st.metric("Avg Booking Value", f"{avg_booking_value:,.2f}", border=True)
    st.metric("Total Guests", f"{total_guests:,}", border=True)

st.divider()

# --- Monthly Charts ---
df["MONTH"] = df["CHECK_IN_DATE"].astype("datetime64[ns]").dt.to_period("M").dt.to_timestamp()

monthly = df.groupby("MONTH").agg(
    REVENUE=("TOTAL_AMOUNT", "sum"),
    BOOKINGS=("BOOKING_ID", "count")
).reset_index()

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.subheader("Revenue per Month")
        st.line_chart(monthly, x="MONTH", y="REVENUE")

with col2:
    with st.container(border=True):
        st.subheader("Bookings per Month")
        st.line_chart(monthly, x="MONTH", y="BOOKINGS")

st.divider()

# --- Bar Charts ---
col3, col4, col5 = st.columns(3)

with col3:
    with st.container(border=True):
        st.subheader("Top Cities by Revenue")
        city_revenue = df.groupby("HOTEL_CITY")["TOTAL_AMOUNT"].sum().reset_index()
        city_revenue.columns = ["CITY", "REVENUE"]
        city_revenue = city_revenue.sort_values("REVENUE", ascending=False)
        st.bar_chart(city_revenue, x="CITY", y="REVENUE")

with col4:
    with st.container(border=True):
        st.subheader("Bookings by Room Type")
        room_counts = df.groupby("ROOM_TYPE")["BOOKING_ID"].count().reset_index()
        room_counts.columns = ["ROOM_TYPE", "BOOKINGS"]
        st.bar_chart(room_counts, x="ROOM_TYPE", y="BOOKINGS")

with col5:
    with st.container(border=True):
        st.subheader("Bookings by Status")
        status_counts = df.groupby("BOOKING_STATUS")["BOOKING_ID"].count().reset_index()
        status_counts.columns = ["STATUS", "BOOKINGS"]
        st.bar_chart(status_counts, x="STATUS", y="BOOKINGS")
