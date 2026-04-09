<?php
require_once 'config.php';

// Scan releases directory
$files = [];
if (is_dir(RELEASES_DIR)) {
    $dir_files = scandir(RELEASES_DIR);
    foreach ($dir_files as $file) {
        if ($file === '.' || $file === '..' || $file === '.htaccess') continue;
        $file_path = RELEASES_DIR . $file;
        if (is_file($file_path)) {
            $files[] = [
                'name' => $file,
                'size' => filesize($file_path),
                'mtime' => filemtime($file_path),
            ];
        }
    }
    // Sort by name (usually version number) descending
    usort($files, function($a, $b) {
        return strnatcmp($b['name'], $a['name']);
    });
}

function get_file_icon($filename) {
    if (stripos($filename, 'WearOS') !== false) return '⌚';
    if (stripos($filename, 'fenix') !== false || pathinfo($filename, PATHINFO_EXTENSION) === 'prg') return '⌚';
    if (pathinfo($filename, PATHINFO_EXTENSION) === 'apk') return '📱';
    return '📦';
}

function get_file_type_label($filename) {
    if (stripos($filename, 'WearOS') !== false) return 'Wear OS';
    if (stripos($filename, 'fenix') !== false || pathinfo($filename, PATHINFO_EXTENSION) === 'prg') return 'Garmin (Fenix 6)';
    if (pathinfo($filename, PATHINFO_EXTENSION) === 'apk') return 'Smartphone (Android)';
    return 'Autre';
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Téléchargements — JKDApp</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .download-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
            margin-top: 20px;
        }
        @media (min-width: 768px) {
            .download-grid {
                grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            }
        }
        .download-card {
            background: #fff;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            border: 1px solid #eee;
            display: flex;
            flex-direction: column;
            transition: transform 0.2s ease;
        }
        .download-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.1);
        }
        .file-icon {
            font-size: 2.5rem;
            margin-bottom: 15px;
            text-align: center;
        }
        .file-info {
            flex: 1;
        }
        .file-name {
            font-weight: 700;
            font-size: 1.1rem;
            margin-bottom: 5px;
            word-break: break-all;
        }
        .file-type {
            display: inline-block;
            background: #e1f5fe;
            color: #039be5;
            font-size: 0.75rem;
            font-weight: 700;
            padding: 2px 8px;
            border-radius: 10px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }
        .file-meta {
            font-size: 0.85rem;
            color: var(--text-light);
            margin-bottom: 15px;
        }
        .btn-download {
            width: 100%;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="nav">
                <a href="index.php" style="color: var(--text-light); text-decoration: none;">← Bibliothèque</a>
                <h1 style="margin: 0;">Releases JKDApp</h1>
            </div>
            <p>Téléchargez les dernières versions pour vos appareils.</p>
        </header>

        <div class="download-grid">
            <?php if (empty($files)): ?>
                <div class="card" style="grid-column: 1 / -1; text-align: center; padding: 40px;">
                    <p style="color: var(--text-light);">Aucune version disponible pour le moment.</p>
                </div>
            <?php else: ?>
                <?php foreach ($files as $file): ?>
                    <div class="download-card">
                        <div class="file-icon"><?php echo get_file_icon($file['name']); ?></div>
                        <div class="file-info">
                            <span class="file-type"><?php echo get_file_type_label($file['name']); ?></span>
                            <div class="file-name"><?php echo htmlspecialchars($file['name']); ?></div>
                            <div class="file-meta">
                                📅 <?php echo date('d/m/Y H:i', $file['mtime']); ?><br>
                                ⚖️ <?php echo format_bytes($file['size']); ?>
                            </div>
                        </div>
                        <a href="<?php echo RELEASES_DIR . rawurlencode($file['name']); ?>" class="btn-download" download>
                            <button type="button" style="width: 100%;">Télécharger</button>
                        </a>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>

        <footer style="text-align: center; margin-top: 40px; color: var(--text-light); font-size: 14px;">
            <p>JKDApp · <a href="index.php" style="color: var(--text-light); text-decoration: none;">Bibliothèque</a></p>
        </footer>
    </div>
</body>
</html>
