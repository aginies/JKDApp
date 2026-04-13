<?php
require_once 'config.php';

// Set response headers
header('Content-Type: application/json');

// Only allow POST requests for uploads
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    write_log("Invalid request method: " . $_SERVER['REQUEST_METHOD'], 'WARN');
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
    write_log("Rate limit exceeded", 'WARN');
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
    $decoded = json_decode($json_data);
    if (json_last_error() !== JSON_ERROR_NONE) {
        write_log("Invalid JSON: " . json_last_error_msg(), 'ERROR');
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON payload: ' . json_last_error_msg()]);
        exit;
    }
    
    // Extract username and filename from headers (case-insensitive)
    $all_headers = array_change_key_case(getallheaders(), CASE_LOWER);
    
    /**
     * Decode and sanitize header values while allowing accented characters.
     */
    function sanitize_header($value, $default, $maxlen) {
        if (!isset($value)) return $default;
        // Decode URL component (matches Flutter Uri.encodeComponent)
        // rawurldecode handles %20 correctly as space, matches encodeComponent
        $decoded = rawurldecode($value);
        // Remove truly dangerous filename characters but allow accents (\x7f-\xff)
        $clean = preg_replace('/[<>:"\/\\\|?*]/', '', $decoded);
        // Trim and limit length
        return substr(trim($clean), 0, $maxlen);
    }

    $username = sanitize_header($all_headers['x-username'] ?? null, 'anonymous', 64);
    $category = sanitize_header($all_headers['x-category'] ?? null, 'Uncategorized', 64);
    $filename = sanitize_header($all_headers['x-filename'] ?? null, 'series_' . date('Ymd_His') . '.json', 128);
    
    // Ensure filename ends with .json
    if (pathinfo($filename, PATHINFO_EXTENSION) !== 'json') {
        $filename .= '.json';
    }

    // Prefix filename with username and category for triage: category---username---filename.json
    $safe_username = str_replace('---', '-', $username);
    $safe_category = str_replace('---', '-', $category);
    $base_filename = str_replace('---', '-', $filename);
    
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
