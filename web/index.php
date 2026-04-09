<?php
require_once 'config.php';

// Public file listing logic
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
                'name' => $file,
                'category' => $category,
                'user' => $username,
                'display' => $display_name,
                'size' => filesize($file_path),
                'mtime' => filemtime($file_path),
                'path' => $file_path
            ];
        }
    }
    // Sort by modification time (newest first)
    usort($files, function($a, $b) {
        return $b['mtime'] - $a['mtime'];
    });
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Bibliothèque Publique JKDApp</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .public-header {
            background: linear-gradient(135deg, #3498db, #2980b9);
            color: white;
            padding: 40px 20px;
            border-radius: var(--border-radius);
            margin-bottom: 30px;
            text-align: center;
            box-shadow: var(--shadow);
        }
        .public-header h1 { color: white; margin: 0; }
        .public-header p { opacity: 0.9; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="public-header">
            <h1>Bibliothèque JKDApp</h1>
            <p>Explorez et téléchargez les séries partagées par la communauté.</p>
        </div>

        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h3 style="margin: 0;">Séries Partagées</h3>
                <span class="badge badge-json"><?php echo count($files); ?> Séries au total</span>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Catégorie</th>
                        <th>Contributeur</th>
                        <th>Nom de la Série</th>
                        <th>Taille</th>
                        <th>Partagé le</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($files)): ?>
                        <tr>
                            <td colspan="6" style="text-align: center; color: var(--text-light); padding: 40px;">Aucune série partagée pour le moment. Soyez le premier !</td>
                        </tr>
                    <?php endif; ?>
                    <?php foreach ($files as $file): ?>
                    <tr>
                        <td>
                            <span class="badge" style="background: #fff3e0; color: #e65100; font-weight: 600;">
                                <?php echo htmlspecialchars($file['category']); ?>
                            </span>
                        </td>
                        <td>
                            <span class="badge" style="background: #e3f2fd; color: #1976d2; font-weight: 600;">
                                @<?php echo htmlspecialchars($file['user']); ?>
                            </span>
                        </td>
                        <td style="font-weight: 500;"><?php echo htmlspecialchars(str_ireplace('.json', '', $file['display'])); ?></td>
                        <td><?php echo format_bytes($file['size']); ?></td>
                        <td style="color: var(--text-light);">
                            <?php 
                                setlocale(LC_TIME, 'fr_FR.UTF-8');
                                echo date('d/m/Y', $file['mtime']); 
                            ?>
                        </td>
                        <td>
                            <a href="<?php echo htmlspecialchars($file['path']); ?>" download>
                                <button type="button" style="padding: 8px 16px; font-size: 14px;">Télécharger</button>
                            </a>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        
        <footer style="text-align: center; margin-top: 40px; color: var(--text-light); font-size: 14px;">
            <p>&copy; 2026 Communauté JKDApp. <a href="admin.php" style="color: var(--text-light); text-decoration: none;">Accès Admin</a></p>
        </footer>
    </div>
</body>
</html>
