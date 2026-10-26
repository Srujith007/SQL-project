-- =====================================================================
-- StayPoint Hospitality — Hotel Reservation Operations Analytics
-- MySQL Business Analytics Project — Combined Master SQL File
-- =====================================================================
-- Dataset source: 6 CSV files (guests, hotels, rooms, bookings, stays,
-- staff) provided as part of the Hotel Reservation Analytics course
-- project brief, representing StayPoint Hospitality's booking and stay
-- records. Row counts and structure verified in Section 2 below.
--
-- Sections in this file, matching the project's SQL Deliverable list:
--   1. Sprint 2.1 — Database & Table Creation
--   2. Sprint 2.2 — Data Import (edit the file paths for your machine)
--   3. Sprint 3   — Basic Analysis / Data Exploration (8 queries)
--   4. Sprint 4   — Objective-Based Analysis (25 queries, 5 objectives)
--   5. SQL Concepts Showcase — explicit INNER JOIN, LEFT JOIN,
--      subqueries (WHERE, correlated, derived table)
--
-- Sprint 1.4's written (non-SQL) answers live in the separate report
-- document, since that sprint explicitly asks NOT to write SQL.
-- =====================================================================


-- #####################################################################
-- SECTION 1: SPRINT 2.1 — DATABASE & TABLE CREATION
-- #####################################################################


CREATE DATABASE IF NOT EXISTS hotel_reservation_analytics;
USE hotel_reservation_analytics;

-- Drop in reverse dependency order (safe to re-run while building)
DROP TABLE IF EXISTS stays;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS guests;
DROP TABLE IF EXISTS hotels;

-- ---------------------------------------------------------------------
-- 1. hotels — independent table, no FKs
-- ---------------------------------------------------------------------
CREATE TABLE hotels (
    hotel_id     VARCHAR(20)   NOT NULL,
    hotel_name   VARCHAR(100)  NOT NULL,
    city         VARCHAR(50),
    star_rating  INT,
    total_rooms  INT,
    opened_date  DATE,
    PRIMARY KEY (hotel_id),
    CHECK (star_rating BETWEEN 1 AND 5)
);

-- ---------------------------------------------------------------------
-- 2. guests — independent table, no FKs
-- ---------------------------------------------------------------------
CREATE TABLE guests (
    guest_id             VARCHAR(20)   NOT NULL,
    guest_name           VARCHAR(100)  NOT NULL,
    city                 VARCHAR(50),
    guest_type           VARCHAR(20),   -- e.g. Individual / Corporate
    preferred_room_type  VARCHAR(20),
    loyalty_tier         VARCHAR(20),
    account_since        DATE,
    PRIMARY KEY (guest_id)
);

-- ---------------------------------------------------------------------
-- 3. staff — independent table, no FKs
-- ---------------------------------------------------------------------
CREATE TABLE staff (
    staff_id     VARCHAR(20)   NOT NULL,
    staff_name   VARCHAR(100)  NOT NULL,
    hire_date    DATE,
    rating       DECIMAL(3,2),
    department   VARCHAR(30),
    is_active    VARCHAR(3)    DEFAULT 'Yes',
    PRIMARY KEY (staff_id)
);

