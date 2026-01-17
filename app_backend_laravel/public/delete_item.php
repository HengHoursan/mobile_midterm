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

require_once __DIR__ . '/../functions/item_functions.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $itemId = filter_input(INPUT_POST, 'item_id', FILTER_VALIDATE_INT);

        if (!$itemId) {
            http_response_code(400); // Bad Request
            echo json_encode(['success' => false, 'message' => 'Valid item_id is required.']);
            exit;
        }

        if (deleteItem($itemId)) {
            echo json_encode(['success' => true, 'message' => 'Item deleted successfully.']);
        } else {
            http_response_code(404); // Not Found / no row affected
            echo json_encode(['success' => false, 'message' => 'Item not found or could not be deleted.']);
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
