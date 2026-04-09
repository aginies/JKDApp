<?php
require_once 'config.php';

header('Content-Type: application/json');

write_log("API: Fetching series list");

$files = [];
if (is_dir(UPLOAD_DIR)) {
    $dir_files = scandir(UPLOAD_DIR);
    foreach ($dir_files as $file) {
        if ($file === '.' || $file === '..' || $file === '.htaccess') continue;
        $file_path = UPLOAD_DIR . $file;
        if (is_file($file_path)) {
            // Extract username and category from filename: category---username---filename.json
            $parts = explode('---', $file, 3);
            if (count($parts) >= 3) {
                $category = $parts[0];
                $username = $parts[1];
                $display_name = $parts[2];
            } else if (count($parts) == 2) {
                // Backward compatibility: user_filename.json
                $category = 'Autre';
                $username = str_replace('_', ' ', $parts[0]);
                $display_name = str_replace('_', ' ', $parts[1]);
            } else {
                // Older compatibility: filename.json
                $parts_old = explode('_', $file, 3);
                if (count($parts_old) >= 3) {
                    $category = str_replace('_', ' ', $parts_old[0]);
                    $username = str_replace('_', ' ', $parts_old[1]);
                    $display_name = str_replace('_', ' ', $parts_old[2]);
                } else {
                    $category = 'Autre';
                    $username = 'anonyme';
                    $display_name = str_replace('_', ' ', $file);
                }
            }

            $files[] = [
                'filename' => $file,
                'category' => $category,
                'user' => $username,
                'title' => str_ireplace('.json', '', $display_name),
                'size' => filesize($file_path),
                'date' => date('c', filemtime($file_path)),
                'url' => 'data/' . rawurlencode($file)
            ];
        }
    }
    // Sort by modification time (newest first)
    usort($files, function($a, $b) {
        return strtotime($b['date']) - strtotime($a['date']);
    });
}

echo json_encode($files);
?>
