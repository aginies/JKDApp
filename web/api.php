<?php
require_once 'config.php';

// Set response headers
header('Content-Type: application/json');

// Only allow POST requests for uploads
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed. Use POST.']);
    exit;
}

// Verify the API Key in headers
verify_api_key();

// Handle JSON upload
$content_type = isset($_SERVER["CONTENT_TYPE"]) ? $_SERVER["CONTENT_TYPE"] : '';

if (strpos($content_type, "application/json") !== false) {
    // Read raw JSON from request body
    $json_data = file_get_contents('php://input');
    
    if (empty($json_data)) {
        http_response_code(400);
        echo json_encode(['error' => 'Empty request body']);
        exit;
    }

    // Check file size
    if (strlen($json_data) > MAX_FILE_SIZE) {
        http_response_code(413);
        echo json_encode(['error' => 'File too large (max ' . format_bytes(MAX_FILE_SIZE) . ')']);
        exit;
    }
    
    // Validate JSON structure
    $decoded = json_decode($json_data);
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON payload: ' . json_last_error_msg()]);
        exit;
    }
    
    // Extract username and filename from headers (case-insensitive)
    $all_headers = array_change_key_case(getallheaders(), CASE_LOWER);
    
    $username = isset($all_headers['x-username']) ? preg_replace('/[^a-zA-Z0-9_\-\s]/', '', $all_headers['x-username']) : 'anonymous';
    $category = isset($all_headers['x-category']) ? preg_replace('/[^a-zA-Z0-9_\-\s]/', '', $all_headers['x-category']) : 'Uncategorized';
    $filename = isset($all_headers['x-filename']) ? preg_replace('/[^a-zA-Z0-9_\-\.\s]/', '', $all_headers['x-filename']) : 'series_' . date('Ymd_His') . '.json';
    
    // Ensure filename ends with .json
    if (pathinfo($filename, PATHINFO_EXTENSION) !== 'json') {
        $filename .= '.json';
    }

    // Prefix filename with username and category for triage: category---username---filename.json
    $safe_username = str_replace('---', '-', $username);
    $safe_category = str_replace('---', '-', $category);
    $final_filename = $safe_category . '---' . $safe_username . '---' . str_replace('---', '-', $filename);
    
    // Create directory if not exists
    if (!is_dir(UPLOAD_DIR)) {
        mkdir(UPLOAD_DIR, 0755, true);
    }
    
    // Save to file
    $target_path = UPLOAD_DIR . $final_filename;
    if (file_put_contents($target_path, $json_data)) {
        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'message' => 'File saved successfully',
            'filename' => $final_filename,
            'display_name' => $filename,
            'user' => $username,
            'size' => format_bytes(strlen($json_data))
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save file to server storage']);
    }
} else {
    http_response_code(400);
    echo json_encode(['error' => 'Unsupported content type. Must be application/json']);
}
?>
