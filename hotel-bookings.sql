-- Create DataBase
CREATE DATABASE HOTEL_DB;

-- Create File Format
CREATE OR REPLACE FILE FORMAT FF_CSV
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '');

CREATE OR REPLACE STAGE STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = FF_CSV);

list @STG_HOTEL_BOOKINGS;

-- Create Table BRONZE_HOTEL_BOOKING
CREATE TABLE BRONZE_HOTEL_BOOKING (
    booking_id STRING,
    hotel_id STRING,
    hotel_city STRING,
    customer_id STRING,
    customer_name STRING,
    customer_email STRING,
    check_in_date STRING,
    check_out_date STRING,
    room_type STRING,
    num_guests STRING,
    total_amount STRING,
    currency STRING,
    booking_status STRING
);

-- Loading Data from Stage to Bronze Table
COPY INTO BRONZE_HOTEL_BOOKING
FROM @STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = FF_CSV)
ON_ERROR = 'CONTINUE';

select * from BRONZE_HOTEL_BOOKING;

-- Create Table SILVER_HOTEL_BOOKINGS
CREATE OR REPLACE TABLE SILVER_HOTEL_BOOKINGS (
    booking_id VARCHAR,
    hotel_id VARCHAR,
    hotel_city VARCHAR,
    customer_id VARCHAR,
    customer_name VARCHAR,
    customer_email VARCHAR,
    check_in_date DATE,
    check_out_date DATE,
    room_type VARCHAR,
    num_guests INTEGER,
    total_amount FLOAT,
    currency VARCHAR,
    booking_status VARCHAR
);

DESC TABLE SILVER_HOTEL_BOOKINGS;


-- need to clean the data, first try to check the errors and fix it

select CUSTOMER_EMAIL from BRONZE_HOTEL_BOOKING
where CUSTOMER_EMAIL NOT LIKE '%@%.%' or CUSTOMER_EMAIL IS NULL;

-- using TRY_TO_NUMBER means -> it converts text to number directly, TRY_TO_NUMBER('500')-> 500 -> TRY_TO_NUMBER('abc') --> NULL

select total_amount from BRONZE_HOTEL_BOOKING
where TRY_TO_NUMBER(total_amount) < 0;

select distinct booking_status from BRONZE_HOTEL_BOOKING;

-- Inserting Cleaned data to Silver layer
INSERT INTO SILVER_HOTEL_BOOKINGS
SELECT 
    booking_id,
    hotel_id,
    INITCAP(TRIM(Hotel_city))as hotel_city,
    customer_id,
    INITCAP(TRIM(customer_name))as customer_name,
    case when customer_email LIKE '%@%.%' then lower(trim(customer_email))
    else NULL end as customer_email,
    TRY_TO_DATE(NULLIF(CHECK_IN_DATE, '')) as check_in_date,
    TRY_TO_DATE(NULLIF(CHECK_OUT_DATE, '')) as check_out_date,
    room_type,
    num_guests,
    abs(TRY_TO_NUMBER(total_amount)) as total_amount,
    currency,
    case when booking_status IN ('Confirmeeed') then 'Confirmed'
    else booking_status end as booking_status
    from BRONZE_HOTEL_BOOKING
    where TRY_TO_DATE(CHECK_IN_DATE) IS NOT NULL and 
    TRY_TO_DATE(CHECK_OUT_DATE) IS NOT NULL and 
    TRY_TO_DATE(CHECK_OUT_DATE) >= TRY_TO_DATE(CHECK_IN_DATE);
    
select * from SILVER_HOTEL_BOOKINGS;

SELECT DISTINCT booking_status FROM SILVER_HOTEL_BOOKINGS;
SELECT DISTINCT check_in_date FROM SILVER_HOTEL_BOOKINGS;

-- create gold tables (business ready tables)
-- 1. Show monthly revenue and monthly bookings
       CREATE TABLE GOLD_AGG_DAILY_BOOKING AS
       select check_in_date as date,
       sum(total_amount) as total_revenue,
       count(*) as total_bookings
       from SILVER_HOTEL_BOOKINGS
       group by check_in_date
       order by date;

select * from GOLD_AGG_DAILY_BOOKING;
       
-- 2. Identify top revenue generating cities
     CREATE TABLE GOLD_AGG_HOTEL_CITY_SALES AS
       select hotel_city,
       sum(total_amount) as total_revenue
       from SILVER_HOTEL_BOOKINGS
       group by hotel_city
       order by hotel_city desc;

 select * from GOLD_AGG_HOTEL_CITY_SALES limit 50; 

CREATE TABLE GOLD_BOOKING_CLEAN AS
select 
    booking_id,
    hotel_id,
    hotel_city,
    customer_id,
    customer_name,
    customer_email,
    check_in_date,
    check_out_date,
    room_type,
    num_guests,
    total_amount,
    currency,
    booking_status
    from SILVER_HOTEL_BOOKINGS;

select sum(total_amount) from GOLD_BOOKING_CLEAN ; 
  select * from GOLD_BOOKING_CLEAN ; 

-- Analyse bookings by type and status
 CREATE TABLE GOLD_AGG_BOOKING_STATUS AS
       select room_type as roomtype,
       booking_status as status,
       check_in_date as date,
       COUNT(*) AS total_bookings,
       sum(total_amount) as total_revenue
       from SILVER_HOTEL_BOOKINGS
       group by room_type, booking_status,check_in_date
       order by date ;
       
  select * from GOLD_AGG_BOOKING_STATUS;  
    
