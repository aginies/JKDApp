<?php
$lang = isset($_GET['lang']) && $_GET['lang'] === 'en' ? 'en' : 'fr';
?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">
<head>
    <meta charset="UTF-8">
    <title><?php echo $lang === 'fr' ? 'Politique de Confidentialité — JKDApp' : 'Privacy Policy — JKDApp'; ?></title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .privacy-content h1 { margin-top: 0; }
        .privacy-content h2 { 
            margin-top: 30px; 
            border-bottom: 1px solid #eee; 
            padding-bottom: 10px;
            color: var(--primary);
        }
        .privacy-content p { margin-bottom: 15px; }
        .privacy-content ul { margin-bottom: 15px; padding-left: 20px; }
        .privacy-content li { margin-bottom: 8px; }
        .effective-date {
            color: var(--text-light);
            font-style: italic;
            margin-bottom: 30px;
        }
        .lang-switcher {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-bottom: 20px;
        }
        .lang-link {
            padding: 5px 12px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.85rem;
            font-weight: 600;
            background: #eee;
            color: #666;
        }
        .lang-link.active {
            background: var(--primary);
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="nav">
                <a href="index.php" style="color: var(--text-light); text-decoration: none;">← <?php echo $lang === 'fr' ? 'Bibliothèque' : 'Library'; ?></a>
                <h1 style="margin: 0;"><?php echo $lang === 'fr' ? 'Confidentialité' : 'Privacy'; ?></h1>
            </div>
        </header>

        <div class="lang-switcher">
            <a href="?lang=fr" class="lang-link <?php echo $lang === 'fr' ? 'active' : ''; ?>">Français</a>
            <a href="?lang=en" class="lang-link <?php echo $lang === 'en' ? 'active' : ''; ?>">English</a>
        </div>

        <div class="card privacy-content">
            <?php if ($lang === 'fr'): ?>
                <h1>Politique de Confidentialité</h1>
                <p class="effective-date">Date d'entrée en vigueur : 9 avril 2026</p>

                <p>Cette politique de confidentialité décrit comment l'application <strong>JKD App</strong> ("nous", "notre" ou "l'application") traite vos informations. Votre vie privée est notre priorité absolue.</p>

                <h2>1. Opération Priorité au Local</h2>
                <p>L'application JKD App est conçue comme un utilitaire fonctionnant en <strong>priorité sur votre appareil</strong>. Par défaut, toute la logique applicative, le traitement des données et le stockage s'effectuent entièrement sur votre appareil.</p>
                <ul>
                    <li><strong>Pas de collecte de données :</strong> Nous ne collectons, ne stockons, ne transmettons ni ne partageons aucune information personnelle, statistique d'utilisation ou identifiant d'appareil.</li>
                    <li><strong>Aucun compte requis :</strong> Vous n'avez pas besoin de créer un compte ou de fournir des informations personnelles pour utiliser l'application.</li>
                    <li><strong>Pas d'analyse :</strong> Nous n'utilisons aucun outil tiers d'analyse ou de suivi.</li>
                    <li><strong>Connectivité axée sur la confidentialité :</strong> Les connexions au serveur sont strictement limitées aux fonctionnalités optionnelles de la "Bibliothèque Cloud". Aucune de ces connexions n'est utilisée pour collecter des données ; elles sont exclusivement utilisées pour envoyer ou récupérer des fichiers JSON.</li>
                </ul>

                <h2>2. Base de données interne et gestion des données</h2>
                <p>L'application gère une <strong>base de données locale interne</strong> pour stocker et afficher les éléments (séries, mouvements, etc.).</p>
                <ul>
                    <li><strong>Stockage local :</strong> Cette base de données est stockée uniquement sur le stockage local de votre appareil et n'est pas accessible par nous ou par un tiers.</li>
                    <li><strong>Objectif :</strong> Tout le traitement effectué par l'application est exclusivement destiné à la gestion de cette base de données interne pour fournir les fonctionnalités de l'application et vous afficher les éléments.</li>
                    <li><strong>Portabilité des données :</strong> Si vous utilisez les fonctions d'exportation (JSON, PDF), les fichiers sont générés localement et restent sur votre appareil à moins que vous ne choisissiez manuellement de les partager à l'aide des capacités de partage de votre appareil.</li>
                </ul>

                <h2>3. Permissions et accès aux données</h2>
                <p>L'application nécessite des autorisations spécifiques (telles que le stockage ou le microphone pour la saisie vocale) pour fonctionner correctement. Ces autorisations sont utilisées exclusivement pour :</p>
                <ul>
                    <li><strong>Traitement local :</strong> Gestion de la base de données interne et traitement des fichiers sélectionnés par l'utilisateur ou de la saisie vocale entièrement sur l'appareil.</li>
                    <li><strong>Bibliothèque Cloud optionnelle :</strong> Lorsque vous choisissez manuellement de partager une série ou d'en télécharger une depuis la bibliothèque Cloud, l'application se connecte à notre serveur pour transmettre les données de la série au format JSON. <strong>C'est le seul moment où l'application communique avec un serveur, et aucune donnée personnelle ou mesure d'utilisation n'est jamais incluse dans ces transmissions.</strong></li>
                </ul>

                <h2>4. Sécurité des données</h2>
                <p>Étant donné que l'application fonctionne principalement localement et ne transmet que des fichiers initiés manuellement par l'utilisateur, vos informations restent privées et sécurisées sur votre propre appareil.</p>

                <h2>5. Services tiers</h2>
                <p>L'application ne s'intègre à aucun service tiers, réseau publicitaire ou plateforme de médias sociaux susceptible de collecter vos données.</p>

                <h2>6. Modifications de cette politique</h2>
                <p>Nous pouvons mettre à jour notre politique de confidentialité de temps à autre. Tout changement sera reflété par la nouvelle "Date d'entrée en vigueur" en haut de cette page.</p>

                <h2>7. Nous contacter</h2>
                <p>Si vous avez des questions ou des suggestions concernant notre politique de confidentialité, n'hésitez pas à nous contacter.</p>

                <p><strong>Auteur :</strong> Antoine Ginies</p>

            <?php else: ?>
                <h1>Privacy Policy</h1>
                <p class="effective-date">Effective Date: April 9, 2026</p>

                <p>This Privacy Policy describes how the <strong>JKD App</strong> ("we", "our", or "the application") handles your information. Your privacy is our top priority.</p>

                <h2>1. Local-First Operation</h2>
                <p>The JKD App is designed as a <strong>local-first</strong> utility. By default, all application logic, data processing, and storage occur entirely on your device.</p>
                <ul>
                    <li><strong>No Data Collection:</strong> We do not collect, store, transmit, or share any personal information, usage statistics, or device identifiers.</li>
                    <li><strong>No Account Required:</strong> You do not need to create an account or provide any personal details to use the app.</li>
                    <li><strong>No Analytics:</strong> We do not use any third-party analytics or tracking tools.</li>
                    <li><strong>Privacy-Focused Connectivity:</strong> Server connections are strictly limited to the optional "Cloud Library" features. None of these connections are used to collect data; they are used exclusively for pushing or retrieving JSON files.</li>
                </ul>

                <h2>2. Internal Database and Data Management</h2>
                <p>The application manages an <strong>internal local database</strong> to store and display items (series, moves, etc.).</p>
                <ul>
                    <li><strong>Local Storage:</strong> This database is stored solely on your device's local storage and is not accessible by us or any third party.</li>
                    <li><strong>Purpose:</strong> All processing done by the app is exclusively for managing this internal database to provide the application's features and display items to you.</li>
                    <li><strong>Data Portability:</strong> If you use the export features (JSON, PDF), the files are generated locally and stay on your device unless you manually choose to share them using your device's sharing capabilities.</li>
                </ul>

                <h2>3. Permissions and Data Access</h2>
                <p>The application requires specific permissions (such as storage or microphone for voice input) to function correctly. These permissions are used exclusively for:</p>
                <ul>
                    <li><strong>Local Processing:</strong> Managing the internal database and processing user-selected files or voice input entirely on the device.</li>
                    <li><strong>Optional Cloud Library:</strong> When you manually choose to share a series or download one from the Cloud Library, the app connects to our server to transmit the series data in JSON format. <strong>This is the only time the app communicates with a server, and no personal data or usage metrics are ever included in these transmissions.</strong></li>
                </ul>

                <h2>4. Data Security</h2>
                <p>Since the application operates primarily locally and only transmits manual user-initiated files, your information remains private and secure on your own device.</p>

                <h2>5. Third-Party Services</h2>
                <p>The application does not integrate with any third-party services, advertising networks, or social media platforms that could collect your data.</p>

                <h2>6. Changes to This Policy</h2>
                <p>We may update our Privacy Policy from time to time. Any changes will be reflected by the new "Effective Date" at the top of this page.</p>

                <h2>7. Contact Us</h2>
                <p>If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.</p>

                <p><strong>Author:</strong> Antoine Ginies</p>
            <?php endif; ?>
        </div>

        <footer style="text-align: center; margin-top: 40px; color: var(--text-light); font-size: 14px;">
            <p>JKDApp · <a href="index.php" style="color: var(--text-light); text-decoration: none;"><?php echo $lang === 'fr' ? 'Bibliothèque' : 'Library'; ?></a></p>
        </footer>
    </div>
</body>
</html>
