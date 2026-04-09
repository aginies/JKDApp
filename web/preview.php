<?php
require_once 'config.php';

// Security: validate file parameter
$filename = isset($_GET['file']) ? basename($_GET['file']) : '';
if (empty($filename) || pathinfo($filename, PATHINFO_EXTENSION) !== 'json') {
    http_response_code(400);
    die('Fichier invalide.');
}

$filepath = UPLOAD_DIR . $filename;
if (!file_exists($filepath) || !is_file($filepath)) {
    http_response_code(404);
    die('Fichier introuvable.');
}

$json = file_get_contents($filepath);
$data = json_decode($json, true);
if ($data === null) {
    http_response_code(400);
    die('JSON invalide.');
}

// Normalize: handle both single-series object and array of series
$series_list = isset($data['title']) ? [$data] : array_values($data);

// Recursively decode nested move JSON strings and translations
function decode_moves(array $raw): array {
    $result = [];
    foreach ($raw as $m) {
        foreach (['sub_moves_json', 'chain_json', 'counter_sub_moves_json', 'counter_chain_json'] as $key) {
            if (!empty($m[$key]) && is_string($m[$key])) {
                $nested    = json_decode($m[$key], true);
                $m[$key]   = is_array($nested) ? decode_moves($nested) : [];
            } else {
                $m[$key] = [];
            }
        }
        foreach (['translations', 'counter_translations'] as $key) {
            if (!empty($m[$key]) && is_string($m[$key])) {
                $m[$key] = json_decode($m[$key], true) ?? [];
            } elseif (!is_array($m[$key] ?? null)) {
                $m[$key] = [];
            }
        }
        $result[] = $m;
    }
    return $result;
}

foreach ($series_list as &$s) {
    if (!empty($s['moves']) && is_array($s['moves'])) {
        $s['moves'] = decode_moves($s['moves']);
    } else {
        $s['moves'] = [];
    }
}
unset($s);

// ── Rendering helpers ──────────────────────────────────────────────────────

function cat_color(string $cat): string {
    return match ($cat) {
        'punch'        => '#e74c3c',
        'kick'         => '#3498db',
        'packs'        => '#e67e22',
        'trapping'     => '#9b59b6',
        'simultaneous' => '#16a085',
        'chain'        => '#2c3e50',
        'combo'        => '#8e44ad',
        'kali'         => '#d4ac0d',
        'general'      => '#1abc9c',
        'move'         => '#95a5a6',
        'text'         => '#7f8c8d',
        default        => '#7f8c8d',
    };
}

function cat_icon(string $cat): string {
    return match ($cat) {
        'punch'        => '✊',
        'kick'         => '🦵',
        'packs'        => '📦',
        'trapping'     => '🤲',
        'simultaneous' => '🔄',
        'chain'        => '⛓',
        'combo'        => '💥',
        'kali'         => '⚔',
        'general'      => '◎',
        'move'         => '↕',
        'text'         => '📝',
        default        => '•',
    };
}

function side_color(string $side): string {
    return match ($side) {
        'L'     => '#3498db',
        'R'     => '#e74c3c',
        'M'     => '#27ae60',
        'F'     => '#1abc9c',
        'B'     => '#795548',
        default => '#95a5a6',
    };
}

function level_symbol(string $level): string {
    return match ($level) {
        'High'  => '▲',
        'Mid'   => '●',
        'Low'   => '▼',
        default => '',
    };
}

function render_badges(array $m, bool $is_counter = false): string {
    $prefix  = $is_counter ? 'counter_' : '';
    $side    = $m[$prefix . 'side']           ?? '';
    $level   = $m[$prefix . 'level']          ?? '';
    $special = $m[$prefix . 'special_action'] ?? '';
    $feint   = !empty($m[$prefix . 'is_feint']);
    $reps    = (int)($m['repetitions']        ?? 1);
    $html    = '';

    if ($side)    $html .= '<span class="badge-side" style="background:' . side_color($side) . '">' . htmlspecialchars($side) . '</span>';
    if ($level)   $html .= '<span class="badge-level">' . level_symbol($level) . ' ' . htmlspecialchars($level) . '</span>';
    if ($special) $html .= '<span class="badge-special">' . htmlspecialchars($special) . '</span>';
    if ($feint)   $html .= '<span class="badge-feint">Feint</span>';
    if (!$is_counter && $reps > 1) $html .= '<span class="badge-rep">×' . $reps . '</span>';

    return $html;
}

