<?php
// CORS headers for images
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

$filename = $_GET['file'] ?? '';
$imagePath = __DIR__ . '/uploads/' . $filename;

// Security check - only allow files in uploads directory
if (empty($filename) || strpos($filename, '..') !== false || strpos($filename, '/') !== false) {
    http_response_code(404);
    exit('File not found');
}

if (!file_exists($imagePath)) {
    http_response_code(404);
    exit('Image not found');
}

// Get file info
$imageInfo = getimagesize($imagePath);
if ($imageInfo === false) {
    http_response_code(404);
    exit('Invalid image');
}

// Set proper content type
header('Content-Type: ' . $imageInfo['mime']);
header('Content-Length: ' . filesize($imagePath));

// Output the image
readfile($imagePath);
?>