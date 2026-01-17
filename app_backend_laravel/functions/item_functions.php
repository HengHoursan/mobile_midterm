<?php
require_once __DIR__ . '/../config/db.php';

function fetchItems() {
    global $pdo;
    $stmt = $pdo->query('SELECT * FROM tblitems');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function fetchItem($id) {
    global $pdo;
    $stmt = $pdo->prepare('SELECT * FROM tblitems WHERE item_id = :item_id');
    $stmt->execute(['item_id' => $id]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function uploadImage($file) {
    // Store images under public/uploads so they are directly accessible via URL
    $target_dir = __DIR__ . "/../public/uploads/";
    // Ensure the uploads directory exists
    if (!is_dir($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    $imageName = uniqid() . '_' . basename($file["name"]);
    $target_file = $target_dir . $imageName;
    $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

    // Check if image file is a actual image or fake image
    $check = getimagesize($file["tmp_name"]);
    if($check === false) {
        throw new Exception("File is not an image.");
    }

    // Check file size (5MB limit)
    if ($file["size"] > 5 * 1024 * 1024) { 
        throw new Exception("Sorry, your file is too large. Max 5MB.");
    }

    // Allow certain file formats
    if($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg" && $imageFileType != "gif" ) {
        throw new Exception("Sorry, only JPG, JPEG, PNG & GIF files are allowed.");
    }

    if (move_uploaded_file($file["tmp_name"], $target_file)) {
        return $imageName; // Return just the filename
    } else {
        throw new Exception("Sorry, there was an error uploading your file.");
    }
}

function insertItem($data) {
    global $pdo;

    $item_image = null;
    if (isset($_FILES['item_image']) && $_FILES['item_image']['error'] == UPLOAD_ERR_OK) {
        try {
            $item_image = uploadImage($_FILES['item_image']);
        } catch (Exception $e) {
            // Handle error, e.g., log it or return a specific error message
            error_log("Image upload failed: " . $e->getMessage());
            throw $e; // Re-throw to be caught by the API endpoint
        }
    }
    
    $sql = "INSERT INTO tblitems (item_name, category, description, qty, unit_price, item_image, status) 
            VALUES (:item_name, :category, :description, :qty, :unit_price, :item_image, :status)";
    $stmt= $pdo->prepare($sql);
    $stmt->execute([
        'item_name' => $data['item_name'],
        'category' => $data['category'] ?? null,
        'description' => $data['description'] ?? null,
        'qty' => $data['qty'],
        'unit_price' => $data['unit_price'],
        'item_image' => $item_image,
        'status' => $data['status'] ?? 'active' // Default status
    ]);
    return $pdo->lastInsertId();
}

function updateItem($data) {
    global $pdo;

    $item_image = $data['current_item_image'] ?? null; // Keep existing image by default

    if (isset($_FILES['item_image']) && $_FILES['item_image']['error'] == UPLOAD_ERR_OK) {
        try {
            // Delete old image if it exists
            if ($item_image && file_exists(__DIR__ . "/../public/uploads/" . $item_image)) {
                 unlink(__DIR__ . "/../public/uploads/" . $item_image);
            }
            $item_image = uploadImage($_FILES['item_image']);
        } catch (Exception $e) {
            error_log("Image upload failed during update: " . $e->getMessage());
            throw $e;
        }
    } else if (isset($data['current_item_image']) && empty($_FILES['item_image']['name'])) {
        // If no new image is uploaded and current_item_image is provided, retain it
        $item_image = $data['current_item_image'];
    } else {
        $item_image = null; // No image for update
    }


    $sql = "UPDATE tblitems SET 
                item_name = :item_name, 
                category = :category, 
                description = :description, 
                qty = :qty, 
                unit_price = :unit_price, 
                item_image = :item_image, 
                status = :status 
            WHERE item_id = :item_id";
    $stmt= $pdo->prepare($sql);
    $stmt->execute([
        'item_id' => $data['item_id'],
        'item_name' => $data['item_name'],
        'category' => $data['category'] ?? null,
        'description' => $data['description'] ?? null,
        'qty' => $data['qty'],
        'unit_price' => $data['unit_price'],
        'item_image' => $item_image,
        'status' => $data['status'] ?? 'active' // Default status
    ]);
    return $stmt->rowCount();
}

function deleteItem($itemId) {
    global $pdo;
    
    // First, get the item to delete its image if it exists
    $item = fetchItem($itemId);
    if ($item && isset($item['item_image']) && $item['item_image']) {
        $imagePath = __DIR__ . "/../public/uploads/" . $item['item_image'];
        if (file_exists($imagePath)) {
            unlink($imagePath); // Delete the image file
        }
    }

    $stmt = $pdo->prepare('DELETE FROM tblitems WHERE item_id = :item_id');
    return $stmt->execute(['item_id' => $itemId]);
}
?>
