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
            
            <table id="series-table">
                <thead>
                    <tr>
                        <th class="sortable" data-col="0">Catégorie <span class="sort-icon"></span></th>
                        <th class="sortable" data-col="1">Contributeur <span class="sort-icon"></span></th>
                        <th class="sortable" data-col="2">Nom de la Série <span class="sort-icon"></span></th>
                        <th class="sortable" data-col="3">Taille <span class="sort-icon"></span></th>
                        <th class="sortable" data-col="4">Partagé le <span class="sort-icon"></span></th>
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
                        <td data-sort="<?php echo htmlspecialchars($file['category']); ?>">
                            <span class="badge" style="background: #fff3e0; color: #e65100; font-weight: 600;">
                                <?php echo htmlspecialchars($file['category']); ?>
                            </span>
                        </td>
                        <td data-sort="<?php echo htmlspecialchars($file['user']); ?>">
                            <span class="badge" style="background: #e3f2fd; color: #1976d2; font-weight: 600;">
                                @<?php echo htmlspecialchars($file['user']); ?>
                            </span>
                        </td>
                        <td data-sort="<?php echo htmlspecialchars(str_ireplace('.json', '', $file['display'])); ?>" style="font-weight: 500;"><?php echo htmlspecialchars(str_ireplace('.json', '', $file['display'])); ?></td>
                        <td data-sort="<?php echo (int)$file['size']; ?>"><?php echo format_bytes($file['size']); ?></td>
                        <td data-sort="<?php echo (int)$file['mtime']; ?>" style="color: var(--text-light);">
                            <?php
                                setlocale(LC_TIME, 'fr_FR.UTF-8');
                                echo date('d/m/Y', $file['mtime']);
                            ?>
                        </td>
                        <td style="white-space: nowrap;">
                            <a href="preview.php?file=<?php echo urlencode($file['name']); ?>" title="Prévisualiser">
                                <button type="button" class="btn-icon" style="background: var(--success);">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                </button>
                            </a>
                            <a href="<?php echo htmlspecialchars('data/' . rawurlencode($file['name'])); ?>" download title="Télécharger">
                                <button type="button" class="btn-icon">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                                </button>
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
    <style>
        th.sortable { cursor: pointer; user-select: none; }
        th.sortable:hover { background: #edf2f7; }
        th.sortable[data-sort-dir] { color: var(--primary); }
        .sort-icon { font-size: 0.75em; opacity: 0.6; }
    </style>
    <script>
        document.querySelectorAll('#series-table th.sortable').forEach(th => {
            th.addEventListener('click', () => {
                const col  = parseInt(th.dataset.col);
                const tbody = document.querySelector('#series-table tbody');
                const rows  = Array.from(tbody.querySelectorAll('tr')).filter(r => r.cells.length > 1);
                const asc   = th.dataset.sortDir !== 'asc';

                document.querySelectorAll('#series-table th.sortable').forEach(h => {
                    delete h.dataset.sortDir;
                    h.querySelector('.sort-icon').textContent = '';
                });

                th.dataset.sortDir = asc ? 'asc' : 'desc';
                th.querySelector('.sort-icon').textContent = asc ? '▲' : '▼';

                rows.sort((a, b) => {
                    const av = a.cells[col].dataset.sort ?? a.cells[col].textContent.trim();
                    const bv = b.cells[col].dataset.sort ?? b.cells[col].textContent.trim();
                    const an = parseFloat(av), bn = parseFloat(bv);
                    if (!isNaN(an) && !isNaN(bn)) return asc ? an - bn : bn - an;
                    return asc ? av.localeCompare(bv, 'fr') : bv.localeCompare(av, 'fr');
                });

                rows.forEach(r => tbody.appendChild(r));
            });
        });
    </script>
</body>
</html>