-- ---------------------------------------------------------------------
-- 4. rooms — depends on hotels
-- ---------------------------------------------------------------------
CREATE TABLE rooms (
    room_id         VARCHAR(20)   NOT NULL,
    hotel_id        VARCHAR(20)   NOT NULL,
    room_type       VARCHAR(20),
    floor_number    INT,
    max_occupancy   INT,
    price_per_night DECIMAL(10,2),
    is_active       VARCHAR(3)    DEFAULT 'Yes',
    PRIMARY KEY (room_id),
    CONSTRAINT fk_rooms_hotel
        FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 5. bookings — depends on guests, hotels
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    booking_id            VARCHAR(20)    NOT NULL,
    guest_id              VARCHAR(20)    NOT NULL,
    hotel_id              VARCHAR(20)    NOT NULL,
    booking_date          DATE,
    room_type_requested   VARCHAR(20),
    booking_channel       VARCHAR(30),
    nights_booked         INT            DEFAULT 1,
    total_amount          DECIMAL(12,2),
    PRIMARY KEY (booking_id),
    CONSTRAINT fk_bookings_guest
        FOREIGN KEY (guest_id) REFERENCES guests(guest_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_hotel
        FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (nights_booked > 0)
);

-- ---------------------------------------------------------------------
-- 6. stays — depends on bookings, rooms, staff
-- ---------------------------------------------------------------------
CREATE TABLE stays (
    stay_id           VARCHAR(20)   NOT NULL,
    booking_id        VARCHAR(20)   NOT NULL,
    room_id           VARCHAR(20)   NOT NULL,
    staff_id          VARCHAR(20),          -- nullable: a stay may not yet have an assigned staff member
    check_in_date     DATE,
    check_out_date    DATE,
    status            VARCHAR(20),          -- Checked-out / No-show / Cancelled / In-progress
    nights_stayed     INT,
    service_requests  INT           DEFAULT 0,
    stay_duration_hrs INT,
    PRIMARY KEY (stay_id),
    CONSTRAINT fk_stays_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_stays_room
        FOREIGN KEY (room_id) REFERENCES rooms(room_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_stays_staff
        FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- Helpful indexes for the analysis queries in Sprints 3 & 4
-- ---------------------------------------------------------------------
CREATE INDEX idx_bookings_guest   ON bookings(guest_id);
CREATE INDEX idx_bookings_hotel   ON bookings(hotel_id);
CREATE INDEX idx_bookings_channel ON bookings(booking_channel);
CREATE INDEX idx_rooms_hotel      ON rooms(hotel_id);
CREATE INDEX idx_stays_booking    ON stays(booking_id);
CREATE INDEX idx_stays_room       ON stays(room_id);
CREATE INDEX idx_stays_staff      ON stays(staff_id);
CREATE INDEX idx_stays_status     ON stays(status);


-- #####################################################################
-- SECTION 2: SPRINT 2.2 — DATA IMPORT
-- Edit the 6 file paths below to point at your own CSV locations
-- before running this section.
-- #####################################################################

USE hotel_reservation_analytics;

SET GLOBAL local_infile = 1;
-- Connect with: mysql -u root --local-infile=1

-- Clear out any partial/garbled data from a previous failed run before
-- reloading (safe to run even on empty tables). Order: children first.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE stays;
TRUNCATE TABLE bookings;
TRUNCATE TABLE rooms;
TRUNCATE TABLE guests;
TRUNCATE TABLE staff;
TRUNCATE TABLE hotels;
SET FOREIGN_KEY_CHECKS = 1;

-- Order matters: hotels, guests, staff (parents) -> rooms -> bookings -> stays

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\hotels.csv'
INTO TABLE hotels
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(hotel_id, hotel_name, city, star_rating, total_rooms, opened_date);

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\guests.csv'
INTO TABLE guests
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(guest_id, guest_name, city, guest_type, preferred_room_type, loyalty_tier, @account_since)
SET account_since = STR_TO_DATE(@account_since, '%d-%m-%Y');

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\staff.csv'
INTO TABLE staff
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(staff_id, staff_name, hire_date, rating, department, is_active);

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\rooms.csv'
INTO TABLE rooms
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(room_id, hotel_id, room_type, floor_number, max_occupancy, price_per_night, is_active);

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\bookings.csv'
INTO TABLE bookings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(booking_id, guest_id, hotel_id, @booking_date, room_type_requested, booking_channel, nights_booked, total_amount)
SET booking_date = STR_TO_DATE(@booking_date, '%d-%m-%Y');

LOAD DATA LOCAL INFILE 'E:\\Innomatics\\SQL project\\stays.csv'
INTO TABLE stays
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(stay_id, booking_id, room_id, staff_id, check_in_date, check_out_date, status, nights_stayed, service_requests, stay_duration_hrs);

-- ---------------------------------------------------------------------
-- Verification — actual results after running this against the
-- provided CSVs (matches the Dataset Overview table exactly):
--   hotels    25
--   guests    350
--   staff     70
--   rooms     600
--   bookings  2800
--   stays     3200
-- ---------------------------------------------------------------------
SELECT 'hotels'   AS table_name, COUNT(*) AS row_count FROM hotels
UNION ALL SELECT 'guests',   COUNT(*) FROM guests
UNION ALL SELECT 'staff',    COUNT(*) FROM staff
UNION ALL SELECT 'rooms',    COUNT(*) FROM rooms
UNION ALL SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL SELECT 'stays',    COUNT(*) FROM stays;

-- Orphan-FK sanity check — all six return 0 rows once data is loaded
-- in the correct order:
SELECT * FROM rooms    r WHERE NOT EXISTS (SELECT 1 FROM hotels h   WHERE h.hotel_id = r.hotel_id);
SELECT * FROM bookings b WHERE NOT EXISTS (SELECT 1 FROM guests g   WHERE g.guest_id = b.guest_id);
SELECT * FROM bookings b WHERE NOT EXISTS (SELECT 1 FROM hotels h   WHERE h.hotel_id = b.hotel_id);
SELECT * FROM stays    s WHERE NOT EXISTS (SELECT 1 FROM bookings bk WHERE bk.booking_id = s.booking_id);
SELECT * FROM stays    s WHERE NOT EXISTS (SELECT 1 FROM rooms   r  WHERE r.room_id = s.room_id);
SELECT * FROM stays    s WHERE NOT EXISTS (SELECT 1 FROM staff   st WHERE st.staff_id = s.staff_id);


-- #####################################################################
-- SECTION 3: SPRINT 3 — BASIC ANALYSIS / DATA EXPLORATION
-- #####################################################################

-- =====================================================================
USE hotel_reservation_analytics;

-- 1. Total number of guests
SELECT COUNT(*) AS total_guests
FROM guests;

-- 2. Total number of bookings
SELECT COUNT(*) AS total_bookings
FROM bookings;

-- 3. Total number of stays
SELECT COUNT(*) AS total_stays
FROM stays;

-- 4. Different room types available
SELECT DISTINCT room_type
FROM rooms
ORDER BY room_type;

-- 5. Staff members currently active
SELECT COUNT(*) AS active_staff
FROM staff
WHERE is_active = 'Yes';

-- 6. Different booking channels
SELECT DISTINCT booking_channel
FROM bookings
ORDER BY booking_channel;

-- 7. Total booking amount across all bookings
SELECT SUM(total_amount) AS total_booking_amount
FROM bookings;

-- 8. Average nights booked per booking
SELECT ROUND(AVG(nights_booked), 2) AS avg_nights_booked
FROM bookings;


-- #####################################################################
-- SECTION 4: SPRINT 4 — OBJECTIVE-BASED ANALYSIS
-- #####################################################################

-- For each objective: analytical questions -> SQL -> (interpret results
-- against the actual data once imported; insight lines are placeholders
-- to fill in after running these against your data).
-- =====================================================================
USE hotel_reservation_analytics;


-- #####################################################################
-- 4.1 Understand Booking Demand
-- #####################################################################

-- Q1.1: How many bookings does each hotel have, and what's the total
-- and average booking amount per hotel?
SELECT
    h.hotel_id,
    h.hotel_name,
    h.city,
    COUNT(b.booking_id)         AS total_bookings,
    SUM(b.total_amount)         AS total_booking_amount,
    ROUND(AVG(b.total_amount),2) AS avg_booking_amount
FROM hotels h
LEFT JOIN bookings b ON b.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name, h.city
ORDER BY total_bookings DESC;

-- Q1.2: How does booking volume and spend compare across booking channels?
SELECT
    booking_channel,
    COUNT(*)                     AS total_bookings,
    SUM(total_amount)            AS total_amount,
    ROUND(AVG(total_amount),2)   AS avg_amount,
    ROUND(AVG(nights_booked),2)  AS avg_nights_booked
FROM bookings
GROUP BY booking_channel
ORDER BY total_bookings DESC;

-- Q1.3: Which requested room types are most in demand?
SELECT
    room_type_requested,
    COUNT(*)               AS total_bookings,
    SUM(total_amount)      AS total_amount
FROM bookings
GROUP BY room_type_requested
ORDER BY total_bookings DESC;

-- Q1.4: How does booking volume trend over time (by month)?
SELECT
    DATE_FORMAT(booking_date, '%Y-%m') AS booking_month,
    COUNT(*)                           AS total_bookings,
    SUM(total_amount)                  AS total_amount
FROM bookings
GROUP BY DATE_FORMAT(booking_date, '%Y-%m')
ORDER BY booking_month;

-- Q1.5: Which hotel + channel combinations bring in the most revenue?
SELECT
    h.hotel_name,
    b.booking_channel,
    COUNT(*)             AS total_bookings,
    SUM(b.total_amount)  AS total_amount
FROM bookings b
JOIN hotels h ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name, b.booking_channel
ORDER BY total_amount DESC
LIMIT 20;

-- Insight: Bookings are spread fairly evenly across the 25 hotels (98-129 each, no single hotel
-- dominates). Website (984) and Mobile App (875) drive ~66% of bookings, but Mobile App bookings
-- run higher in average value (Rs 17,427) than Website (Rs 15,548). Standard rooms are booked most
-- often (1,259 bookings) but Suites carry the highest average booking value (Rs 27,477 vs Rs 10,781
-- for Standard), so volume leader and revenue-per-booking leader are different room types.



-- #####################################################################
-- 4.2 Understand Guest Booking Behaviour
-- #####################################################################

-- Q2.1: Which guests have made the most bookings?
SELECT
    g.guest_id,
    g.guest_name,
    g.guest_type,
    COUNT(b.booking_id)  AS total_bookings,
    SUM(b.total_amount)  AS total_spent
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id
GROUP BY g.guest_id, g.guest_name, g.guest_type
ORDER BY total_bookings DESC
LIMIT 20;

-- Q2.2: Which guests have the highest total booking amount (top spenders)?
SELECT
    g.guest_id,
    g.guest_name,
    g.loyalty_tier,
    SUM(b.total_amount) AS total_spent
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id
GROUP BY g.guest_id, g.guest_name, g.loyalty_tier
ORDER BY total_spent DESC
LIMIT 20;

-- Q2.3: How does guest activity differ across hotels?
SELECT
    h.hotel_name,
    COUNT(DISTINCT b.guest_id) AS distinct_guests,
    COUNT(b.booking_id)        AS total_bookings
FROM bookings b
JOIN hotels h ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name
ORDER BY distinct_guests DESC;

-- Q2.4: How do Individual vs Corporate guests differ in booking behaviour?
SELECT
    g.guest_type,
    COUNT(DISTINCT g.guest_id)      AS distinct_guests,
    COUNT(b.booking_id)             AS total_bookings,
    ROUND(AVG(b.total_amount),2)    AS avg_booking_amount,
    ROUND(AVG(b.nights_booked),2)   AS avg_nights_booked
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id
GROUP BY g.guest_type;

-- Q2.5: How does guest booking volume trend over time by loyalty tier?
SELECT
    g.loyalty_tier,
    DATE_FORMAT(b.booking_date, '%Y-%m') AS booking_month,
    COUNT(*) AS total_bookings
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id
GROUP BY g.loyalty_tier, DATE_FORMAT(b.booking_date, '%Y-%m')
ORDER BY booking_month, g.loyalty_tier;

-- Insight: Individual guests (233 of 350) generate more than double the bookings of Corporate
-- guests (1,903 vs 897), but average booking value and nights booked are nearly identical between
-- the two types (~Rs 16,000-16,500, ~3.3 nights). Corporate accounts book less often but at a
-- comparable ticket size, suggesting Corporate demand is driven by fewer, larger accounts rather
-- than higher-value individual transactions.



-- #####################################################################
-- 4.3 Evaluate Stay Performance
-- #####################################################################

-- Q3.1: How do stay outcomes (status) break down overall?
SELECT
    status,
    COUNT(*) AS total_stays,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM stays), 2) AS pct_of_stays
FROM stays
GROUP BY status
ORDER BY total_stays DESC;

-- Q3.2: How do stay outcomes compare across hotels?
-- (hotel lives on bookings, so stays must be joined through bookings)
SELECT
    h.hotel_name,
    s.status,
    COUNT(*) AS total_stays
FROM stays s
JOIN bookings b ON b.booking_id = s.booking_id
JOIN hotels h   ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name, s.status
ORDER BY h.hotel_name, total_stays DESC;

-- Q3.3: What's the average stay duration (nights and hours) by status?
SELECT
    status,
    ROUND(AVG(nights_stayed), 2)      AS avg_nights_stayed,
    ROUND(AVG(stay_duration_hrs), 2)  AS avg_duration_hrs
FROM stays
GROUP BY status;

-- Q3.4: Which hotels have the highest share of non-completed stays
-- (No-show / Cancelled) relative to their total stays?
SELECT
    h.hotel_name,
    COUNT(*) AS total_stays,
    SUM(CASE WHEN s.status IN ('No-show','Cancelled') THEN 1 ELSE 0 END) AS problem_stays,
    ROUND(100 * SUM(CASE WHEN s.status IN ('No-show','Cancelled') THEN 1 ELSE 0 END) / COUNT(*), 2) AS problem_pct
FROM stays s
JOIN bookings b ON b.booking_id = s.booking_id
JOIN hotels h   ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name
ORDER BY problem_pct DESC;

-- Q3.5: How has the "Checked-out" completion rate trended by month?
SELECT
    DATE_FORMAT(s.check_in_date, '%Y-%m') AS stay_month,
    COUNT(*) AS total_stays,
    SUM(CASE WHEN s.status = 'Checked-out' THEN 1 ELSE 0 END) AS completed_stays,
    ROUND(100 * SUM(CASE WHEN s.status = 'Checked-out' THEN 1 ELSE 0 END) / COUNT(*), 2) AS completion_pct
FROM stays s
GROUP BY DATE_FORMAT(s.check_in_date, '%Y-%m')
ORDER BY stay_month;

-- Insight: Only 66.2% of stays end in "Checked-out" (2,117 of 3,200). No-shows (16.9%) slightly
-- outnumber Cancellations (15.0%), and In-progress stays are a small tail (1.9%). Combined,
-- No-show + Cancelled account for roughly 1 in 3 stays never completing -- a meaningful gap between
-- bookings made and stays fulfilled. Problem rates vary by hotel: the worst (StayPoint Kochi Palace,
-- ~39.2%) run notably higher than the best-performing hotels, pointing to hotel-level rather than
-- purely random causes.



-- #####################################################################
-- 4.4 Understand Staff and Room Performance
-- #####################################################################

-- Q4.1: How many stays has each staff member handled, and what's their rating?
SELECT
    st.staff_id,
    st.staff_name,
    st.department,
    st.rating,
    COUNT(s.stay_id) AS stays_handled
FROM staff st
LEFT JOIN stays s ON s.staff_id = st.staff_id
GROUP BY st.staff_id, st.staff_name, st.department, st.rating
ORDER BY stays_handled DESC;

-- Q4.2: How do stay outcomes differ by staff member?
SELECT
    st.staff_name,
    s.status,
    COUNT(*) AS total_stays
FROM stays s
JOIN staff st ON st.staff_id = s.staff_id
GROUP BY st.staff_name, s.status
ORDER BY st.staff_name, total_stays DESC;

-- Q4.3: Does average stay duration vary by staff member?
SELECT
    st.staff_name,
    COUNT(*)                          AS stays_handled,
    ROUND(AVG(s.nights_stayed), 2)    AS avg_nights_stayed,
    ROUND(AVG(s.stay_duration_hrs),2) AS avg_duration_hrs
FROM stays s
JOIN staff st ON st.staff_id = s.staff_id
GROUP BY st.staff_name
ORDER BY stays_handled DESC;

-- Q4.4: How is room usage distributed across room types?
SELECT
    r.room_type,
    COUNT(s.stay_id)                AS total_stays,
    ROUND(AVG(s.nights_stayed), 2)  AS avg_nights_stayed,
    ROUND(AVG(r.price_per_night),2) AS avg_price_per_night
FROM rooms r
LEFT JOIN stays s ON s.room_id = r.room_id
GROUP BY r.room_type
ORDER BY total_stays DESC;

-- Q4.5: Which individual rooms have the most stays and highest service requests?
SELECT
    r.room_id,
    r.room_type,
    h.hotel_name,
    COUNT(s.stay_id)               AS total_stays,
    ROUND(AVG(s.service_requests),2) AS avg_service_requests
FROM rooms r
JOIN hotels h ON h.hotel_id = r.hotel_id
LEFT JOIN stays s ON s.room_id = r.room_id
GROUP BY r.room_id, r.room_type, h.hotel_name
ORDER BY total_stays DESC
LIMIT 20;

-- Insight: Staff workload is fairly balanced at the top (busiest staff handle 56-59 stays each) and
-- workload doesn't track cleanly with rating -- e.g. one top-5 staff member by volume has a 4.82
-- rating while another has 3.15, so heavier caseloads aren't clearly linked to lower service quality.
-- By room type, Suites carry the highest average price per night (Rs 8,865) and Standard rooms see
-- the most stays (1,440), consistent with Standard being the volume driver and Suite the premium tier.



-- #####################################################################
-- 4.5 Identify Booking and Stay Problems
-- #####################################################################

-- Q5.1: Which bookings resulted in a cancellation or no-show?
SELECT
    b.booking_id,
    b.booking_channel,
    h.hotel_name,
    s.status,
    s.check_in_date
FROM bookings b
JOIN stays s  ON s.booking_id = b.booking_id
JOIN hotels h ON h.hotel_id = b.hotel_id
WHERE s.status IN ('No-show', 'Cancelled')
ORDER BY s.check_in_date DESC;

-- Q5.2: What's the overall distribution of stay statuses (problem patterns)?
SELECT
    status,
    COUNT(*) AS total_stays,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM stays), 2) AS pct_of_stays
