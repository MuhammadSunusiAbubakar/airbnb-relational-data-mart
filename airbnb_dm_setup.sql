-- Step 1: Create the normalized database schema for the Airbnb Data Mart project
CREATE DATABASE IF NOT EXISTS airbnb_dm
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 2: Set the database as the active default schema
USE airbnb_dm;

-- Step 3: Confirm active schema selection
SELECT DATABASE() AS active_schema;
USE airbnb_dm;

-- 1. USERS: Core identity entity with recursive referral relationship
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    referred_by_id BIGINT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(25) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_referred_by 
        FOREIGN KEY (referred_by_id) REFERENCES users(user_id) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 2. GOVERNMENT_IDS: Verification documents linked 1:1 to users
CREATE TABLE IF NOT EXISTS government_ids (
    id_document_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    id_type ENUM('Passport', 'National ID', 'Drivers License') NOT NULL,
    id_number VARCHAR(100) NOT NULL,
    verification_status ENUM('Pending', 'Verified', 'Rejected') DEFAULT 'Pending',
    verified_at TIMESTAMP NULL,
    CONSTRAINT fk_gov_ids_user 
        FOREIGN KEY (user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 3. SOCIAL_CONNECTIONS: External social platform links
CREATE TABLE IF NOT EXISTS social_connections (
    connection_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    platform_name ENUM('Facebook', 'Google', 'Apple', 'LinkedIn') NOT NULL,
    external_id VARCHAR(120) NOT NULL,
    linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_social_user 
        FOREIGN KEY (user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_user_platform UNIQUE (user_id, platform_name)
) ENGINE=InnoDB;

-- 4. GUEST_PROFILES: Specific guest preferences and profile data
CREATE TABLE IF NOT EXISTS guest_profiles (
    guest_profile_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    preferred_currency CHAR(3) DEFAULT 'USD',
    preferred_language VARCHAR(30) DEFAULT 'English',
    emergency_contact_phone VARCHAR(25) NULL,
    CONSTRAINT fk_guest_user 
        FOREIGN KEY (user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. HOST_PROFILES: Verified host attributes and banking details
CREATE TABLE IF NOT EXISTS host_profiles (
    host_profile_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    is_superhost BOOLEAN DEFAULT FALSE,
    bank_account_iban VARCHAR(34) NOT NULL,
    response_rate_pct DECIMAL(5,2) DEFAULT 100.00,
    CONSTRAINT fk_host_user 
        FOREIGN KEY (user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6. PROPERTY_CATEGORIES: Accommodation taxonomy with recursive parent category
CREATE TABLE IF NOT EXISTS property_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT NULL,
    category_name VARCHAR(60) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    CONSTRAINT fk_categories_parent 
        FOREIGN KEY (parent_category_id) REFERENCES property_categories(category_id) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Verification check
SHOW TABLES;
USE airbnb_dm;

-- 7. LISTINGS: Core property accommodation entity
CREATE TABLE IF NOT EXISTS listings (
    listing_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_profile_id BIGINT NOT NULL,
    category_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NULL,
    room_type ENUM('Entire place', 'Private room', 'Shared room', 'Hotel room') NOT NULL,
    city VARCHAR(80) NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'US',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listings_host 
        FOREIGN KEY (host_profile_id) REFERENCES host_profiles(host_profile_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_listings_category 
        FOREIGN KEY (category_id) REFERENCES property_categories(category_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. LISTING_SPECIFICATIONS: Physical architectural details (1:1 with listing)
CREATE TABLE IF NOT EXISTS listing_specifications (
    spec_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL UNIQUE,
    max_guests INT NOT NULL DEFAULT 1,
    bedrooms_count INT NOT NULL DEFAULT 1,
    beds_count INT NOT NULL DEFAULT 1,
    bathrooms_count DECIMAL(3, 1) NOT NULL DEFAULT 1.0,
    CONSTRAINT fk_specs_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_max_guests CHECK (max_guests > 0)
) ENGINE=InnoDB;

-- 9. AMENITIES: Lookup master table for features (Wi-Fi, Kitchen, Pool, etc.)
CREATE TABLE IF NOT EXISTS amenities (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE,
    category ENUM('Basic', 'Safety', 'Luxury', 'Family') NOT NULL
) ENGINE=InnoDB;

-- 10. LISTING_AMENITIES: Composite join entity resolving M:N relationship
CREATE TABLE IF NOT EXISTS listing_amenities (
    listing_id BIGINT NOT NULL,
    amenity_id INT NOT NULL,
    PRIMARY KEY (listing_id, amenity_id),
    CONSTRAINT fk_la_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_la_amenity 
        FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 11. LISTING_PHOTOS: Multimedia catalog for listings
CREATE TABLE IF NOT EXISTS listing_photos (
    photo_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    photo_url VARCHAR(255) NOT NULL,
    display_order INT NOT NULL DEFAULT 1,
    is_primary BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_photos_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 12. CO_HOSTS: Secondary managers authorized by the host for a listing
CREATE TABLE IF NOT EXISTS co_hosts (
    co_host_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    can_manage_calendar BOOLEAN DEFAULT TRUE,
    can_manage_pricing BOOLEAN DEFAULT FALSE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cohosts_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cohosts_user 
        FOREIGN KEY (user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_listing_cohost UNIQUE (listing_id, user_id)
) ENGINE=InnoDB;

-- Verify total tables created so far (should display 12 tables)
SHOW TABLES;
USE airbnb_dm;

-- 13. AVAILABILITY_CALENDAR: Atomic daily availability ledger per listing
CREATE TABLE IF NOT EXISTS availability_calendar (
    calendar_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    calendar_date DATE NOT NULL,
    status ENUM('Available', 'Reserved', 'Blocked') DEFAULT 'Available',
    price_override DECIMAL(10, 2) NULL,
    CONSTRAINT fk_cal_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_listing_date UNIQUE (listing_id, calendar_date)
) ENGINE=InnoDB;

-- 14. PRICING_RULES: Base nightly rate, cleaning charges, and extra guest fees
CREATE TABLE IF NOT EXISTS pricing_rules (
    rule_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL UNIQUE,
    base_nightly_price DECIMAL(10, 2) NOT NULL,
    weekend_price DECIMAL(10, 2) NULL,
    cleaning_fee DECIMAL(10, 2) DEFAULT 0.00,
    security_deposit DECIMAL(10, 2) DEFAULT 0.00,
    extra_guest_fee DECIMAL(10, 2) DEFAULT 0.00,
    CONSTRAINT fk_pricing_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_base_price CHECK (base_nightly_price > 0)
) ENGINE=InnoDB;

-- 15. PROMOTIONS_DISCOUNTS: Long-term stay and promotional discounts
CREATE TABLE IF NOT EXISTS promotions_discounts (
    discount_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    discount_type ENUM('Weekly', 'Monthly', 'EarlyBird', 'LastMinute') NOT NULL,
    discount_pct DECIMAL(5, 2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    CONSTRAINT fk_promo_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_discount_pct CHECK (discount_pct BETWEEN 1.00 AND 90.00),
    CONSTRAINT chk_discount_dates CHECK (valid_to >= valid_from)
) ENGINE=InnoDB;

-- Verify total count of tables (now 15 tables)
SHOW TABLES;
USE airbnb_dm;

-- 16. BOOKINGS: Core transactional ternary entity (Guest + Host + Listing)
CREATE TABLE IF NOT EXISTS bookings (
    booking_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    guest_profile_id BIGINT NOT NULL,
    host_profile_id BIGINT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_guests INT NOT NULL DEFAULT 1,
    booking_status ENUM('Pending', 'Confirmed', 'Cancelled', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bookings_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_guest 
        FOREIGN KEY (guest_profile_id) REFERENCES guest_profiles(guest_profile_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_host 
        FOREIGN KEY (host_profile_id) REFERENCES host_profiles(host_profile_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_booking_dates CHECK (check_out_date > check_in_date)
) ENGINE=InnoDB;

-- 17. BOOKING_FINANCIAL_BREAKDOWNS: Platform commissions (6-12% guest, 3% host) & escrow ledger
CREATE TABLE IF NOT EXISTS booking_financial_breakdowns (
    financial_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE,
    base_subtotal DECIMAL(10, 2) NOT NULL,
    cleaning_fee DECIMAL(10, 2) DEFAULT 0.00,
    guest_service_fee DECIMAL(10, 2) NOT NULL,
    host_service_fee DECIMAL(10, 2) NOT NULL,
    total_guest_paid DECIMAL(10, 2) NOT NULL,
    net_host_earnings DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_financial_booking 
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 18. PAYMENT_TRANSACTIONS: Multi-channel guest payment processing records
CREATE TABLE IF NOT EXISTS payment_transactions (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Apple Pay', 'Google Pay') NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL,
    payment_status ENUM('Initiated', 'Completed', 'Failed', 'Refunded') DEFAULT 'Initiated',
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_booking 
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 19. HOST_PAYOUTS: Escrow release ledger (automated release 24 hours post check-in)
CREATE TABLE IF NOT EXISTS host_payouts (
    payout_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE,
    host_profile_id BIGINT NOT NULL,
    payout_amount DECIMAL(10, 2) NOT NULL,
    scheduled_release_time DATETIME NOT NULL,
    payout_status ENUM('Scheduled', 'Processing', 'Paid', 'Withheld') DEFAULT 'Scheduled',
    released_at DATETIME NULL,
    CONSTRAINT fk_payouts_booking 
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payouts_host 
        FOREIGN KEY (host_profile_id) REFERENCES host_profiles(host_profile_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Verify total table count (now 19 tables)
SHOW TABLES;
USE airbnb_dm;

-- 20. REVIEWS: Double-blind ratings & feedback ledger (14-day mutual blind window)
CREATE TABLE IF NOT EXISTS reviews (
    review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    reviewer_user_id BIGINT NOT NULL,
    cleanliness_rating TINYINT NOT NULL,
    accuracy_rating TINYINT NOT NULL,
    communication_rating TINYINT NOT NULL,
    location_rating TINYINT NOT NULL,
    overall_rating DECIMAL(2, 1) NOT NULL,
    review_comments TEXT NOT NULL,
    is_visible BOOLEAN DEFAULT FALSE,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_booking 
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewer 
        FOREIGN KEY (reviewer_user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cleanliness CHECK (cleanliness_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_accuracy CHECK (accuracy_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_communication CHECK (communication_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_location CHECK (location_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_overall CHECK (overall_rating BETWEEN 1.0 AND 5.0)
) ENGINE=InnoDB;

-- 21. MESSAGE_THREADS: In-platform communication audit trail
CREATE TABLE IF NOT EXISTS message_threads (
    message_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    sender_user_id BIGINT NOT NULL,
    receiver_user_id BIGINT NOT NULL,
    message_body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msg_listing 
        FOREIGN KEY (listing_id) REFERENCES listings(listing_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_msg_sender 
        FOREIGN KEY (sender_user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_msg_receiver 
        FOREIGN KEY (receiver_user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 22. DISPUTE_CLAIMS: Ternary administrative arbitration entity (Booking + Claimant + Admin)
CREATE TABLE IF NOT EXISTS dispute_claims (
    dispute_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    claimant_user_id BIGINT NOT NULL,
    admin_user_id BIGINT NOT NULL,
    disputed_amount DECIMAL(10, 2) NOT NULL,
    claim_reason TEXT NOT NULL,
    resolution_status ENUM('Open', 'Under Review', 'Refund Approved', 'Dismissed') DEFAULT 'Open',
    filed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    CONSTRAINT fk_dispute_booking 
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_dispute_claimant 
        FOREIGN KEY (claimant_user_id) REFERENCES users(user_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_dispute_admin 
        FOREIGN KEY (admin_user_id) REFERENCES users(user_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_disputed_amount CHECK (disputed_amount > 0)
) ENGINE=InnoDB;

-- Final Schema Verification: Ensure all 22 entities are present
SHOW TABLES;


USE airbnb_dm;

-- Audit 1: Total Entity Count & Storage Engine Confirmation
SELECT 
    table_name AS entity_name,
    engine,
    table_rows,
    table_collation
FROM information_schema.tables
WHERE table_schema = 'airbnb_dm'
ORDER BY table_name ASC;

-- Audit 2: High-Level Cluster Entity Count Verification
SELECT 
    COUNT(*) AS total_tables_created,
    CASE 
        WHEN COUNT(*) = 22 THEN 'PASS: All 22 Entities Successfully Registered'
        ELSE 'FAIL: Table count mismatch'
    END AS cluster_status
FROM information_schema.tables
WHERE table_schema = 'airbnb_dm';

-- Audit 3: Referential Integrity & Foreign Key Count Audit
SELECT 
    table_name AS child_table,
    constraint_name,
    referenced_table_name AS parent_table
FROM information_schema.key_column_usage
WHERE table_schema = 'airbnb_dm'
  AND referenced_table_name IS NOT NULL
ORDER BY parent_table ASC, child_table ASC;
USE airbnb_dm;

-- Temporarily bypass foreign key checks to safely refresh seed data
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE co_hosts;
TRUNCATE TABLE listing_photos;
TRUNCATE TABLE listing_amenities;
TRUNCATE TABLE listing_specifications;
TRUNCATE TABLE listings;
TRUNCATE TABLE amenities;
TRUNCATE TABLE host_profiles;
TRUNCATE TABLE guest_profiles;
TRUNCATE TABLE property_categories;
TRUNCATE TABLE social_connections;
TRUNCATE TABLE government_ids;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. Insert 25 Users
INSERT INTO users (user_id, referred_by_id, first_name, last_name, email, phone_number) VALUES
(1, NULL, 'Amina', 'Bello', 'amina.bello@example.com', '+2348031110001'),
(2, 1, 'Chidi', 'Okeke', 'chidi.okeke@example.com', '+2348031110002'),
(3, 1, 'Zainab', 'Danjuma', 'zainab.danjuma@example.com', '+2348031110003'),
(4, 2, 'Tunde', 'Bakare', 'tunde.bakare@example.com', '+2348031110004'),
(5, NULL, 'Emeka', 'Nwosu', 'emeka.nwosu@example.com', '+2348031110005'),
(6, 5, 'Fatima', 'Aliyu', 'fatima.aliyu@example.com', '+2348031110006'),
(7, NULL, 'Kelechi', 'Eze', 'kelechi.eze@example.com', '+2348031110007'),
(8, 7, 'Balarabe', 'Musa', 'balarabe.musa@example.com', '+2348031110008'),
(9, 7, 'Ngozi', 'Adeyemi', 'ngozi.adeyemi@example.com', '+2348031110009'),
(10, NULL, 'Ibrahim', 'Garba', 'ibrahim.garba@example.com', '+2348031110010'),
(11, 10, 'Halima', 'Shehu', 'halima.shehu@example.com', '+2348031110011'),
(12, NULL, 'Olumide', 'Fashola', 'olumide.fashola@example.com', '+2348031110012'),
(13, 12, 'Hauwa', 'Mohammed', 'hauwa.mohammed@example.com', '+2348031110013'),
(14, NULL, 'David', 'Mark', 'david.mark@example.com', '+2348031110014'),
(15, 14, 'Blessing', 'Effiong', 'blessing.effiong@example.com', '+2348031110015'),
(16, NULL, 'Suleiman', 'Abba', 'suleiman.abba@example.com', '+2348031110016'),
(17, 16, 'Grace', 'Okafor', 'grace.okafor@example.com', '+2348031110017'),
(18, 16, 'Umar', 'Faruk', 'umar.faruk@example.com', '+2348031110018'),
(19, NULL, 'Peter', 'Obi', 'peter.obi@example.com', '+2348031110019'),
(20, 19, 'Maryam', 'Sani', 'maryam.sani@example.com', '+2348031110020'),
(21, NULL, 'Samuel', 'Akpabio', 'samuel.akpabio@example.com', '+2348031110021'),
(22, 21, 'Rukayya', 'Jibril', 'rukayya.jibril@example.com', '+2348031110022'),
(23, NULL, 'Yusuf', 'Maitama', 'yusuf.maitama@example.com', '+2348031110023'),
(24, 23, 'Yetunde', 'Balogun', 'yetunde.balogun@example.com', '+2348031110024'),
(25, NULL, 'Kabiru', 'Gwandu', 'kabiru.gwandu@example.com', '+2348031110025');

-- 2. Insert 22 Government IDs
INSERT INTO government_ids (user_id, id_type, id_number, verification_status, verified_at) VALUES
(1, 'Passport', 'A1024001', 'Verified', '2026-01-10 10:00:00'),
(2, 'National ID', 'NIN892011', 'Verified', '2026-01-12 11:30:00'),
(3, 'Drivers License', 'DL490211', 'Verified', '2026-01-15 09:15:00'),
(4, 'Passport', 'A1024004', 'Pending', NULL),
(5, 'National ID', 'NIN892015', 'Verified', '2026-01-18 14:00:00'),
(6, 'Passport', 'A1024006', 'Verified', '2026-01-20 16:20:00'),
(7, 'Drivers License', 'DL490217', 'Verified', '2026-01-22 13:45:00'),
(8, 'National ID', 'NIN892018', 'Rejected', NULL),
(9, 'Passport', 'A1024009', 'Verified', '2026-01-25 15:10:00'),
(10, 'National ID', 'NIN892020', 'Verified', '2026-02-01 10:05:00'),
(11, 'Passport', 'A1024011', 'Verified', '2026-02-03 11:40:00'),
(12, 'Drivers License', 'DL490222', 'Verified', '2026-02-05 12:00:00'),
(13, 'National ID', 'NIN892023', 'Pending', NULL),
(14, 'Passport', 'A1024014', 'Verified', '2026-02-08 09:50:00'),
(15, 'Passport', 'A1024015', 'Verified', '2026-02-10 17:30:00'),
(16, 'National ID', 'NIN892026', 'Verified', '2026-02-12 10:15:00'),
(17, 'Drivers License', 'DL490227', 'Verified', '2026-02-15 14:20:00'),
(18, 'Passport', 'A1024018', 'Verified', '2026-02-18 16:00:00'),
(19, 'National ID', 'NIN892029', 'Verified', '2026-02-20 11:10:00'),
(20, 'Passport', 'A1024020', 'Verified', '2026-02-22 13:00:00'),
(21, 'National ID', 'NIN892031', 'Verified', '2026-02-25 15:45:00'),
(22, 'Drivers License', 'DL490232', 'Verified', '2026-02-28 08:30:00');

-- 3. Insert 22 Social Connections
INSERT INTO social_connections (user_id, platform_name, external_id) VALUES
(1, 'Google', 'google_uid_101'),
(1, 'LinkedIn', 'linkedin_uid_101'),
(2, 'Facebook', 'fb_uid_102'),
(3, 'Apple', 'apple_uid_103'),
(4, 'Google', 'google_uid_104'),
(5, 'LinkedIn', 'linkedin_uid_105'),
(6, 'Facebook', 'fb_uid_106'),
(7, 'Google', 'google_uid_107'),
(8, 'Apple', 'apple_uid_108'),
(9, 'LinkedIn', 'linkedin_uid_109'),
(10, 'Google', 'google_uid_110'),
(11, 'Facebook', 'fb_uid_111'),
(12, 'Apple', 'apple_uid_112'),
(13, 'LinkedIn', 'linkedin_uid_113'),
(14, 'Google', 'google_uid_114'),
(15, 'Facebook', 'fb_uid_115'),
(16, 'LinkedIn', 'linkedin_uid_116'),
(17, 'Google', 'google_uid_117'),
(18, 'Apple', 'apple_uid_118'),
(19, 'Facebook', 'fb_uid_119'),
(20, 'LinkedIn', 'linkedin_uid_120'),
(21, 'Google', 'google_uid_121');

-- 4. Insert 20 Property Categories
INSERT INTO property_categories (category_id, parent_category_id, category_name, description) VALUES
(1, NULL, 'Apartments', 'Self-contained residential housing units'),
(2, NULL, 'Houses', 'Standalone residential private homes'),
(3, NULL, 'Unique Stays', 'Special architectural lodgings and retreats'),
(4, NULL, 'Bed & Breakfast', 'Hospitality establishments offering morning dining'),
(5, 1, 'Loft', 'Open-concept space converted from commercial structures'),
(6, 1, 'Serviced Apartment', 'Fully furnished units including regular cleaning'),
(7, 1, 'Penthouse', 'Luxury suite situated on top floors'),
(8, 2, 'Villa', 'Expansive upscale private residence with grounds'),
(9, 2, 'Townhouse', 'Multi-floor terraced urban home'),
(10, 2, 'Cottage', 'Cozy countryside or coastal lodging'),
(11, 2, 'Bungalow', 'Single-story residential dwelling'),
(12, 3, 'Treehouse', 'Elevated forest shelter built around trees'),
(13, 3, 'Houseboat', 'Moored residential aquatic dwelling'),
(14, 3, 'Yurt', 'Circular tent shelter traditionally used by nomads'),
(15, 3, 'Cabin', 'Rustic wooden dwelling set in secluded nature'),
(16, 3, 'Dome House', 'Geodesic energy-efficient dome structure'),
(17, 4, 'Farm Stay', 'Lodging situated on an active working rural farm'),
(18, 4, 'Boutique Inn', 'Intimate hospitality lodging with custom styling'),
(19, 1, 'Studio', 'Single room integrating bedroom and kitchenette'),
(20, 2, 'Duplex', 'Two-unit residential structure sharing a central wall');

-- 5. Insert 20 Guest Profiles
INSERT INTO guest_profiles (guest_profile_id, user_id, preferred_currency, preferred_language, emergency_contact_phone) VALUES
(1, 1, 'USD', 'English', '+2348039990001'),
(2, 2, 'EUR', 'English', '+2348039990002'),
(3, 3, 'GBP', 'Hausa', '+2348039990003'),
(4, 4, 'USD', 'Yoruba', '+2348039990004'),
(5, 5, 'NGN', 'Igbo', '+2348039990005'),
(6, 6, 'USD', 'English', '+2348039990006'),
(7, 7, 'EUR', 'French', '+2348039990007'),
(8, 8, 'NGN', 'Hausa', '+2348039990008'),
(9, 9, 'USD', 'English', '+2348039990009'),
(10, 10, 'GBP', 'English', '+2348039990010'),
(11, 11, 'NGN', 'Hausa', '+2348039990011'),
(12, 12, 'USD', 'Yoruba', '+2348039990012'),
(13, 13, 'EUR', 'English', '+2348039990013'),
(14, 14, 'USD', 'English', '+2348039990014'),
(15, 15, 'NGN', 'English', '+2348039990015'),
(16, 16, 'USD', 'Hausa', '+2348039990016'),
(17, 17, 'EUR', 'Igbo', '+2348039990017'),
(18, 18, 'GBP', 'English', '+2348039990018'),
(19, 19, 'USD', 'English', '+2348039990019'),
(20, 20, 'NGN', 'Hausa', '+2348039990020');

-- 6. Insert 20 Host Profiles
INSERT INTO host_profiles (host_profile_id, user_id, is_superhost, bank_account_iban, response_rate_pct) VALUES
(1, 1, TRUE, 'GB29NWBK60161331926819', 99.50),
(2, 2, FALSE, 'DE89370400440532013000', 92.00),
(3, 3, TRUE, 'FR1420041010050500013M02606', 100.00),
(4, 4, FALSE, 'NG1200010000001234567801', 88.50),
(5, 5, TRUE, 'GB33BUKB20201555555555', 98.00),
(6, 6, FALSE, 'NG1200020000001234567802', 91.00),
(7, 7, TRUE, 'DE44500105175407324931', 97.50),
(8, 8, FALSE, 'NG1200030000001234567803', 85.00),
(9, 9, TRUE, 'GB11BARC20000012345678', 100.00),
(10, 10, FALSE, 'NG1200040000001234567804', 94.00),
(11, 11, TRUE, 'FR7630006000011234567890189', 99.00),
(12, 12, FALSE, 'DE22100110012345678901', 90.00),
(13, 13, TRUE, 'NG1200050000001234567805', 96.50),
(14, 14, FALSE, 'GB99MIDL40051512345678', 89.00),
(15, 15, TRUE, 'NG1200060000001234567806', 98.50),
(16, 16, FALSE, 'DE33500700100123456789', 93.00),
(17, 17, TRUE, 'NG1200070000001234567807', 100.00),
(18, 18, FALSE, 'GB55LOYD30908912345678', 87.00),
(19, 19, TRUE, 'NG1200080000001234567808', 97.00),
(20, 20, FALSE, 'DE66500800000123456789', 91.50);

-- 7. Insert 20 Amenities
INSERT INTO amenities (amenity_id, name, category) VALUES
(1, 'High-Speed Wi-Fi', 'Basic'),
(2, 'Air Conditioning (HVAC)', 'Basic'),
(3, 'Fully Equipped Kitchen', 'Basic'),
(4, 'Washing Machine', 'Basic'),
(5, 'Free Dedicated Parking', 'Basic'),
(6, 'Smoke Detector', 'Safety'),
(7, 'Carbon Monoxide Alarm', 'Safety'),
(8, 'First Aid Medical Kit', 'Safety'),
(9, 'Fire Extinguisher', 'Safety'),
(10, 'Private Swimming Pool', 'Luxury'),
(11, 'Hot Tub / Jacuzzi', 'Luxury'),
(12, 'Private Sauna', 'Luxury'),
(13, 'Rooftop Terrace', 'Luxury'),
(14, 'EV Charger', 'Luxury'),
(15, 'Crib & Pack-n-Play', 'Family'),
(16, 'High Chair', 'Family'),
(17, 'Children Books & Toys', 'Family'),
(18, 'Baby Safety Gates', 'Family'),
(19, 'Dedicated Workspace Desk', 'Basic'),
(20, 'Waterfront Access', 'Luxury');

-- 8. Insert 20 Listings
INSERT INTO listings (listing_id, host_profile_id, category_id, title, description, room_type, city, country_code, latitude, longitude, is_active) VALUES
(1, 1, 1, 'Central Skyline Apartment', 'Modern flat in city core', 'Entire place', 'Abuja', 'NG', 9.076500, 7.398600, TRUE),
(2, 2, 5, 'Industrial Artist Loft', 'High ceilings and brick walls', 'Entire place', 'Lagos', 'NG', 6.524400, 3.379200, TRUE),
(3, 3, 8, 'Luxury Hillside Villa', 'Private pool and panoramic views', 'Entire place', 'Kano', 'NG', 12.002200, 8.592000, TRUE),
(4, 4, 2, 'Suburban Family Home', 'Spacious yard in quiet neighborhood', 'Entire place', 'Gombe', 'NG', 10.289700, 11.167300, TRUE),
(5, 5, 19, 'Minimalist Executive Studio', 'Ideal for business trips and nomads', 'Entire place', 'Abuja', 'NG', 9.057900, 7.495100, TRUE),
(6, 6, 6, 'Serviced Diplomatic Suite', 'Daily housekeeping and concierge', 'Entire place', 'Abuja', 'NG', 9.082000, 7.489000, TRUE),
(7, 7, 7, 'Oceanfront Penthouse', 'Top-floor views over the coastline', 'Entire place', 'Lagos', 'NG', 6.428100, 3.421900, TRUE),
(8, 8, 9, 'Classic Victoria Townhouse', 'Multi-level home with garden patio', 'Entire place', 'London', 'GB', 51.507400, -0.127800, TRUE),
(9, 9, 10, 'Peaceful Coastal Cottage', 'Short walk to sandy beaches', 'Entire place', 'Brighton', 'GB', 50.822500, -0.137200, TRUE),
(10, 10, 15, 'Pine Mountain Log Cabin', 'Cozy fireplace surrounded by woods', 'Entire place', 'Munich', 'DE', 48.135100, 11.582000, TRUE),
(11, 11, 12, 'Canopy Eco Treehouse', 'Rustic escape among forest trees', 'Entire place', 'Freiburg', 'DE', 47.999000, 7.842100, TRUE),
(12, 12, 13, 'River Thames Houseboat', 'Floating home with scenic deck', 'Entire place', 'London', 'GB', 51.485100, -0.174900, TRUE),
(13, 13, 14, 'Desert Oasis Stargazing Yurt', 'Clear skylight dome for night views', 'Entire place', 'Kano', 'NG', 11.996100, 8.516700, TRUE),
(14, 14, 16, 'Geodesic Eco Dome', 'Off-grid sustainable stay', 'Entire place', 'Berlin', 'DE', 52.520000, 13.405000, TRUE),
(15, 15, 17, 'Heritage Farm Stay Retreat', 'Fresh breakfast and scenic pastures', 'Entire place', 'Bauchi', 'NG', 10.315800, 9.844200, TRUE),
(16, 16, 18, 'Historic Boutique Inn Room', 'Period decor with modern amenities', 'Private room', 'Paris', 'FR', 48.856600, 2.352200, TRUE),
(17, 17, 20, 'Sunny Garden Duplex', 'Private entrance with small patio', 'Entire place', 'Gombe', 'NG', 10.279000, 11.155000, TRUE),
(18, 18, 11, 'Palm Grove Bungalow', 'Single-story private tropical home', 'Entire place', 'Lagos', 'NG', 6.447400, 3.472300, TRUE),
(19, 19, 1, 'Arts District Room', 'Cozy bedroom in shared creative flat', 'Private room', 'Berlin', 'DE', 52.500000, 13.380000, TRUE),
(20, 20, 2, 'University Campus Flat', 'Walking distance to faculties', 'Private room', 'Munich', 'DE', 48.150000, 11.580000, TRUE);

-- 9. Insert 20 Listing Specifications
INSERT INTO listing_specifications (spec_id, listing_id, max_guests, bedrooms_count, beds_count, bathrooms_count) VALUES
(1, 1, 4, 2, 2, 2.0),
(2, 2, 2, 1, 1, 1.5),
(3, 3, 10, 5, 6, 5.5),
(4, 4, 6, 3, 4, 2.5),
(5, 5, 2, 1, 1, 1.0),
(6, 6, 4, 2, 2, 2.0),
(7, 7, 8, 4, 4, 4.0),
(8, 8, 6, 3, 3, 3.0),
(9, 9, 4, 2, 3, 1.5),
(10, 10, 5, 2, 3, 1.0),
(11, 11, 2, 1, 1, 1.0),
(12, 12, 3, 1, 2, 1.0),
(13, 13, 2, 1, 1, 1.0),
(14, 14, 4, 2, 2, 1.5),
(15, 15, 6, 3, 4, 2.0),
(16, 16, 2, 1, 1, 1.0),
(17, 17, 4, 2, 2, 2.0),
(18, 18, 4, 2, 2, 2.0),
(19, 19, 1, 1, 1, 1.0),
(20, 20, 2, 1, 1, 1.0);

-- 10. Insert 24 Listing Amenities joins
INSERT INTO listing_amenities (listing_id, amenity_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 19),
(2, 1), (2, 2), (2, 19),
(3, 1), (3, 2), (3, 3), (3, 10), (3, 11), (3, 14),
(4, 1), (4, 3), (4, 4), (4, 5), (4, 15),
(5, 1), (5, 2), (5, 19),
(7, 1), (7, 10), (7, 13);

-- 11. Insert 20 Listing Photos
INSERT INTO listing_photos (photo_id, listing_id, photo_url, display_order, is_primary) VALUES
(1, 1, 'https://images.airbnb-dm.test/listing1_main.jpg', 1, TRUE),
(2, 2, 'https://images.airbnb-dm.test/listing2_main.jpg', 1, TRUE),
(3, 3, 'https://images.airbnb-dm.test/listing3_main.jpg', 1, TRUE),
(4, 4, 'https://images.airbnb-dm.test/listing4_main.jpg', 1, TRUE),
(5, 5, 'https://images.airbnb-dm.test/listing5_main.jpg', 1, TRUE),
(6, 6, 'https://images.airbnb-dm.test/listing6_main.jpg', 1, TRUE),
(7, 7, 'https://images.airbnb-dm.test/listing7_main.jpg', 1, TRUE),
(8, 8, 'https://images.airbnb-dm.test/listing8_main.jpg', 1, TRUE),
(9, 9, 'https://images.airbnb-dm.test/listing9_main.jpg', 1, TRUE),
(10, 10, 'https://images.airbnb-dm.test/listing10_main.jpg', 1, TRUE),
(11, 11, 'https://images.airbnb-dm.test/listing11_main.jpg', 1, TRUE),
(12, 12, 'https://images.airbnb-dm.test/listing12_main.jpg', 1, TRUE),
(13, 13, 'https://images.airbnb-dm.test/listing13_main.jpg', 1, TRUE),
(14, 14, 'https://images.airbnb-dm.test/listing14_main.jpg', 1, TRUE),
(15, 15, 'https://images.airbnb-dm.test/listing15_main.jpg', 1, TRUE),
(16, 16, 'https://images.airbnb-dm.test/listing16_main.jpg', 1, TRUE),
(17, 17, 'https://images.airbnb-dm.test/listing17_main.jpg', 1, TRUE),
(18, 18, 'https://images.airbnb-dm.test/listing18_main.jpg', 1, TRUE),
(19, 19, 'https://images.airbnb-dm.test/listing19_main.jpg', 1, TRUE),
(20, 20, 'https://images.airbnb-dm.test/listing20_main.jpg', 1, TRUE);

-- 12. Insert 20 Co-Hosts
INSERT INTO co_hosts (co_host_id, listing_id, user_id, can_manage_calendar, can_manage_pricing) VALUES
(1, 1, 2, TRUE, TRUE),
(2, 2, 3, TRUE, FALSE),
(3, 3, 4, TRUE, TRUE),
(4, 4, 5, TRUE, FALSE),
(5, 5, 6, TRUE, TRUE),
(6, 6, 7, TRUE, FALSE),
(7, 7, 8, TRUE, TRUE),
(8, 8, 9, TRUE, FALSE),
(9, 9, 10, TRUE, TRUE),
(10, 10, 11, TRUE, FALSE),
(11, 11, 12, TRUE, TRUE),
(12, 12, 13, TRUE, FALSE),
(13, 13, 14, TRUE, TRUE),
(14, 14, 15, TRUE, FALSE),
(15, 15, 16, TRUE, TRUE),
(16, 16, 17, TRUE, FALSE),
(17, 17, 18, TRUE, TRUE),
(18, 18, 19, TRUE, FALSE),
(19, 19, 20, TRUE, TRUE),
(20, 20, 1, TRUE, FALSE);

-- Summary row count check for all 12 tables
SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL
SELECT 'government_ids', COUNT(*) FROM government_ids
UNION ALL
SELECT 'social_connections', COUNT(*) FROM social_connections
UNION ALL
SELECT 'property_categories', COUNT(*) FROM property_categories
UNION ALL
SELECT 'guest_profiles', COUNT(*) FROM guest_profiles
UNION ALL
SELECT 'host_profiles', COUNT(*) FROM host_profiles
UNION ALL
SELECT 'amenities', COUNT(*) FROM amenities
UNION ALL
SELECT 'listings', COUNT(*) FROM listings
UNION ALL
SELECT 'listing_specifications', COUNT(*) FROM listing_specifications
UNION ALL
SELECT 'listing_amenities', COUNT(*) FROM listing_amenities
UNION ALL
SELECT 'listing_photos', COUNT(*) FROM listing_photos
UNION ALL
SELECT 'co_hosts', COUNT(*) FROM co_hosts;
USE airbnb_dm;

-- Temporarily bypass FK checks to reset Clusters 3 & 4 cleanly without residual collisions
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE host_payouts;
TRUNCATE TABLE payment_transactions;
TRUNCATE TABLE booking_financial_breakdowns;
TRUNCATE TABLE bookings;
TRUNCATE TABLE promotions_discounts;
TRUNCATE TABLE pricing_rules;
TRUNCATE TABLE availability_calendar;

SET FOREIGN_KEY_CHECKS = 1;

-- ====================================================================
-- CLUSTER 3: SCHEDULING, PRICING RULES & PROMOTIONS (20 ROWS EACH)
-- ====================================================================

-- 1. Availability Calendar (20 slots across listings 1 to 16)
INSERT INTO availability_calendar (calendar_id, listing_id, calendar_date, status, price_override) VALUES
(1, 1, '2026-10-01', 'Available', NULL),
(2, 1, '2026-10-02', 'Available', NULL),
(3, 2, '2026-10-01', 'Reserved', NULL),
(4, 2, '2026-10-02', 'Reserved', NULL),
(5, 3, '2026-10-05', 'Available', 350.00),
(6, 3, '2026-10-06', 'Available', 350.00),
(7, 4, '2026-10-10', 'Available', NULL),
(8, 4, '2026-10-11', 'Blocked', NULL),
(9, 5, '2026-10-12', 'Available', NULL),
(10, 6, '2026-10-15', 'Available', 180.00),
(11, 7, '2026-10-20', 'Available', 450.00),
(12, 8, '2026-10-22', 'Reserved', NULL),
(13, 9, '2026-10-25', 'Available', NULL),
(14, 10, '2026-11-01', 'Available', 130.00),
(15, 11, '2026-11-05', 'Available', NULL),
(16, 12, '2026-11-10', 'Blocked', NULL),
(17, 13, '2026-11-12', 'Available', NULL),
(18, 14, '2026-11-15', 'Available', NULL),
(19, 15, '2026-11-20', 'Reserved', NULL),
(20, 16, '2026-11-25', 'Available', 95.00);

-- 2. Pricing Rules (1:1 with listings 1-20)
INSERT INTO pricing_rules (rule_id, listing_id, base_nightly_price, weekend_price, cleaning_fee, security_deposit, extra_guest_fee) VALUES
(1, 1, 120.00, 140.00, 25.00, 100.00, 15.00),
(2, 2, 95.00, 110.00, 20.00, 50.00, 10.00),
(3, 3, 320.00, 380.00, 60.00, 250.00, 30.00),
(4, 4, 150.00, 175.00, 35.00, 150.00, 20.00),
(5, 5, 80.00, 90.00, 15.00, 50.00, 10.00),
(6, 6, 160.00, 190.00, 40.00, 150.00, 25.00),
(7, 7, 400.00, 480.00, 80.00, 300.00, 40.00),
(8, 8, 220.00, 260.00, 50.00, 200.00, 25.00),
(9, 9, 110.00, 130.00, 25.00, 100.00, 15.00),
(10, 10, 125.00, 145.00, 30.00, 100.00, 15.00),
(11, 11, 105.00, 120.00, 20.00, 75.00, 10.00),
(12, 12, 135.00, 155.00, 30.00, 100.00, 20.00),
(13, 13, 90.00, 105.00, 20.00, 50.00, 10.00),
(14, 14, 115.00, 135.00, 25.00, 100.00, 15.00),
(15, 15, 140.00, 160.00, 35.00, 120.00, 20.00),
(16, 16, 85.00, 95.00, 15.00, 50.00, 10.00),
(17, 17, 130.00, 150.00, 30.00, 100.00, 15.00),
(18, 18, 145.00, 170.00, 35.00, 120.00, 20.00),
(19, 19, 65.00, 75.00, 10.00, 40.00, 0.00),
(20, 20, 70.00, 80.00, 15.00, 40.00, 0.00);

-- 3. Promotions & Discounts (20 rows)
INSERT INTO promotions_discounts (discount_id, listing_id, discount_type, discount_pct, valid_from, valid_to) VALUES
(1, 1, 'Weekly', 10.00, '2026-09-01', '2026-12-31'),
(2, 2, 'EarlyBird', 15.00, '2026-09-15', '2026-11-15'),
(3, 3, 'Monthly', 25.00, '2026-10-01', '2026-12-31'),
(4, 4, 'Weekly', 12.00, '2026-09-01', '2026-12-31'),
(5, 5, 'LastMinute', 20.00, '2026-10-01', '2026-10-31'),
(6, 6, 'Monthly', 20.00, '2026-10-01', '2027-01-31'),
(7, 7, 'Weekly', 10.00, '2026-09-15', '2026-12-15'),
(8, 8, 'EarlyBird', 15.00, '2026-10-01', '2026-11-30'),
(9, 9, 'Weekly', 8.00, '2026-09-01', '2026-12-31'),
(10, 10, 'LastMinute', 18.00, '2026-11-01', '2026-11-30'),
(11, 11, 'Weekly', 10.00, '2026-10-01', '2026-12-31'),
(12, 12, 'EarlyBird', 12.00, '2026-10-15', '2026-12-15'),
(13, 13, 'Weekly', 15.00, '2026-09-01', '2026-11-30'),
(14, 14, 'Monthly', 30.00, '2026-10-01', '2027-01-31'),
(15, 15, 'Weekly', 10.00, '2026-10-01', '2026-12-31'),
(16, 16, 'LastMinute', 15.00, '2026-11-15', '2026-12-15'),
(17, 17, 'Weekly', 10.00, '2026-09-01', '2026-12-31'),
(18, 18, 'Monthly', 22.00, '2026-10-01', '2026-12-31'),
(19, 19, 'EarlyBird', 10.00, '2026-09-15', '2026-11-15'),
(20, 20, 'Weekly', 5.00, '2026-10-01', '2026-12-31');

-- ====================================================================
-- CLUSTER 4: RESERVATIONS, FINANCIALS & PAYOUTS (20 ROWS EACH)
-- ====================================================================

-- 4. Bookings (Ternary join: Guest + Host + Listing)
INSERT INTO bookings (booking_id, listing_id, guest_profile_id, host_profile_id, check_in_date, check_out_date, total_guests, booking_status) VALUES
(1, 1, 1, 1, '2026-10-01', '2026-10-05', 2, 'Confirmed'),
(2, 2, 2, 2, '2026-10-03', '2026-10-07', 1, 'Completed'),
(3, 3, 3, 3, '2026-10-05', '2026-10-10', 4, 'Confirmed'),
(4, 4, 4, 4, '2026-10-08', '2026-10-12', 3, 'Confirmed'),
(5, 5, 5, 5, '2026-10-10', '2026-10-14', 1, 'Completed'),
(6, 6, 6, 6, '2026-10-12', '2026-10-16', 2, 'Confirmed'),
(7, 7, 7, 7, '2026-10-15', '2026-10-20', 4, 'Confirmed'),
(8, 8, 8, 8, '2026-10-18', '2026-10-22', 2, 'Completed'),
(9, 9, 9, 9, '2026-10-20', '2026-10-24', 2, 'Confirmed'),
(10, 10, 10, 10, '2026-10-22', '2026-10-26', 3, 'Cancelled'),
(11, 11, 11, 11, '2026-10-25', '2026-10-28', 1, 'Completed'),
(12, 12, 12, 12, '2026-10-27', '2026-10-31', 2, 'Confirmed'),
(13, 13, 13, 13, '2026-11-01', '2026-11-05', 2, 'Confirmed'),
(14, 14, 14, 14, '2026-11-03', '2026-11-07', 2, 'Completed'),
(15, 15, 15, 15, '2026-11-05', '2026-11-10', 4, 'Confirmed'),
(16, 16, 16, 16, '2026-11-08', '2026-11-12', 1, 'Completed'),
(17, 17, 17, 17, '2026-11-10', '2026-11-14', 3, 'Confirmed'),
(18, 18, 18, 18, '2026-11-12', '2026-11-16', 2, 'Confirmed'),
(19, 19, 19, 19, '2026-11-15', '2026-11-18', 1, 'Completed'),
(20, 20, 20, 20, '2026-11-18', '2026-11-22', 2, 'Confirmed');

-- 5. Booking Financial Breakdowns (Commission: Guest 10%, Host 3%)
INSERT INTO booking_financial_breakdowns (financial_id, booking_id, base_subtotal, cleaning_fee, guest_service_fee, host_service_fee, total_guest_paid, net_host_earnings) VALUES
(1, 1, 480.00, 25.00, 48.00, 14.40, 553.00, 490.60),
(2, 2, 380.00, 20.00, 38.00, 11.40, 438.00, 388.60),
(3, 3, 1600.00, 60.00, 160.00, 48.00, 1820.00, 1612.00),
(4, 4, 600.00, 35.00, 60.00, 18.00, 695.00, 617.00),
(5, 5, 320.00, 15.00, 32.00, 9.60, 367.00, 325.40),
(6, 6, 640.00, 40.00, 64.00, 19.20, 744.00, 660.80),
(7, 7, 2000.00, 80.00, 200.00, 60.00, 2280.00, 2020.00),
(8, 8, 880.00, 50.00, 88.00, 26.40, 1018.00, 903.60),
(9, 9, 440.00, 25.00, 44.00, 13.20, 509.00, 451.80),
(10, 10, 500.00, 30.00, 50.00, 15.00, 580.00, 515.00),
(11, 11, 315.00, 20.00, 31.50, 9.45, 366.50, 325.55),
(12, 12, 540.00, 30.00, 54.00, 16.20, 624.00, 553.80),
(13, 13, 360.00, 20.00, 36.00, 10.80, 416.00, 369.20),
(14, 14, 460.00, 25.00, 46.00, 13.80, 531.00, 471.20),
(15, 15, 700.00, 35.00, 70.00, 21.00, 805.00, 714.00),
(16, 16, 340.00, 15.00, 34.00, 10.20, 389.00, 344.80),
(17, 17, 520.00, 30.00, 52.00, 15.60, 602.00, 534.40),
(18, 18, 580.00, 35.00, 58.00, 17.40, 673.00, 597.60),
(19, 19, 195.00, 10.00, 19.50, 5.85, 224.50, 199.15),
(20, 20, 280.00, 15.00, 28.00, 8.40, 323.00, 286.60);

-- 6. Payment Transactions (20 rows)
INSERT INTO payment_transactions (payment_id, booking_id, payment_method, amount_paid, payment_status, transaction_reference) VALUES
(1, 1, 'Credit Card', 553.00, 'Completed', 'TXN_REF_001_A'),
(2, 2, 'PayPal', 438.00, 'Completed', 'TXN_REF_002_B'),
(3, 3, 'Credit Card', 1820.00, 'Completed', 'TXN_REF_003_C'),
(4, 4, 'Apple Pay', 695.00, 'Completed', 'TXN_REF_004_D'),
(5, 5, 'Google Pay', 367.00, 'Completed', 'TXN_REF_005_E'),
(6, 6, 'Credit Card', 744.00, 'Completed', 'TXN_REF_006_F'),
(7, 7, 'PayPal', 2280.00, 'Completed', 'TXN_REF_007_G'),
(8, 8, 'Credit Card', 1018.00, 'Completed', 'TXN_REF_008_H'),
(9, 9, 'Apple Pay', 509.00, 'Completed', 'TXN_REF_009_I'),
(10, 10, 'Credit Card', 580.00, 'Refunded', 'TXN_REF_010_J'),
(11, 11, 'PayPal', 366.50, 'Completed', 'TXN_REF_011_K'),
(12, 12, 'Credit Card', 624.00, 'Completed', 'TXN_REF_012_L'),
(13, 13, 'Google Pay', 416.00, 'Completed', 'TXN_REF_013_M'),
(14, 14, 'Credit Card', 531.00, 'Completed', 'TXN_REF_014_N'),
(15, 15, 'Apple Pay', 805.00, 'Completed', 'TXN_REF_015_O'),
(16, 16, 'PayPal', 389.00, 'Completed', 'TXN_REF_016_P'),
(17, 17, 'Credit Card', 602.00, 'Completed', 'TXN_REF_017_Q'),
(18, 18, 'Google Pay', 673.00, 'Completed', 'TXN_REF_018_R'),
(19, 19, 'Credit Card', 224.50, 'Completed', 'TXN_REF_019_S'),
(20, 20, 'PayPal', 323.00, 'Completed', 'TXN_REF_020_T');

-- 7. Host Payouts (Scheduled 24h post check-in)
INSERT INTO host_payouts (payout_id, booking_id, host_profile_id, payout_amount, scheduled_release_time, payout_status, released_at) VALUES
(1, 1, 1, 490.60, '2026-10-02 14:00:00', 'Scheduled', NULL),
(2, 2, 2, 388.60, '2026-10-04 14:00:00', 'Paid', '2026-10-04 14:05:00'),
(3, 3, 3, 1612.00, '2026-10-06 14:00:00', 'Scheduled', NULL),
(4, 4, 4, 617.00, '2026-10-09 14:00:00', 'Scheduled', NULL),
(5, 5, 5, 325.40, '2026-10-11 14:00:00', 'Paid', '2026-10-11 14:02:00'),
(6, 6, 6, 660.80, '2026-10-13 14:00:00', 'Scheduled', NULL),
(7, 7, 7, 2020.00, '2026-10-16 14:00:00', 'Scheduled', NULL),
(8, 8, 8, 903.60, '2026-10-19 14:00:00', 'Paid', '2026-10-19 14:10:00'),
(9, 9, 9, 451.80, '2026-10-21 14:00:00', 'Scheduled', NULL),
(10, 10, 10, 515.00, '2026-10-23 14:00:00', 'Withheld', NULL),
(11, 11, 11, 325.55, '2026-10-26 14:00:00', 'Paid', '2026-10-26 14:01:00'),
(12, 12, 12, 553.80, '2026-10-28 14:00:00', 'Scheduled', NULL),
(13, 13, 13, 369.20, '2026-11-02 14:00:00', 'Scheduled', NULL),
(14, 14, 14, 471.20, '2026-11-04 14:00:00', 'Paid', '2026-11-04 14:08:00'),
(15, 15, 15, 714.00, '2026-11-06 14:00:00', 'Scheduled', NULL),
(16, 16, 16, 344.80, '2026-11-09 14:00:00', 'Paid', '2026-11-09 14:04:00'),
(17, 17, 17, 534.40, '2026-11-11 14:00:00', 'Scheduled', NULL),
(18, 18, 18, 597.60, '2026-11-13 14:00:00', 'Scheduled', NULL),
(19, 19, 19, 199.15, '2026-11-16 14:00:00', 'Paid', '2026-11-16 14:00:00'),
(20, 20, 20, 286.60, '2026-11-19 14:00:00', 'Scheduled', NULL);

-- Verification: Row Counts for Clusters 3 and 4 (All 7 tables)
SELECT 'availability_calendar' AS table_name, COUNT(*) AS total_rows FROM availability_calendar
UNION ALL
SELECT 'pricing_rules', COUNT(*) FROM pricing_rules
UNION ALL
SELECT 'promotions_discounts', COUNT(*) FROM promotions_discounts
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'booking_financial_breakdowns', COUNT(*) FROM booking_financial_breakdowns
UNION ALL
SELECT 'payment_transactions', COUNT(*) FROM payment_transactions
UNION ALL
SELECT 'host_payouts', COUNT(*) FROM host_payouts;
USE airbnb_dm;

-- Temporarily bypass FK checks to ensure a clean insert into Cluster 5
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE dispute_claims;
TRUNCATE TABLE message_threads;
TRUNCATE TABLE reviews;

SET FOREIGN_KEY_CHECKS = 1;

-- ====================================================================
-- CLUSTER 5: REVIEWS, MESSAGE THREADS & DISPUTE CLAIMS (20 ROWS EACH)
-- ====================================================================

-- 1. Reviews (Double-Blind Mutual Feedback Ledger)
INSERT INTO reviews (review_id, booking_id, reviewer_user_id, cleanliness_rating, accuracy_rating, communication_rating, location_rating, overall_rating, review_comments, is_visible) VALUES
(1, 1, 1, 5, 5, 5, 5, 5.0, 'Spotless apartment with breathtaking skyline views. Highly recommended!', TRUE),
(2, 2, 2, 4, 5, 4, 4, 4.3, 'Spacious loft with great creative energy. The neighborhood gets slightly lively at night.', TRUE),
(3, 3, 3, 5, 5, 5, 5, 5.0, 'Incredible hillside villa. The pool and outdoor facilities were top tier.', TRUE),
(4, 4, 4, 4, 4, 5, 4, 4.3, 'Warm, quiet home perfect for a relaxing family weekend getaway.', TRUE),
(5, 5, 5, 5, 4, 5, 5, 4.8, 'Very clean and efficient studio. Perfect setup for remote data work.', TRUE),
(6, 6, 6, 5, 5, 5, 5, 5.0, 'First-class service. Concierge was prompt and daily cleaning was impeccable.', TRUE),
(7, 7, 7, 5, 5, 4, 5, 4.8, 'Unrivaled coastal views from the balcony. Worth every dollar.', TRUE),
(8, 8, 8, 4, 4, 4, 5, 4.3, 'Classic townhouse near central transit lines. Lovely garden patio.', TRUE),
(9, 9, 9, 5, 5, 5, 4, 4.8, 'Peaceful and cozy cottage right next to the beach.', TRUE),
(10, 11, 11, 5, 4, 5, 5, 4.8, 'Magical stay up in the canopy. Waking up to forest sounds was unforgettable.', TRUE),
(11, 12, 12, 4, 4, 4, 5, 4.3, 'Unique houseboat experience on the river. Well insulated and warm.', TRUE),
(12, 13, 13, 5, 5, 5, 5, 5.0, 'The stargazing yurt delivered an extraordinary clear night sky view.', TRUE),
(13, 14, 14, 4, 5, 5, 4, 4.5, 'Sleek eco-dome architecture. Great modern off-grid experience.', TRUE),
(14, 15, 15, 5, 4, 5, 4, 4.5, 'Relaxing farm atmosphere with generous and fresh homemade breakfast.', TRUE),
(15, 16, 16, 5, 5, 5, 5, 5.0, 'Charming period interior combined with modern luxury fittings.', TRUE),
(16, 17, 17, 4, 4, 4, 4, 4.0, 'Quiet duplex with easy private access and secure surrounding walls.', TRUE),
(17, 18, 18, 5, 4, 5, 5, 4.8, 'Serene tropical bungalow. Great shade and relaxing grounds.', TRUE),
(18, 19, 19, 4, 5, 4, 4, 4.3, 'Comfortable room close to local art spaces and neighborhood cafes.', TRUE),
(19, 20, 20, 4, 4, 5, 5, 4.5, 'Convenient flat right beside campus, tidy and hassle-free.', TRUE),
(20, 2, 22, 5, 5, 5, 5, 5.0, 'Host feedback: The guest was polite, tidy, and respected all house rules.', TRUE);

-- 2. Message Threads (In-App Communications)
INSERT INTO message_threads (message_id, listing_id, sender_user_id, receiver_user_id, message_body, is_read) VALUES
(1, 1, 1, 1, 'Hello Amina, is early self check-in available around 1:00 PM?', TRUE),
(2, 1, 1, 1, 'Welcome! Yes, smart lock access will activate by 1:00 PM.', TRUE),
(3, 2, 2, 2, 'Hi, does the loft provide dedicated parking in the courtyard?', TRUE),
(4, 2, 2, 2, 'Hello Chidi, designated parking bay 4 is reserved for your stay.', TRUE),
(5, 3, 3, 3, 'Can the villa pool heating be set before our evening arrival?', TRUE),
(6, 3, 3, 3, 'Certainly, pool temperature is scheduled to reach 28C by 4:00 PM.', TRUE),
(7, 4, 4, 4, 'Good day, please confirm high-speed Wi-Fi details for video calls.', TRUE),
(8, 4, 4, 4, 'Network credentials and router instructions are on the foyer counter.', TRUE),
(9, 5, 5, 5, 'Is the work desk suitable for an external multi-monitor display?', TRUE),
(10, 5, 5, 5, 'Yes, the desk is 140cm wide and fitted with direct surge extension sockets.', TRUE),
(11, 6, 6, 6, 'Can we request daily linen turnaround during our stay?', TRUE),
(12, 6, 6, 6, 'Housekeeping is scheduled daily between 10:00 AM and 12:00 PM.', TRUE),
(13, 7, 7, 7, 'Is rooftop terrace access shared or completely private?', TRUE),
(14, 7, 7, 7, 'The upper roof terrace is entirely exclusive to the penthouse suite.', TRUE),
(15, 8, 8, 8, 'Are tube stations within walking distance of the townhouse?', TRUE),
(16, 8, 8, 8, 'Yes, Victoria Station is a convenient 6-minute stroll.', TRUE),
(17, 9, 9, 9, 'Do you offer beach towels and folding parasols?', TRUE),
(18, 9, 9, 9, 'Beach kits and umbrellas are stored in the entryway closet.', TRUE),
(19, 10, 10, 10, 'Requesting cancellation due to an urgent scheduling clash.', TRUE),
(20, 10, 10, 10, 'Cancellation processed according to the platform standard policy.', TRUE);

-- 3. Dispute Claims (Ternary Administrative Arbitration)
INSERT INTO dispute_claims (dispute_id, booking_id, claimant_user_id, admin_user_id, disputed_amount, claim_reason, resolution_status, resolved_at) VALUES
(1, 10, 10, 25, 580.00, 'Guest requested full refund due to flight cancellation.', 'Refund Approved', '2026-10-23 16:00:00'),
(2, 2, 2, 25, 45.00, 'Minor discrepancy in advertised heating setup during first night.', 'Dismissed', '2026-10-06 11:30:00'),
(3, 4, 4, 25, 80.00, 'Garden maintenance noise during morning hours.', 'Refund Approved', '2026-10-10 14:15:00'),
(4, 7, 7, 25, 120.00, 'Elevator maintenance required temporary stair access for half a day.', 'Refund Approved', '2026-10-17 10:00:00'),
(5, 1, 1, 25, 30.00, 'Wi-Fi fiber reset took two hours on day two.', 'Dismissed', '2026-10-03 12:00:00'),
(6, 3, 3, 25, 150.00, 'Outdoor jacuzzi filter required mid-stay servicing.', 'Under Review', NULL),
(7, 5, 5, 25, 25.00, 'Desk light bulb replacement took several hours.', 'Dismissed', '2026-10-12 18:00:00'),
(8, 6, 6, 25, 60.00, 'Cleaning crew arrived one hour past standard schedule.', 'Refund Approved', '2026-10-14 09:30:00'),
(9, 8, 8, 25, 40.00, 'Patio gate lock was difficult to open.', 'Dismissed', '2026-10-20 15:00:00'),
(10, 9, 9, 25, 50.00, 'Coastal fog caused slight satellite television interruption.', 'Dismissed', '2026-10-22 17:00:00'),
(11, 11, 11, 25, 70.00, 'Treehouse canopy bridge lighting flickering in wind.', 'Under Review', NULL),
(12, 12, 12, 25, 90.00, 'River mooring gangway adjustment required maintenance visit.', 'Under Review', NULL),
(13, 13, 13, 25, 35.00, 'Telescope mount missing dust cap upon arrival.', 'Dismissed', '2026-11-03 11:00:00'),
(14, 14, 14, 25, 85.00, 'Solar battery switchover caused brief power restart.', 'Refund Approved', '2026-11-05 14:00:00'),
(15, 15, 15, 25, 40.00, 'Tractor activity on adjoining field started at 7:00 AM.', 'Dismissed', '2026-11-07 16:30:00'),
(16, 16, 16, 25, 55.00, 'Boutique courtyard fountain switched off for cleaning.', 'Dismissed', '2026-11-10 13:00:00'),
(17, 17, 17, 25, 65.00, 'Neighboring duplex lawn trimming during afternoon rest.', 'Dismissed', '2026-11-12 10:30:00'),
(18, 18, 18, 25, 110.00, 'Air conditioning maintenance required inspection visit.', 'Under Review', NULL),
(19, 19, 19, 25, 20.00, 'Shared flat hallway light replacement delayed.', 'Dismissed', '2026-11-17 12:00:00'),
(20, 20, 20, 25, 30.00, 'Campus street noise during sports event evening.', 'Dismissed', '2026-11-20 15:45:00');

-- 4. Global Verification: Row Counts Across All 22 Normalized Entities
SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL SELECT 'government_ids', COUNT(*) FROM government_ids
UNION ALL SELECT 'social_connections', COUNT(*) FROM social_connections
UNION ALL SELECT 'property_categories', COUNT(*) FROM property_categories
UNION ALL SELECT 'guest_profiles', COUNT(*) FROM guest_profiles
UNION ALL SELECT 'host_profiles', COUNT(*) FROM host_profiles
UNION ALL SELECT 'amenities', COUNT(*) FROM amenities
UNION ALL SELECT 'listings', COUNT(*) FROM listings
UNION ALL SELECT 'listing_specifications', COUNT(*) FROM listing_specifications
UNION ALL SELECT 'listing_amenities', COUNT(*) FROM listing_amenities
UNION ALL SELECT 'listing_photos', COUNT(*) FROM listing_photos
UNION ALL SELECT 'co_hosts', COUNT(*) FROM co_hosts
UNION ALL SELECT 'availability_calendar', COUNT(*) FROM availability_calendar
UNION ALL SELECT 'pricing_rules', COUNT(*) FROM pricing_rules
UNION ALL SELECT 'promotions_discounts', COUNT(*) FROM promotions_discounts
UNION ALL SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL SELECT 'booking_financial_breakdowns', COUNT(*) FROM booking_financial_breakdowns
UNION ALL SELECT 'payment_transactions', COUNT(*) FROM payment_transactions
UNION ALL SELECT 'host_payouts', COUNT(*) FROM host_payouts
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'message_threads', COUNT(*) FROM message_threads
UNION ALL SELECT 'dispute_claims', COUNT(*) FROM dispute_claims;