USE airbnb_dm;

-- ====================================================================
-- 1. VIEW: PLATFORM REVENUE & COMMISSION ESCROW YIELD
-- Demonstrates multi-table aggregation, financial reconciliation, and take-rate
-- ====================================================================
CREATE OR REPLACE VIEW vw_platform_revenue_analytics AS
SELECT 
    b.booking_status,
    COUNT(b.booking_id) AS total_reservations,
    ROUND(SUM(bfb.base_subtotal), 2) AS total_base_subtotal,
    ROUND(SUM(bfb.cleaning_fee), 2) AS total_cleaning_fees,
    ROUND(SUM(bfb.guest_service_fee), 2) AS total_guest_commissions,
    ROUND(SUM(bfb.host_service_fee), 2) AS total_host_commissions,
    ROUND(SUM(bfb.guest_service_fee + bfb.host_service_fee), 2) AS total_platform_net_revenue,
    ROUND(SUM(bfb.total_guest_paid), 2) AS gross_booking_value,
    ROUND(AVG(bfb.guest_service_fee + bfb.host_service_fee), 2) AS avg_commission_per_booking
FROM bookings b
JOIN booking_financial_breakdowns bfb ON b.booking_id = bfb.booking_id
GROUP BY b.booking_status;

-- ====================================================================
-- 2. VIEW: HOST PERFORMANCE, OCCUPANCY & SUPERHOST EVALUATION
-- Demonstrates 1:1, 1:M joins, conditional logic, and KPI aggregation
-- ====================================================================
CREATE OR REPLACE VIEW vw_host_performance_occupancy AS
SELECT 
    hp.host_profile_id,
    CONCAT(u.first_name, ' ', u.last_name) AS host_full_name,
    hp.is_superhost,
    hp.response_rate_pct,
    COUNT(DISTINCT l.listing_id) AS active_properties_listed,
    COUNT(DISTINCT b.booking_id) AS total_bookings_handled,
    COALESCE(ROUND(AVG(r.overall_rating), 2), 0.00) AS avg_listing_rating,
    COALESCE(ROUND(SUM(bfb.net_host_earnings), 2), 0.00) AS lifetime_net_earnings
FROM host_profiles hp
JOIN users u ON hp.user_id = u.user_id
JOIN listings l ON hp.host_profile_id = l.host_profile_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id
LEFT JOIN booking_financial_breakdowns bfb ON b.booking_id = bfb.booking_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
GROUP BY hp.host_profile_id, host_full_name, hp.is_superhost, hp.response_rate_pct;

-- ====================================================================
-- 3. AUDIT QUERY: 24-HOUR POST-CHECK-IN ESCROW PAYOUT SCHEDULE VERIFICATION
-- Tests temporal compliance and transactional integrity
-- ====================================================================
SELECT 
    hp.payout_id,
    b.booking_id,
    CONCAT(u.first_name, ' ', u.last_name) AS host_name,
    b.check_in_date,
    hp.scheduled_release_time,
    TIMESTAMPDIFF(HOUR, b.check_in_date, hp.scheduled_release_time) AS hours_after_checkin,
    hp.payout_amount,
    hp.payout_status,
    hp.released_at
FROM host_payouts hp
JOIN bookings b ON hp.booking_id = b.booking_id
JOIN host_profiles host_prof ON hp.host_profile_id = host_prof.host_profile_id
JOIN users u ON host_prof.user_id = u.user_id
ORDER BY b.check_in_date ASC;

-- ====================================================================
-- 4. ANALYTIC QUERY: DISPUTE CLAIMS ARBITRATION BREAKDOWN (TERNARY JOIN)
-- Joins Dispute Claims + Booking + Claimant User + Admin User
-- ====================================================================
SELECT 
    dc.dispute_id,
    dc.booking_id,
    CONCAT(claimant.first_name, ' ', claimant.last_name) AS claimant_name,
    CONCAT(admin_user.first_name, ' ', admin_user.last_name) AS arbitrator_admin,
    dc.disputed_amount,
    dc.resolution_status,
    dc.claim_reason,
    dc.filed_at,
    dc.resolved_at
FROM dispute_claims dc
JOIN users claimant ON dc.claimant_user_id = claimant.user_id
JOIN users admin_user ON dc.admin_user_id = admin_user.user_id
ORDER BY dc.dispute_id ASC;
USE airbnb_dm;

-- 1. Query the Platform Revenue & Escrow Commission Yield View
SELECT * FROM vw_platform_revenue_analytics;

-- 2. Query the Host Performance & Superhost Evaluation View
SELECT * FROM vw_host_performance_occupancy
ORDER BY lifetime_net_earnings DESC;