FROM stays
GROUP BY status
ORDER BY total_stays DESC;

-- Q5.3: Do stays with high service-request counts show worse outcomes?
-- (bucket service_requests into low/medium/high and compare status mix)
SELECT
    CASE
        WHEN service_requests = 0 THEN 'None'
        WHEN service_requests BETWEEN 1 AND 2 THEN 'Low (1-2)'
        WHEN service_requests BETWEEN 3 AND 5 THEN 'Medium (3-5)'
        ELSE 'High (6+)'
    END AS service_request_bucket,
    status,
    COUNT(*) AS total_stays
FROM stays
GROUP BY service_request_bucket, status
ORDER BY service_request_bucket, total_stays DESC;

-- Q5.4: Which hotels experience the most booking/stay problems in absolute terms?
SELECT
    h.hotel_name,
    COUNT(*) AS problem_stays
FROM stays s
JOIN bookings b ON b.booking_id = s.booking_id
JOIN hotels h   ON h.hotel_id = b.hotel_id
WHERE s.status IN ('No-show', 'Cancelled')
GROUP BY h.hotel_name
ORDER BY problem_stays DESC;

-- Q5.5: Is there a relationship between booking channel and problem stays?
SELECT
    b.booking_channel,
    COUNT(*) AS total_stays,
    SUM(CASE WHEN s.status IN ('No-show','Cancelled') THEN 1 ELSE 0 END) AS problem_stays,
    ROUND(100 * SUM(CASE WHEN s.status IN ('No-show','Cancelled') THEN 1 ELSE 0 END) / COUNT(*), 2) AS problem_pct
