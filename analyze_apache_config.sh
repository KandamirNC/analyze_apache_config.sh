#!/bin/bash

CONFIG_DIR="/etc/apache2/sites-available"

# Prüfe, ob Apache installiert ist
if ! command -v apache2ctl &> /dev/null; then
    echo "Apache ist nicht installiert oder nicht im Pfad verfügbar."
    exit 1
fi

# Alle Konfigurationsdateien durchsuchen
for conf in "$CONFIG_DIR"/*.conf; do
    echo "Analysiere $conf ..."
    
    # Entferne auskommentierte Zeilen vor der Verarbeitung
    ACTIVE_LINES=$(grep -E "^[^#]" "$conf")
    
    # ServerName und ServerAlias extrahieren
    SERVER_NAMES=$(echo "$ACTIVE_LINES" | grep -i "ServerName" | awk '{print $2}')
    SERVER_ALIASES=$(echo "$ACTIVE_LINES" | grep -i "ServerAlias" | awk '{print $2}')
    
    # Überprüfen, ob verwendete Zertifikate und Verzeichnisse existieren
    CERT_FILES=$(echo "$ACTIVE_LINES" | grep -i "SSLCertificateFile" | awk '{print $2}')
    CERT_KEYS=$(echo "$ACTIVE_LINES" | grep -i "SSLCertificateKeyFile" | awk '{print $2}')
    
    echo "  ServerName: $SERVER_NAMES"
    echo "  ServerAlias: $SERVER_ALIASES"
    
    for cert in $CERT_FILES; do
        if [[ ! -f "$cert" ]]; then
            echo "  [WARNUNG] Zertifikatsdatei fehlt: $cert"
        fi
    done
    
    for key in $CERT_KEYS; do
        if [[ ! -f "$key" ]]; then
            echo "  [WARNUNG] Zertifikatsschlüssel fehlt: $key"
        fi
    done
    
    echo "------------------------------------"
done
