-- MariaDB set up script for lenron-obf

-- Create Table on database set up with docker-compose.yaml
USE chatriwe_obf;

-- Create table for obfuscated data.
CREATE TABLE IF NOT EXISTS obfuscation (id INT NOT NULL AUTO_INCREMENT, fingerprint VARCHAR(64), data VARCHAR(1000), ip VARCHAR(16), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id) );

-- Create table for passlocks.
CREATE TABLE IF NOT EXISTS passlock_table (id INT NOT NULL AUTO_INCREMENT, browser_id VARCHAR(64), passlock VARCHAR(64), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id) );

-- Enable event scheduler so events can be scheduled.
SET GLOBAL event_scheduler = ON;   

-- Every 1 minute remove all records older than 5 minutes.
CREATE EVENT remove_expired_passlocks ON SCHEDULE EVERY 1 MINUTE
DO DELETE FROM passlock_table WHERE timestamp < CURRENT_TIMESTAMP() - INTERVAL 5 MINUTE;

