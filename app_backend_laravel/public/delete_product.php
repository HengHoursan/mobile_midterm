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
        $productId = filter_input(INPUT_POST, 'product_id', FILTER_VALIDATE_INT);

        if (!$productId) {
            http_response_code(400); // Bad Request
            echo json_encode(['success' => false, 'message' => 'Valid product_id is required.']);
            exit;
        }

        if (deleteProduct($productId)) {
            echo json_encode(['success' => true, 'message' => 'product deleted successfully.']);
        } else {
            http_response_code(404); // Not Found / no row affected
            echo json_encode(['success' => false, 'message' => 'product not found or could not be deleted.']);
        }
    } catch (Exception $e) {
        http_response_code(500); // Internal Server Error
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
} else {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['success' => false, 'message' => 'Invalid request method. Received: ' . $_SERVER['REQUEST_METHOD']]);
}
?>
