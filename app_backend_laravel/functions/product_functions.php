<?php
require_once __DIR__ . '/../config/db.php';

function fetchProducts() {
    global $pdo;
    $stmt = $pdo->query('SELECT * FROM tblproduct');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function fetchProduct($id) {
    global $pdo;
    $stmt = $pdo->prepare('SELECT * FROM tblproduct WHERE product_id = :id');
    $stmt->execute(['id' => $id]);
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

function insertProduct($data) {
    global $pdo;

    $product_image = null;
    if (isset($_FILES['product_image']) && $_FILES['product_image']['error'] == UPLOAD_ERR_OK) {
        try {
            $product_image = uploadImage($_FILES['product_image']);
        } catch (Exception $e) {
            // Handle error, e.g., log it or return a specific error message
            error_log("Image upload failed: " . $e->getMessage());
            throw $e; // Re-throw to be caught by the API endpoint
        }
    }
    
    $sql = "INSERT INTO tblproduct (product_name, category, description, qty, unit_price, product_image, status) 
            VALUES (:product_name, :category, :description, :qty, :unit_price, :product_image, :status)";
    $stmt= $pdo->prepare($sql);
    $stmt->execute([
        'product_name' => $data['product_name'],
        'category' => $data['category'] ?? null,
        'description' => $data['description'] ?? null,
        'qty' => $data['qty'],
        'unit_price' => $data['unit_price'],
        'product_image' => $product_image,
        'status' => $data['status'] ?? 'active' // Default status
    ]);
    return $pdo->lastInsertId();
}

function updateProduct($data) {
    global $pdo;

    $product_image = $data['current_product_image'] ?? null; // Keep existing image by default

    if (isset($_FILES['product_image']) && $_FILES['product_image']['error'] == UPLOAD_ERR_OK) {
        try {
            // Delete old image if it exists
            if ($product_image && file_exists(__DIR__ . "/../public/uploads/" . $product_image)) {
                 unlink(__DIR__ . "/../public/uploads/" . $product_image);
            }
            $product_image = uploadImage($_FILES['product_image']);
        } catch (Exception $e) {
            error_log("Image upload failed during update: " . $e->getMessage());
            throw $e;
        }
    } else if (isset($data['current_product_image']) && empty($_FILES['product_image']['name'])) {
        // If no new image is uploaded and current_item_image is provided, retain it
        $product_image = $data['current_product_image'];
    } else {
        $product_image = null; // No image for update
    }


    $sql = "UPDATE tblproduct SET 
                product_name = :product_name, 
                category = :category, 
                description = :description, 
                qty = :qty, 
                unit_price = :unit_price, 
                product_image = :product_image, 
                status = :status 
            WHERE product_id = :product_id";
    $stmt= $pdo->prepare($sql);
    $stmt->execute([
        'product_id' => $data['product_id'],
        'product_name' => $data['product_name'],
        'category' => $data['category'] ?? null,
        'description' => $data['description'] ?? null,
        'qty' => $data['qty'],
        'unit_price' => $data['unit_price'],
        'product_image' => $product_image,
        'status' => $data['status'] ?? 'active' // Default status
    ]);
    return $stmt->rowCount();
}

function deleteProduct($productId) {
    global $pdo;
    
    // First, get the item to delete its image if it exists
    $product = fetchProduct($productId);
    if ($ $product && isset($item['product_image']) &&  $product['product_image']) {
        $imagePath = __DIR__ . "/../public/uploads/" .  $product['product_image'];
        if (file_exists($imagePath)) {
            unlink($imagePath); // Delete the image file
        }
    }

    $stmt = $pdo->prepare('DELETE FROM tblproduct WHERE product_id = :product_id');
    return $stmt->execute(['product_id' =>  $productId]);
}
?>
