-- MariaDB set up script for lenron-obf

-- Grant privileges to user (not sure if necessary)
GRANT ALL PRIVILEGES ON *.* TO 'chatriwe_admin'@'localhost';

-- Create Table on existing dbase
USE chatriwe_obf;
CREATE TABLE IF NOT EXISTS obfuscation (fingerprint VARCHAR(64), data VARCHAR(1000), ip VARCHAR(16), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(fingerprint) );