function render_simple_move(array $m, bool $is_sub = false): string {
    $cat   = $m['category'] ?? 'other';
    $color = cat_color($cat);
    $icon  = cat_icon($cat);
    $name  = htmlspecialchars($m['name'] ?? '');

    return '<span class="move-cat-icon" style="background:' . $color . '">' . $icon . '</span>'
         . '<span class="move-name">' . $name . '</span>'
         . render_badges($m);
}

function render_move(array $m, string $num_label = ''): string {
    $cat           = $m['category'] ?? 'other';
    $sub_moves     = $m['sub_moves_json']         ?? [];
    $chain         = $m['chain_json']             ?? [];
    $counter_name  = $m['counter_name']           ?? '';
    $counter_sub   = $m['counter_sub_moves_json'] ?? [];
    $counter_chain = $m['counter_chain_json']     ?? [];
    $is_combo      = !empty($sub_moves);
    $is_chain      = !empty($chain);
    $has_counter   = !empty($counter_name) || !empty($counter_sub) || !empty($counter_chain);

    $html = '<div class="move-card">';

    // Row: number + content
    $html .= '<div class="move-row">';

    // Number circle
    if ($num_label !== '') {
        $html .= '<div class="move-num">' . htmlspecialchars($num_label) . '</div>';
    } else {
        $html .= '<div class="move-num-empty"></div>';
    }

    $html .= '<div class="move-body">';

    // ── Main content ──
    if ($is_combo || $is_chain) {
        $items = $is_combo ? $sub_moves : $chain;
        $sep   = $is_combo ? '+' : '→';

        // Header: icon + move name (the overall defence/combo label) + top-level badges
        $html .= '<div class="move-main">';
        $html .= '<span class="move-cat-icon" style="background:' . cat_color($cat) . '">' . cat_icon($cat) . '</span>';
        $html .= '<span class="move-name">' . htmlspecialchars($m['name'] ?? '') . '</span>';
        $html .= render_badges($m);
        $html .= '</div>';

        // Each item: attack row + its counter row (if present)
        $html .= '<div class="combo-moves">';
        foreach ($items as $i => $item) {
            if ($i > 0) $html .= '<div class="combo-sep">' . $sep . '</div>';
            $html .= '<div class="combo-item">';
            $html .= '<div class="move-main">' . render_simple_move($item) . '</div>';

            $sc_name = $item['counter_name'] ?? '';
            if (!empty($sc_name)) {
                $sc_cat   = $item['counter_category'] ?? '';
                $sc_color = $sc_cat ? cat_color($sc_cat) : '#e74c3c';
                $sc_icon  = $sc_cat ? cat_icon($sc_cat)  : '🛡';
                $html .= '<div class="sub-counter">';
                $html .= '<span class="counter-arrow">↩</span>';
                $html .= '<span class="move-cat-icon" style="background:' . $sc_color . '">' . $sc_icon . '</span>';
                $html .= '<span class="move-name">' . htmlspecialchars($sc_name) . '</span>';
                if (!empty($item['counter_side']))           $html .= '<span class="badge-side" style="background:' . side_color($item['counter_side']) . '">' . htmlspecialchars($item['counter_side']) . '</span>';
                if (!empty($item['counter_level']))          $html .= '<span class="badge-level">' . level_symbol($item['counter_level']) . ' ' . htmlspecialchars($item['counter_level']) . '</span>';
                if (!empty($item['counter_special_action'])) $html .= '<span class="badge-special">' . htmlspecialchars($item['counter_special_action']) . '</span>';
                $html .= '</div>'; // sub-counter
            }
            $html .= '</div>'; // combo-item
        }
        $html .= '</div>'; // combo-moves
    } else {
        $html .= '<div class="move-main">' . render_simple_move($m) . '</div>';
    }

    // ── Counter ──
    if ($has_counter) {
        $counter_cat   = $m['counter_category'] ?? '';
        $counter_color = $counter_cat ? cat_color($counter_cat) : '#e74c3c';
        $counter_icon  = $counter_cat ? cat_icon($counter_cat)  : '🛡';

        $html .= '<div class="counter-section">';
        $html .= '<span class="counter-arrow">↩</span>';
        $html .= '<div class="counter-content">';

        if (!empty($counter_sub)) {
            foreach ($counter_sub as $i => $csub) {
                if ($i > 0) $html .= '<span class="move-sep">+</span>';
                $html .= render_simple_move($csub, true);
            }
        } elseif (!empty($counter_chain)) {
            foreach ($counter_chain as $i => $clink) {
                if ($i > 0) $html .= '<span class="move-sep chain-sep">→</span>';
                $html .= render_simple_move($clink, true);
            }
        } else {
            $html .= '<span class="move-cat-icon" style="background:' . $counter_color . '">' . $counter_icon . '</span>';
            $html .= '<span class="move-name">' . htmlspecialchars($m['counter_name'] ?? '') . '</span>';
            $html .= render_badges($m, true);
        }

        $html .= '</div></div>'; // counter-content + counter-section
    }

    $html .= '</div>'; // move-body
    $html .= '</div>'; // move-row
    $html .= '</div>'; // move-card

    return $html;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Prévisualisation — <?php echo htmlspecialchars(basename($filename, '.json')); ?></title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        /* ── Series header ── */
        .series-header {
            display: flex;
            align-items: flex-start;
            gap: 16px;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }
        .series-title {
            font-size: 1.5rem;
            font-weight: 700;
            margin: 0 0 8px 0;
            color: var(--text-color);
        }
        .series-meta { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
        .badge-cat  { background: #3498db; color: white; }
        .badge-type { background: #27ae60; color: white; }
        .badge-atk  { background: #e67e22; color: white; }
        .series-notes {
            margin-top: 12px;
            color: var(--text-light);
            font-style: italic;
            font-size: 0.9rem;
        }
        .series-author {
            margin-top: 8px;
            color: var(--text-light);
            font-size: 0.8rem;
        }

        /* ── Move list ── */
        .move-list   { display: flex; flex-direction: column; gap: 8px; }

        .move-card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 10px 14px;
            border-left: 3px solid var(--primary);
        }
        .move-row    { display: flex; align-items: flex-start; gap: 12px; }
        .move-body   { flex: 1; display: flex; flex-direction: column; gap: 6px; }

        /* Number circle */
        .move-num {
            min-width: 32px;
            height: 32px;
            border-radius: 50%;
            background: var(--primary);
            color: white;
            font-weight: 700;
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            margin-top: 2px;
        }
        .move-num-empty { min-width: 32px; flex-shrink: 0; }

        /* Main move row */
        .move-main {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
        }

        .move-cat-icon {
            width: 28px;
            height: 28px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            flex-shrink: 0;
        }
        .move-name  { font-weight: 600; font-size: 0.95rem; }
        .move-sep   { font-weight: 700; color: var(--text-light); font-size: 1rem; padding: 0 2px; }
        .chain-sep  { color: #2c3e50; }

        /* Badges */
        .badge-side {
            color: white;
            font-size: 0.75rem;
            font-weight: 700;
            padding: 2px 8px;
            border-radius: 12px;
        }
        .badge-level {
            font-size: 0.75rem;
            color: var(--text-light);
            background: #eee;
            padding: 2px 8px;
            border-radius: 12px;
        }
        .badge-special {
            font-size: 0.75rem;
            background: #ede7f6;
            color: #6a1b9a;
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 600;
        }
        .badge-feint {
            font-size: 0.72rem;
            background: #fff3e0;
            color: #e65100;
            padding: 2px 8px;
            border-radius: 12px;
            font-style: italic;
        }
        .badge-rep {
            font-size: 0.75rem;
            background: #e8f5e9;
            color: #2e7d32;
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 700;
        }

        /* Combo/chain attack-defence pairs */
        .combo-moves    { display: flex; flex-direction: column; gap: 4px; margin-top: 8px; padding-left: 12px; border-left: 2px solid #ddd; }
        .combo-item     { display: flex; flex-direction: column; gap: 3px; }
        .combo-sep      { font-weight: 700; color: var(--text-light); font-size: 0.85rem; padding: 1px 4px; }
        .sub-counter    { display: flex; align-items: center; flex-wrap: wrap; gap: 6px; background: #fff5f5; border: 1px solid #fca5a5; border-radius: 4px; padding: 3px 8px; margin-left: 8px; align-self: flex-start; }

        /* Counter section */
        .counter-section {
            display: flex;
            align-items: flex-start;
            gap: 8px;
            background: #fff5f5;
            border: 1px solid #fca5a5;
            border-radius: 6px;
            padding: 6px 10px;
            margin-top: 2px;
            align-self: flex-start;
        }
        .counter-arrow  { font-size: 1.1rem; color: #e74c3c; flex-shrink: 0; margin-top: 2px; }
        .counter-content { display: flex; align-items: center; flex-wrap: wrap; gap: 6px; }

        /* Series separator */
        .series-divider { border: none; border-top: 2px dashed #eee; margin: 32px 0; }
    </style>
</head>
<body>
<div class="container">

    <div class="nav" style="margin-bottom: 24px;">
        <a href="index.php" style="color: var(--text-light); text-decoration: none;">← Bibliothèque</a>
        <a href="<?php echo htmlspecialchars('data/' . rawurlencode($filename)); ?>" download>
            <button type="button" style="padding: 8px 16px; font-size: 14px;">Télécharger</button>
        </a>
    </div>

    <?php foreach ($series_list as $idx => $series): ?>
        <?php if ($idx > 0): ?><hr class="series-divider"><?php endif; ?>

        <div class="card">
            <!-- Series header -->
            <div class="series-header">
                <div style="flex:1">
                    <h2 class="series-title"><?php echo htmlspecialchars($series['title'] ?? 'Sans titre'); ?></h2>
                    <div class="series-meta">
                        <?php if (!empty($series['category'])): ?>
                            <span class="badge badge-cat"><?php echo htmlspecialchars($series['category']); ?></span>
                        <?php endif; ?>
                        <?php if (!empty($series['type'])): ?>
                            <span class="badge badge-type"><?php echo htmlspecialchars($series['type']); ?></span>
                        <?php endif; ?>
                        <?php if (!empty($series['attack_method'])): ?>
                            <span class="badge badge-atk"><?php echo htmlspecialchars($series['attack_method']); ?></span>
                        <?php endif; ?>
                        <span class="badge badge-json"><?php echo count($series['moves']); ?> mouvements</span>
                    </div>
                    <?php if (!empty($series['notes'])): ?>
                        <p class="series-notes"><?php echo nl2br(htmlspecialchars($series['notes'])); ?></p>
                    <?php endif; ?>
                    <?php if (!empty($series['Author']) || !empty($series['Date'])): ?>
                        <p class="series-author">
                            <?php
                                $parts = [];
                                if (!empty($series['Author'])) $parts[] = htmlspecialchars($series['Author']);
                                if (!empty($series['Date']))   $parts[] = htmlspecialchars($series['Date']);
                                echo implode(' · ', $parts);
                            ?>
                        </p>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Move list -->
            <?php if (empty($series['moves'])): ?>
                <p style="color: var(--text-light); text-align: center;">Aucun mouvement.</p>
            <?php else: ?>
                <div class="move-list">
                <?php
                    $move_num = 0;
                    foreach ($series['moves'] as $move):
                        $cat       = $move['category']  ?? 'other';
                        $sub_letter = $move['sub_letter'] ?? null;
                        $is_text   = ($cat === 'text');

                        // Number: only for non-'move', non-sub moves
                        $num_label = '';
                        if ($sub_letter === null && $cat !== 'move') {
                            $move_num++;
                            $num_label = (string)$move_num;
                        } elseif ($sub_letter !== null) {
                            $num_label = $move_num . $sub_letter;
                        }

                        echo render_move($move, $num_label);
                    endforeach;
                ?>
                </div>
            <?php endif; ?>
        </div>
    <?php endforeach; ?>

    <footer style="text-align: center; margin-top: 40px; color: var(--text-light); font-size: 14px;">
        <p>JKDApp · <a href="index.php" style="color: var(--text-light); text-decoration: none;">Bibliothèque</a></p>
    </footer>
</div>
</body>
</html>
