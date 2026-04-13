<?php
require_once 'config.php';

// Group releases by category
$categories = [
    'smartphone' => ['label' => 'Smartphone (Android)', 'icon' => '📱', 'files' => []],
    'wearos'     => ['label' => 'Wear OS', 'icon' => '⌚', 'files' => []],
    'garmin'     => ['label' => 'Garmin', 'icon' => '⌚', 'files' => []],
    'other'      => ['label' => 'Autres', 'icon' => '📦', 'files' => []],
];

if (is_dir(RELEASES_DIR)) {
    $dir_files = scandir(RELEASES_DIR);
    foreach ($dir_files as $file) {
        if ($file === '.' || $file === '..' || $file === '.htaccess') continue;
        $file_path = RELEASES_DIR . $file;
        if (is_file($file_path)) {
            $file_info = [
                'name' => $file,
                'size' => filesize($file_path),
                'mtime' => filemtime($file_path),
            ];

            // Determine category
            if (stripos($file, 'WearOS') !== false) {
                $categories['wearos']['files'][] = $file_info;
            } elseif (stripos($file, 'fenix') !== false || pathinfo($file, PATHINFO_EXTENSION) === 'prg') {
                $categories['garmin']['files'][] = $file_info;
            } elseif (pathinfo($file, PATHINFO_EXTENSION) === 'apk') {
                $categories['smartphone']['files'][] = $file_info;
            } else {
                $categories['other']['files'][] = $file_info;
            }
        }
    }

    // Sort files within each category by name (version) descending
    foreach ($categories as $key => $cat) {
        usort($categories[$key]['files'], function($a, $b) {
            return strnatcmp($b['name'], $a['name']);
        });
    }
}

function format_garmin_label($filename) {
    $parts = explode('_', pathinfo($filename, PATHINFO_FILENAME));
    if (count($parts) >= 2) {
        $device_id = $parts[count($parts)-1];
        $label = ucfirst($device_id);
        $label = preg_replace('/(?<! )(\d+)/', ' $1', $label);
        $label = preg_replace('/(\d+) mm/', '$1mm', $label);
        $label = str_ireplace('pro', ' Pro', $label);
        $label = str_ireplace('solar', ' Solar', $label);
        return $label;
    }
    return 'Watch';
}

function format_wearos_compatibility($filename) {
    if (stripos($filename, 'arm64-v8a') !== false) {
        return 'Moderne : Pixel Watch 1/2, Galaxy Watch 4/5/6/7/Ultra, TicWatch Pro 5';
    }
    if (stripos($filename, 'armeabi-v7a') !== false) {
        return 'Legacy : Fossil Gen 5/6, TicWatch Pro 3/E3, Oppo Watch, Moto 360';
    }
    return 'Universel';
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Téléchargements Beta — JKDApp</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .category-section {
            margin-bottom: 40px;
        }
        .category-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--primary);
        }
        .category-header h2 {
            margin: 0;
            font-size: 1.5rem;
            color: var(--text-color);
        }
        .download-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
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
        .file-info {
            flex: 1;
        }
        .file-name {
            font-weight: 700;
            font-size: 1.1rem;
            margin-bottom: 5px;
            word-break: break-all;
        }
        .device-badge {
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
                <div style="display: flex; gap: 15px; align-items: center;">
                    <a href="index.php" style="color: var(--text-light); text-decoration: none;">← Bibliothèque</a>
                    <a href="privacy.php" style="color: var(--text-light); text-decoration: none; font-size: 0.9rem;">Confidentialité</a>
                </div>
                <h1 style="margin: 0;">Releases JKDApp <span style="font-size: 1rem; vertical-align: middle; background: #ff9800; color: white; padding: 2px 10px; border-radius: 4px; margin-left: 10px; font-weight: 800;">BETA</span></h1>
            </div>
            <p>Téléchargez les dernières versions pour vos appareils.</p>
        </header>

        <?php 
        $has_any_files = false;
        foreach ($categories as $key => $cat): 
            if (empty($cat['files'])) continue;
            $has_any_files = true;
        ?>
            <section class="category-section">
                <div class="category-header">
                    <span style="font-size: 1.5rem;"><?php echo $cat['icon']; ?></span>
                    <h2><?php echo $cat['label']; ?></h2>
                </div>
                
                <div class="download-grid">
                    <?php foreach ($cat['files'] as $file): ?>
                        <div class="download-card">
                            <div class="file-info">
                                <?php if ($key === 'garmin'): ?>
                                    <span class="device-badge"><?php echo format_garmin_label($file['name']); ?></span>
                                <?php elseif ($key === 'wearos'): ?>
                                    <span class="device-badge" style="background: #f3e5f5; color: #7b1fa2;"><?php echo format_wearos_compatibility($file['name']); ?></span>
                                <?php endif; ?>
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
                </div>
            </section>
        <?php endforeach; ?>

        <?php if (!$has_any_files): ?>
            <div class="card" style="text-align: center; padding: 40px;">
                <p style="color: var(--text-light);">Aucune version disponible pour le moment.</p>
            </div>
        <?php endif; ?>

        <footer style="text-align: center; margin-top: 40px; color: var(--text-light); font-size: 14px;">
            <p>JKDApp · <a href="index.php" style="color: var(--text-light); text-decoration: none;">Bibliothèque</a></p>
        </footer>
    </div>
</body>
</html>
