<?php
require_once 'config.php';

send_cors_headers();

// Set response headers
header('Content-Type: application/json');

// Only allow POST requests for uploads
$method = $_SERVER['REQUEST_METHOD'] ?? '';
if ($method !== 'POST') {
    write_log("Invalid request method: " . ($method ?: 'CLI/Empty'), 'WARN');
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed. Use POST.']);
    exit;
}

// Verify the short-lived HMAC token
verify_token();

write_log("API: Processing upload attempt");

// Rate limiting: max 30 uploads per IP per hour (locked read+write to avoid race)
$rate_limit_max    = 30;
$rate_limit_window = 3600; // seconds
$client_ip         = get_client_ip();
$rate_file         = get_rate_limit_file('rl', $client_ip);
$now               = time();
$state             = ['count' => 0, 'window_start' => $now];

$fh = @fopen($rate_file, 'c+');
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
    write_log("Rate limit exceeded", 'WARN');
    http_response_code(429);
    header('Retry-After: ' . $retry_after);
    echo json_encode(['error' => 'Too many requests. Please try again later.']);
    exit;
}

/**
 * Decode and sanitize header values while allowing accented characters.
 */
function sanitize_header($value, $default, $maxlen) {
    if (!isset($value)) return $default;
    // Decode URL component (matches Flutter Uri.encodeComponent)
    $decoded = rawurldecode($value);
    // Remove raw NUL bytes and other control characters.
    $decoded = preg_replace('/[[:cntrl:]]/', '', $decoded);
    // Remove truly dangerous filename characters but allow accents (\x7f-\xff)
    $clean = preg_replace('/[<>:"\/\\\|?*]/', '', $decoded);
    // Trim, then reject empty results and leading dots
    $clean = trim($clean);
    if ($clean === '' || $clean[0] === '.') {
        return $default;
    }
    return substr($clean, 0, $maxlen);
}

/**
 * Validate that the decoded JSON payload matches expected JKDApp series or custom angle structure.
 */
function validate_series_payload($decoded, string $category): bool {
    if (!is_array($decoded)) {
        return false;
    }
    if ($category === 'Custom Angles') {
        foreach ($decoded as $item) {
            if (!is_array($item)) return false;
        }
        return true;
    }
    // Single series: must have 'title' string
    if (isset($decoded['title']) && is_string($decoded['title']) && trim($decoded['title']) !== '') {
        return true;
    }
    // Array of series: list where each item has 'title' string
    $is_list = function_exists('array_is_list') 
        ? array_is_list($decoded) 
        : (empty($decoded) || array_keys($decoded) === range(0, count($decoded) - 1));

    if (!empty($decoded) && $is_list) {
        foreach ($decoded as $series) {
            if (!is_array($series) || !isset($series['title']) || !is_string($series['title']) || trim($series['title']) === '') {
                return false;
            }
        }
        return true;
    }
    return false;
}

// Handle JSON upload
$content_type = isset($_SERVER["CONTENT_TYPE"]) ? $_SERVER["CONTENT_TYPE"] : '';

