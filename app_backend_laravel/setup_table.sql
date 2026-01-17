-- Create the tblitems table for the midterm project
-- Run this in your MySQL database (midtermdb)

CREATE TABLE tblitems (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    category VARCHAR(255) NULL,
    description TEXT NULL,
    qty INT NOT NULL DEFAULT 0,
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    item_image VARCHAR(500) NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Optional: Insert some sample data for testing
INSERT INTO tblitems (item_name, category, description, qty, unit_price, status) VALUES
('Sample Item 1', 'Electronics', 'A sample electronic item', 10, 99.99, 'active'),
('Sample Item 2', 'Books', 'A sample book', 5, 29.95, 'active'),
('Sample Item 3', 'Clothing', 'A sample clothing item', 20, 49.50, 'active');