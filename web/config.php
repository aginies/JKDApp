<?php
// Configuration for JKDApp Web Storage
define('UPLOAD_DIR', 'data/');
define('ADMIN_USER', 'aginies');

// Secrets (password hash and API key) are stored in secrets.php — never commit that file.
require_once __DIR__ . '/secrets.php';

// Max file size allowed (in bytes) - 100KB
define('MAX_FILE_SIZE', 100 * 1024);

// Allowed file extensions
define('ALLOWED_EXTENSIONS', ['json']);

/**
 * Utility to verify API key in headers
 */
function verify_api_key() {
    $headers = getallheaders();
    $provided_key = isset($headers['X-API-KEY']) ? $headers['X-API-KEY'] : (isset($headers['x-api-key']) ? $headers['x-api-key'] : null);
    
    if (!$provided_key || $provided_key !== APP_API_KEY) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized: Invalid API Key']);
        exit;
    }
}

/**
 * Utility to format bytes into readable strings
 */
function format_bytes($bytes, $precision = 2) {
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= pow(1024, $pow);
    return round($bytes, $precision) . ' ' . $units[$pow];
}
?>
