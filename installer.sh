#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Bitte führe das Skript mit Root-Rechten aus (sudo)."
    exit
fi

INSTALL_DIR="/var/www/html/trolling"
KEY_FILE="$INSTALL_DIR/key.txt"

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

setup_website() {
    cat <<EOL > "$INSTALL_DIR/index.php"
<?php
\$keyFile = __DIR__ . '/key.txt';
\$storedKey = trim(file_get_contents(\$keyFile));

if (\$_POST['key'] !== \$storedKey) {
    echo <<<HTML
    <!DOCTYPE html>
    <html lang="de">
    <head>
        <meta charset="UTF-8">
        <title>Login - Trolling Tools</title>
        <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500&display=swap" rel="stylesheet">
        <style>
            body {
                font-family: 'Roboto', sans-serif;
                background-color: #2c2c2c;
                color: #ddd;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                transition: background-color 0.3s, color 0.3s;
            }
            .container {
                background-color: #444;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
                width: 300px;
                text-align: center;
            }
            h1 {
                margin-bottom: 20px;
                color: #4CAF50;
            }
            input {
                width: 100%;
                padding: 10px;
                margin: 10px 0;
                border: 1px solid #666;
                border-radius: 4px;
                background-color: #333;
                color: #fff;
            }
            button {
                width: 100%;
                padding: 10px;
                background-color: #4CAF50;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 16px;
                cursor: pointer;
                transition: background-color 0.3s;
            }
            button:hover {
                background-color: #45a049;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Bitte Schlüssel eingeben</h1>
            <form method="POST">
                <input type="password" name="key" placeholder="Schlüssel" required>
                <button type="submit">Login</button>
            </form>
        </div>
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
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trolling Tools</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Roboto', sans-serif;
            background-color: #2c2c2c;
            color: #ddd;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            transition: background-color 0.3s, color 0.3s;
        }
        .container {
            background-color: #444;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            width: 400px;
        }
        h1 {
            text-align: center;
            color: #4CAF50;
        }
        button {
            width: 100%;
            padding: 12px;
            margin: 8px 0;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        button:hover {
            background-color: #45a049;
        }
        label, input {
            width: 100%;
            margin-bottom: 10px;
        }
        input {
            padding: 10px;
            border: 1px solid #666;
            border-radius: 5px;
            background-color: #333;
            color: #fff;
        }
        .datalist {
            max-height: 100px;
            overflow-y: scroll;
        }

        /* Dark Mode */
        body.dark {
            background-color: #121212;
            color: #ddd;
        }

        .container.dark {
            background-color: #333;
        }

        button.dark {
            background-color: #0b5c0b;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Trolling Tools</h1>
        <button id="darkModeToggle">Dark Mode</button>
        <form method="POST">
            <button name="action" value="shutdown">PC Shutdown</button>
            <label for="program">Programmname (killall):</label>
            <input type="text" name="program" id="program" placeholder="Programmname" list="programs">
            <datalist id="programs" class="datalist">
                <?php
                    \$programs = shell_exec("ps -e -o comm");
                    \$programList = explode("\n", \$programs);
                    foreach (\$programList as \$program) {
                        echo "<option value=\"".htmlspecialchars(\$program)."\">";
                    }
                ?>
            </datalist>
            <button name="action" value="killall">Killall</button>

            <label for="display">Display:</label>
            <input type="text" name="display" id="display" placeholder=":0" list="displays">
            <datalist id="displays" class="datalist">
                <?php
                    \$displays = shell_exec("who | awk '{print \$2}'");
                    \$displayList = explode("\n", \$displays);
                    foreach (\$displayList as \$display) {
                        echo "<option value=\"".htmlspecialchars(\$display)."\">";
                    }
                ?>
            </datalist>

            <label for="url">URL:</label>
            <input type="text" name="url" id="url" placeholder="https://example.com">
            <button name="action" value="open_firefox">Open Firefox</button>

            <button name="action" value="update">Update Tool</button>
        </form>
    </div>

    <script>
        const darkModeToggle = document.getElementById('darkModeToggle');
        const body = document.body;
        const container = document.querySelector('.container');

        // Check if Dark Mode is enabled in localStorage
        if (localStorage.getItem('darkMode') === 'enabled') {
            body.classList.add('dark');
            container.classList.add('dark');
            darkModeToggle.classList.add('dark');
        }

        darkModeToggle.addEventListener('click', () => {
            body.classList.toggle('dark');
            container.classList.toggle('dark');
            darkModeToggle.classList.toggle('dark');

            // Save Dark Mode preference to localStorage
            if (body.classList.contains('dark')) {
                localStorage.setItem('darkMode', 'enabled');
            } else {
                localStorage.removeItem('darkMode');
            }
        });
    </script>
</body>
</html>
EOL
}

configure_permissions() {
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    echo "www-data ALL=(ALL) NOPASSWD: /sbin/shutdown, /usr/bin/killall, /path/to/this/script" >> /etc/sudoers
    systemctl restart apache2
}

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