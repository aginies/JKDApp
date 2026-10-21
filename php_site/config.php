<?php
// Configuration for JKDApp Web Storage
define('UPLOAD_DIR', 'data/');
define('RELEASES_DIR', 'releases/');
define('ADMIN_USER', 'aginies');

// Secrets are stored in secrets.php — never commit that file.
require_once __DIR__ . '/secrets.php';

// Token lifetime in seconds
define('TOKEN_TTL', 3600);

// Max file size allowed (in bytes) - 300KB (allows series and custom angles)
define('MAX_FILE_SIZE', 300 * 1024);

// Allowed file extensions
define('ALLOWED_EXTENSIONS', ['json']);

// Private runtime cache directory for rate limiting (not world-writable /tmp)
define('CACHE_DIR', __DIR__ . '/data/.cache/');

// Logging configuration
define('LOG_FILE', __DIR__ . '/logs/app.log');

/**
 * Resolve client IP address safely, checking trusted reverse proxy headers if configured.
 */
function get_client_ip(): string {
    if (defined('TRUST_PROXY') && TRUST_PROXY && !empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        $candidate = trim($ips[0]);
        if (filter_var($candidate, FILTER_VALIDATE_IP)) {
            return $candidate;
        }
    }
    $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    return filter_var($ip, FILTER_VALIDATE_IP) ? $ip : '127.0.0.1';
}

/**
 * Get a secure path for rate limiting / runtime state files.
 * Stored in a private, non-world-writable directory instead of /tmp.
 */
function get_rate_limit_file(string $prefix, string $identifier): string {
    if (!is_dir(CACHE_DIR)) {
        @mkdir(CACHE_DIR, 0700, true);
        if (file_exists(CACHE_DIR)) {
            @chmod(CACHE_DIR, 0700);
        }
    }
    return CACHE_DIR . $prefix . '_' . hash('sha256', $identifier) . '.json';
}

/**
 * Log a message to the application log file with restrictive permissions.
 */
function write_log($message, $level = 'INFO') {
    $log_dir = __DIR__ . '/logs';
    if (!is_dir($log_dir)) {
        @mkdir($log_dir, 0700, true);
        if (file_exists($log_dir)) {
            @chmod($log_dir, 0700);
        }
    }
    $date = date('Y-m-d H:i:s');
    $ip = get_client_ip();
    // Neutralize CR/LF so user-derived data cannot forge additional log lines.
    $message = str_replace(["\r", "\n"], ' ', (string)$message);
    if (strlen($message) > 1024) {
        $message = substr($message, 0, 1024) . '... [truncated]';
    }
    $log_entry = "[$date] [$level] [$ip] $message" . PHP_EOL;
    file_put_contents(LOG_FILE, $log_entry, FILE_APPEND | LOCK_EX);
    if (file_exists(LOG_FILE)) {
        @chmod(LOG_FILE, 0600);
    }
}

/**
 * Send CORS headers so the Flutter web build (served from a different
 * origin) can call the API endpoints.
 *
 * A wildcard origin is safe here: no cookies or credentials are involved,
 * and the app secret / tokens travel in request headers (already public in
 * the app binaries, so CORS grants no additional access).
 *
 * Also answers OPTIONS preflight requests, which the browser sends before
 * any POST that uses custom headers (X-Token, X-App-Secret, ...).
 */
function send_cors_headers() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-Token, X-App-Secret, X-USERNAME, X-FILENAME, X-CATEGORY');
    header('Access-Control-Max-Age: 86400');

    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
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
    $timestamp = (int) $ts;
    $now       = time();
    // Reject non-numeric, future-dated, or over-aged timestamps. The HMAC
    // check below still prevents forgery; this is defense-in-depth.
    if (!ctype_digit($ts) || $timestamp > $now || ($now - $timestamp) > TOKEN_TTL) {
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
