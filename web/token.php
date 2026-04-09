<?php
require_once 'config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed. Use POST.']);
    exit;
}

// Rate limiting: max 10 token requests per IP per hour
$rate_limit_max    = 10;
$rate_limit_window = 3600;
$client_ip         = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$rate_file         = sys_get_temp_dir() . '/jkdapp_tkrl_' . md5($client_ip) . '.json';
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

// Validate the shared app secret
$headers = array_change_key_case(getallheaders(), CASE_LOWER);
$secret  = $headers['x-app-secret'] ?? '';

if (!$secret || !hash_equals(APP_SECRET, $secret)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized: Invalid app secret']);
    exit;
}

// Issue a signed token: {timestamp}.{hmac}
$ts    = $now;
$hmac  = hash_hmac('sha256', (string)$ts, TOKEN_SIGNING_KEY);
$token = $ts . '.' . $hmac;

echo json_encode([
    'token'      => $token,
    'expires_at' => $ts + TOKEN_TTL,
]);
