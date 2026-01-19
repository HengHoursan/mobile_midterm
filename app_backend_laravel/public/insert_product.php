<?php
// CORS headers - allow all origins (development only)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Handle preflight (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit(0);
}

require_once __DIR__ . '/../functions/product_functions.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Validate and sanitize input
        $productName = filter_input(INPUT_POST, 'product_name', FILTER_SANITIZE_STRING);
        $category = filter_input(INPUT_POST, 'category', FILTER_SANITIZE_STRING);
        $description = filter_input(INPUT_POST, 'description', FILTER_SANITIZE_STRING);
        $qty = filter_input(INPUT_POST, 'qty', FILTER_VALIDATE_INT);
        $unitPrice = filter_input(INPUT_POST, 'unit_price', FILTER_VALIDATE_FLOAT);
        $status = filter_input(INPUT_POST, 'status', FILTER_SANITIZE_STRING) ?? 'active';

        if (!$productName || $qty === false || $unitPrice === false) {
            throw new Exception("Invalid input data.");
        }

        $data = [
            'product_name' => $productName,
            'category' => $category,
            'description' => $description,
            'qty' => $qty,
            'unit_price' => $unitPrice,
            'status' => $status,
        ];

        $productId = insertProduct($data);

        echo json_encode(['success' => true, 'message' => 'Item added successfully', 'product_id' => $productId]);
    } catch (Exception $e) {
        http_response_code(500); // Internal Server Error
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
} else {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['success' => false, 'message' => 'Invalid request method. Received: ' . $_SERVER['REQUEST_METHOD']]);
}
?>