if (strpos($content_type, "application/json") !== false) {
    // Read raw JSON from request body
    $json_data = file_get_contents('php://input');
    
    if (empty($json_data)) {
        write_log("Empty request body", 'ERROR');
        http_response_code(400);
        echo json_encode(['error' => 'Empty request body']);
        exit;
    }

    // Check file size
    if (strlen($json_data) > MAX_FILE_SIZE) {
        write_log("File too large: " . strlen($json_data) . " bytes", 'ERROR');
        http_response_code(413);
        echo json_encode(['error' => 'File too large (max ' . format_bytes(MAX_FILE_SIZE) . ')']);
        exit;
    }
    
    // Validate JSON structure
    $decoded = json_decode($json_data, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        write_log("Invalid JSON: " . json_last_error_msg(), 'ERROR');
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON payload: ' . json_last_error_msg()]);
        exit;
    }
    
    // Extract username and filename from headers (case-insensitive)
    $all_headers = array_change_key_case(getallheaders(), CASE_LOWER);

    $username = sanitize_header($all_headers['x-username'] ?? null, 'anonymous', 64);
    $category = sanitize_header($all_headers['x-category'] ?? null, 'Uncategorized', 64);
    $filename = sanitize_header($all_headers['x-filename'] ?? null, 'series_' . date('Ymd_His') . '.json', 128);

    // Validate payload against expected schema
    if (!validate_series_payload($decoded, $category)) {
        write_log("Rejected upload: Invalid series/angle structure", 'WARN');
        http_response_code(422);
        echo json_encode(['error' => 'Invalid series payload structure: missing required title or invalid format']);
        exit;
    }
    
    // Prevent multi-extension execution: strip all dots and special chars from filename base
    $raw_name_part = pathinfo($filename, PATHINFO_FILENAME);
    $clean_base = preg_replace('/[^a-zA-Z0-9_\-]/', '_', $raw_name_part);
    $clean_base = trim(preg_replace('/_+/', '_', $clean_base), '_');
    if ($clean_base === '') {
        $clean_base = 'series_' . date('Ymd_His');
    }
    $base_filename = $clean_base . '.json';

    // Prefix filename with username and category for triage: category---username---filename.json
    $safe_username = preg_replace('/[^a-zA-Z0-9_\- \x7f-\xff]/', '_', $username);
    $safe_username = str_replace('---', '-', trim($safe_username));
    if ($safe_username === '') $safe_username = 'anonymous';

    $safe_category = preg_replace('/[^a-zA-Z0-9_\- \x7f-\xff]/', '_', $category);
    $safe_category = str_replace('---', '-', trim($safe_category));
    if ($safe_category === '') $safe_category = 'Uncategorized';
    
    // Create directory if not exists
    if (!is_dir(UPLOAD_DIR)) {
        mkdir(UPLOAD_DIR, 0755, true);
    }
    
    $final_filename = $safe_category . '---' . $safe_username . '---' . $base_filename;
    
    // Non-overwriting logic: append _A, _B, etc. if file exists
    $suffix = '';
    if (file_exists(UPLOAD_DIR . $final_filename)) {
        $suffix_letter = 'A';
        $name_part = pathinfo($base_filename, PATHINFO_FILENAME);
        $ext_part  = pathinfo($base_filename, PATHINFO_EXTENSION);
        
        do {
            $current_suffix = '_' . $suffix_letter;
            $final_filename = $safe_category . '---' . $safe_username . '---' . $name_part . $current_suffix . '.' . $ext_part;
            $suffix_letter++; // PHP magic: 'A' -> 'B', 'Z' -> 'AA'
        } while (file_exists(UPLOAD_DIR . $final_filename));
        
        $suffix = $current_suffix;
    }

    // If suffix was added, update the title inside JSON
    if ($suffix !== '') {
        $decoded = json_decode($json_data, true);
        // Handle both single series and array of series
        if (json_last_error() === JSON_ERROR_NONE) {
            if (isset($decoded['title'])) {
                // Single series
                $decoded['title'] .= ' ' . trim($suffix, '_');
            } elseif (is_array($decoded)) {
                // Potential array of series
                foreach ($decoded as &$s) {
                    if (isset($s['title'])) {
                        $s['title'] .= ' ' . trim($suffix, '_');
                    }
                }
                unset($s);
            }
            $json_data = json_encode($decoded, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        }
    }
    
    // Save to file
    $target_path = UPLOAD_DIR . $final_filename;
    if (file_put_contents($target_path, $json_data)) {
        write_log("Upload success: $final_filename (User: $username, Size: " . strlen($json_data) . " bytes)");
        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'message' => 'File saved successfully' . ($suffix ? " as duplicate ($suffix)" : ""),
            'filename' => $final_filename,
            'display_name' => str_replace($safe_category . '---' . $safe_username . '---', '', $final_filename),
            'user' => $username,
            'size' => format_bytes(strlen($json_data))
        ]);
    } else {
        write_log("Failed to save file: $target_path", 'ERROR');
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save file to server storage']);
    }
} else {
    write_log("Unsupported content type: $content_type", 'WARN');
    http_response_code(400);
    echo json_encode(['error' => 'Unsupported content type. Must be application/json']);
}
?>
