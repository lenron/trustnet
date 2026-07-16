-- MariaDB set up script for lenron-obf

-- Select database to run commands on.
USE chatriwe_obf;

-- Create table for obfuscated data.
CREATE TABLE IF NOT EXISTS obfuscation (id INT NOT NULL AUTO_INCREMENT, fingerprint VARCHAR(43), data VARCHAR(1072), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id), UNIQUE(fingerprint));
-- Create table for passlocks.
CREATE TABLE IF NOT EXISTS passlock_table (id INT NOT NULL AUTO_INCREMENT, browser_id VARCHAR(64), passlock VARCHAR(64), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id));

-- Create table for contact messages.
CREATE TABLE IF NOT EXISTS contact_messages (id INT NOT NULL AUTO_INCREMENT, ip VARCHAR(16), message TEXT(65534), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id));

-- Security tables
-- UNIQUE helps 'INSERT INTO...ON DUPLICATE KEY' work.
-- #1 - Daily stores for given IP
CREATE TABLE IF NOT EXISTS stores_today_per_ip (id INT NOT NULL AUTO_INCREMENT, ip VARCHAR(16), stores_today INT, PRIMARY KEY(id), UNIQUE(ip));
-- #2 - Stores recorded on date
CREATE TABLE IF NOT EXISTS stores_on_date (id INT NOT NULL AUTO_INCREMENT, date_stored DATE, stores_on_this_date INT, PRIMARY KEY(id), UNIQUE(date_stored));
-- #3 - Daily access failures per IP 
CREATE TABLE IF NOT EXISTS access_failures_today_per_ip (id INT NOT NULL AUTO_INCREMENT, ip VARCHAR(16), access_failures_today INT, PRIMARY KEY(id), UNIQUE(ip));
-- #4 - Unique visitor count per date
CREATE TABLE IF NOT EXISTS unique_visitors_on_date (id INT NOT NULL AUTO_INCREMENT, date_visited DATE, unique_visitors_on_this_date INT, PRIMARY KEY(id), UNIQUE(date_visited));
-- #5 - Daily unique visitor IPs - Not using UNIQUE here because I want a standard INSERT INTO to fail if ip exists (don't need response back).
CREATE TABLE IF NOT EXISTS unique_visitor_ips_today (id INT NOT NULL AUTO_INCREMENT, ip VARCHAR(16), PRIMARY KEY(id));
-- #6 - Contact messages today for a given ip..
CREATE TABLE IF NOT EXISTS contacts_today_per_ip (id INT NOT NULL AUTO_INCREMENT, ip VARCHAR(16), contacts_today INT, PRIMARY KEY(id), UNIQUE(ip));
-- #7 - Contact messages on this date
CREATE TABLE IF NOT EXISTS contacts_on_date (id INT NOT NULL AUTO_INCREMENT, date_contacted DATE, contacts_on_this_date INT, PRIMARY KEY(id), UNIQUE(date_contacted));

-- Enable event scheduler so events can be scheduled.
SET GLOBAL event_scheduler = ON;   

-- Every 1 minute remove all passlocks more than 6 minutes old.
CREATE EVENT remove_expired_passlocks ON SCHEDULE EVERY 1 MINUTE
DO DELETE FROM passlock_table WHERE timestamp < CURRENT_TIMESTAMP() - INTERVAL 6 MINUTE;

-- Clear daily tables every 24 hours at 2:30 AM.
CREATE EVENT clear_stores_today_every_24_hours ON SCHEDULE EVERY 1 DAY STARTS CURRENT_DATE + INTERVAL '02:30:00' HOUR_SECOND DO TRUNCATE TABLE stores_today_per_ip;
CREATE EVENT clear_access_failures_today_every_24_hours ON SCHEDULE EVERY 1 DAY STARTS CURRENT_DATE + INTERVAL '02:30:00' HOUR_SECOND DO TRUNCATE TABLE access_failures_today_per_ip;
CREATE EVENT clear_unique_visitor_ips_every_24_hours ON SCHEDULE EVERY 1 DAY STARTS CURRENT_DATE + INTERVAL '02:30:00' HOUR_SECOND DO TRUNCATE TABLE unique_visitor_ips_today;
CREATE EVENT clear_contactes_today_every_24_hours ON SCHEDULE EVERY 1 DAY STARTS CURRENT_DATE + INTERVAL '02:30:00' HOUR_SECOND DO TRUNCATE TABLE contacts_today_per_ip;

-- grant privileges for mariadb-backup. (GRANT ALL doesn't work for these I guess.)
--GRANT RELOAD, PROCESS ON *.* TO 'chatriwe_admin'@'%';   

