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

// Verify the short-lived HMAC token
verify_token();

// Rate limiting: max 30 uploads per IP per hour (locked read+write to avoid race)
$rate_limit_max    = 30;
$rate_limit_window = 3600; // seconds
$client_ip         = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$rate_file         = sys_get_temp_dir() . '/jkdapp_rl_' . md5($client_ip) . '.json';
$now               = time();
$state             = ['count' => 0, 'window_start' => $now];

$fh = fopen($rate_file, 'c+');
if ($fh && flock($fh, LOCK_EX)) {
    $raw = stream_get_contents($fh);
    if ($raw) {
        $state = json_decode($raw, true) ?? $state;
    }
    if ($now - $state['window_start'] > $rate_limit_window) {
        $state = ['count' => 0, 'window_start' => $now];
    }
    $state['count']++;
    ftruncate($fh, 0);
    rewind($fh);
    fwrite($fh, json_encode($state));
    flock($fh, LOCK_UN);
    fclose($fh);
}

if ($state['count'] > $rate_limit_max) {
    $retry_after = $rate_limit_window - ($now - $state['window_start']);
    http_response_code(429);
    header('Retry-After: ' . $retry_after);
    echo json_encode(['error' => 'Too many requests. Please try again later.']);
    exit;
}

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
    
    $username = isset($all_headers['x-username']) ? substr(preg_replace('/[^a-zA-Z0-9_\-\s]/', '', $all_headers['x-username']), 0, 64) : 'anonymous';
    $category = isset($all_headers['x-category']) ? substr(preg_replace('/[^a-zA-Z0-9_\-\s]/', '', $all_headers['x-category']), 0, 64) : 'Uncategorized';
    $filename = isset($all_headers['x-filename']) ? substr(preg_replace('/[^a-zA-Z0-9_\-\.\s]/', '', $all_headers['x-filename']), 0, 128) : 'series_' . date('Ymd_His') . '.json';
    
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
