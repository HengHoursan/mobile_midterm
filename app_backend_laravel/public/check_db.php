<?php
try {
    require_once __DIR__ . '/../config/db.php';
    echo "Database connection successful!";
} catch (PDOException $e) {
    echo "Database connection failed: " . $e->getMessage();
}
?>