FROM bookings b
JOIN stays s ON s.booking_id = b.booking_id
GROUP BY b.booking_channel
ORDER BY problem_pct DESC;

-- Insight: Service-request volume does not explain most incomplete stays -- essentially all
-- No-shows and Cancellations are recorded with zero service requests (they never reached the
-- service-delivery stage), so the "problem" signal sits upstream of in-stay service quality.
-- Problem-stay rates by channel are fairly close (29.8% Walk-in to 33.8% Mobile App), so channel
-- alone is a weak predictor; hotel-level differences (see 4.3) are the stronger pattern to
-- investigate further.



-- #####################################################################
-- SECTION 5: SQL CONCEPTS SHOWCASE
-- Explicit demonstrations of specific SQL techniques (INNER JOIN,
-- subqueries in WHERE, correlated subqueries, derived tables) that are
-- functionally present above but shown here individually and clearly
-- labeled for review.
-- #####################################################################

-- 5.1 Explicit INNER JOIN (2-table)
-- How many bookings have a matching guest record? (sanity/demo query;
-- should equal total bookings, since every booking has a valid guest_id)
SELECT COUNT(*) AS bookings_with_matching_guest
FROM bookings b
INNER JOIN guests g ON g.guest_id = b.guest_id;

-- 5.2 Explicit INNER JOIN (3-table chain)
-- Guest name, hotel name, and stay status for every completed stay
SELECT g.guest_name, h.hotel_name, s.status, s.check_in_date
FROM guests g
INNER JOIN bookings b ON b.guest_id = g.guest_id
INNER JOIN hotels h   ON h.hotel_id = b.hotel_id
INNER JOIN stays s    ON s.booking_id = b.booking_id
WHERE s.status = 'Checked-out'
LIMIT 20;

