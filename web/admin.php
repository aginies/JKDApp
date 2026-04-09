<?php
require_once 'config.php';
session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/',
    'secure'   => true,
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_start();

// Ensure a CSRF token exists for this session
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// Logout logic
if (isset($_GET['logout'])) {
    session_unset();
    session_destroy();
    header('Location: admin.php');
    exit;
}

// Delete logic
if (isset($_POST['delete_file']) && isset($_SESSION['loggedin'])) {
    if (empty($_POST['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) {
        http_response_code(403);
        die('Invalid CSRF token.');
    }
    $file_to_delete = basename($_POST['delete_file']);
    $file_path = UPLOAD_DIR . $file_to_delete;
    if (file_exists($file_path) && is_file($file_path)) {
        unlink($file_path);
        $message = "Le fichier '$file_to_delete' a été supprimé avec succès.";
    }
}

// Login logic — brute-force protection: max 5 attempts per 15 minutes per IP
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login'])) {
    $user      = $_POST['username'];
    $pass      = $_POST['password'];
    $now       = time();
    $bf_max    = 5;
    $bf_window = 900; // 15 minutes
    $bf_file   = sys_get_temp_dir() . '/jkdapp_bf_' . md5($_SERVER['REMOTE_ADDR'] ?? '') . '.json';
    $bf_state  = ['count' => 0, 'window_start' => $now];
    $locked    = false;

    $fh = fopen($bf_file, 'c+');
    if ($fh && flock($fh, LOCK_EX)) {
        $raw = stream_get_contents($fh);
        if ($raw) {
            $bf_state = json_decode($raw, true) ?? $bf_state;
        }
        if ($now - $bf_state['window_start'] > $bf_window) {
            $bf_state = ['count' => 0, 'window_start' => $now];
        }
        if ($bf_state['count'] >= $bf_max) {
            $remaining = $bf_window - ($now - $bf_state['window_start']);
            $error  = "Trop de tentatives. Réessayez dans " . ceil($remaining / 60) . " minute(s).";
            $locked = true;
        }
    }

    if (!$locked) {
        if ($user === ADMIN_USER && password_verify($pass, ADMIN_PASS_HASH)) {
            $bf_state = ['count' => 0, 'window_start' => $now];
            session_regenerate_id(true);
            $_SESSION['loggedin'] = true;
        } else {
            $bf_state['count']++;
            $error = "Nom d'utilisateur ou mot de passe incorrect.";
        }
    }

    if ($fh) {
        ftruncate($fh, 0);
        rewind($fh);
        fwrite($fh, json_encode($bf_state));
        flock($fh, LOCK_UN);
        fclose($fh);
    }
}

// Handle non-logged in state
if (!isset($_SESSION['loggedin'])) {
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Connexion Admin JKDApp</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
    <div class="login-form card">
        <h2>Stockage JKDApp</h2>
        <p>Veuillez vous connecter pour gérer les fichiers JSON.</p>
        <?php if ($error): ?>
            <div class="alert alert-error"><?php echo $error; ?></div>
        <?php endif; ?>
        <form method="POST">
            <div class="form-group">
                <label>Nom d'utilisateur</label>
                <input type="text" name="username" required autocomplete="username">
            </div>
            <div class="form-group">
                <label>Mot de passe</label>
                <input type="password" name="password" required autocomplete="current-password">
            </div>
            <button type="submit" name="login">Se connecter</button>
        </form>
    </div>
</body>
</html>
<?php
    exit;
}

// Main Dashboard logic
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
    <title>Console Admin JKDApp</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
    <div class="container">
        <div class="nav">
            <h2>Gestion du Stockage JKDApp</h2>
            <a href="?logout" class="logout-link">Déconnexion</a>
        </div>

        <?php if (isset($message)): ?>
            <div class="alert" style="background: var(--success); color: white;">
                <?php echo htmlspecialchars($message, ENT_QUOTES, 'UTF-8'); ?>
            </div>
        <?php endif; ?>

        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h3 style="margin: 0;">Fichiers JSON Stockés</h3>
                <span class="badge badge-json"><?php echo count($files); ?> Fichiers</span>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Catégorie</th>
                        <th>Utilisateur</th>
                        <th>Nom du Fichier</th>
                        <th>Taille</th>
                        <th>Date d'Upload</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($files)): ?>
                        <tr>
                            <td colspan="6" style="text-align: center; color: var(--text-light);">Aucun fichier n'a été uploadé.</td>
                        </tr>
                    <?php endif; ?>
                    <?php foreach ($files as $file): ?>
                    <tr>
                        <td>
                            <span class="badge" style="background: #fff3e0; color: #e65100; font-weight: 600;"><?php echo htmlspecialchars($file['category']); ?></span>
                        </td>
                        <td>
                            <span class="badge" style="background: #e8f5e9; color: #2e7d32;"><?php echo htmlspecialchars($file['user']); ?></span>
                        </td>
                        <td style="font-weight: 500;"><?php echo htmlspecialchars(str_ireplace('.json', '', $file['display'])); ?></td>
                        <td><?php echo format_bytes($file['size']); ?></td>
                        <td style="color: var(--text-light);">
                            <?php echo date('d/m/Y H:i', $file['mtime']); ?>
                        </td>
                        <td class="actions">
                            <a href="<?php echo htmlspecialchars($file['path']); ?>" download>
                                <button type="button">Télécharger</button>
                            </a>
                            <form method="POST" onsubmit="return confirm('Êtes-vous sûr de vouloir supprimer ce fichier ?');" style="display: inline;">
                                <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars($_SESSION['csrf_token'], ENT_QUOTES, 'UTF-8'); ?>">
                                <input type="hidden" name="delete_file" value="<?php echo htmlspecialchars($file['name']); ?>">
                                <button type="submit" class="btn-danger">Supprimer</button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        
        <footer style="text-align: center; margin-top: 40px;">
            <a href="index.php" style="color: var(--text-light); text-decoration: none;">&larr; Retour à la bibliothèque publique</a>
        </footer>
    </div>
</body>
</html>
