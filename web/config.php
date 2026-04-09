<?php
// Configuration for JKDApp Web Storage
define('UPLOAD_DIR', 'data/');
define('ADMIN_USER', 'aginies');

// Secrets are stored in secrets.php — never commit that file.
require_once __DIR__ . '/secrets.php';

// Token lifetime in seconds
define('TOKEN_TTL', 3600);

// Max file size allowed (in bytes) - 100KB
define('MAX_FILE_SIZE', 100 * 1024);

// Allowed file extensions
define('ALLOWED_EXTENSIONS', ['json']);

// Logging configuration
define('LOG_FILE', __DIR__ . '/logs/app.log');

/**
 * Log a message to the application log file.
 */
function write_log($message, $level = 'INFO') {
    if (!is_dir(__DIR__ . '/logs')) {
        mkdir(__DIR__ . '/logs', 0755, true);
    }
    $date = date('Y-m-d H:i:s');
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $log_entry = "[$date] [$level] [$ip] $message" . PHP_EOL;
    file_put_contents(LOG_FILE, $log_entry, FILE_APPEND);
}

/**
 * Reject a request with 401 and exit.
 */
function reject(string $message = 'Unauthorized') {
    write_log("REJECT: $message", 'WARN');
    http_response_code(401);
    echo json_encode(['error' => $message]);
    exit;
}

/**
 * Validate the X-Token header: checks HMAC signature and expiry.
 */
function verify_token() {
    $headers = array_change_key_case(getallheaders(), CASE_LOWER);
    $token   = $headers['x-token'] ?? '';
    $parts   = explode('.', $token, 2);

    if (count($parts) !== 2) {
        reject('Unauthorized: missing or malformed token');
    }

    [$ts, $hmac] = $parts;
    if (!ctype_digit($ts) || (time() - (int)$ts) > TOKEN_TTL) {
        reject('Unauthorized: token expired');
    }

    $expected = hash_hmac('sha256', $ts, TOKEN_SIGNING_KEY);
    if (!hash_equals($expected, $hmac)) {
        reject('Unauthorized: invalid token');
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