-- 5.3 Explicit LEFT JOIN
-- Every hotel, including any with zero bookings (LEFT JOIN preserves
-- hotels even if the bookings side has no match)
SELECT h.hotel_name, COUNT(b.booking_id) AS total_bookings
FROM hotels h
LEFT JOIN bookings b ON b.hotel_id = h.hotel_id
GROUP BY h.hotel_name
ORDER BY total_bookings ASC;

-- 5.4 Subquery in WHERE clause (non-correlated)
-- Guests whose total spend exceeds the average booking amount
-- (subquery computes a single scalar value used as a filter threshold)
SELECT g.guest_id, g.guest_name, g.guest_type
FROM guests g
WHERE g.guest_id IN (
    SELECT b.guest_id
    FROM bookings b
    GROUP BY b.guest_id
    HAVING SUM(b.total_amount) > (SELECT AVG(total_amount) FROM bookings)
)
ORDER BY g.guest_name;

-- 5.5 Correlated subquery
-- Hotels whose booking count is above the average booking count per hotel
-- (the inner subquery re-evaluates using each outer row's hotel_id)
SELECT h.hotel_id, h.hotel_name,
       (SELECT COUNT(*) FROM bookings b WHERE b.hotel_id = h.hotel_id) AS booking_count
FROM hotels h
WHERE (SELECT COUNT(*) FROM bookings b WHERE b.hotel_id = h.hotel_id)
      > (SELECT AVG(cnt) FROM (SELECT COUNT(*) AS cnt FROM bookings GROUP BY hotel_id) t)
ORDER BY booking_count DESC;

-- 5.6 Subquery in FROM clause (derived table)
-- Average nights_stayed per hotel, computed from a derived per-stay table
SELECT hotel_name, ROUND(AVG(nights_stayed), 2) AS avg_nights_stayed
FROM (
    SELECT h.hotel_name, s.nights_stayed
    FROM stays s
    JOIN bookings b ON b.booking_id = s.booking_id
    JOIN hotels h   ON h.hotel_id = b.hotel_id
) AS hotel_stay_nights
GROUP BY hotel_name
ORDER BY avg_nights_stayed DESC;
