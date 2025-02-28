#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Keine Farbe

# Pfade zu Apache-Konfigurationen
APACHE_CONF_DIR="/etc/apache2"
SITES_AVAILABLE_DIR="$APACHE_CONF_DIR/sites-available"
SITES_ENABLED_DIR="$APACHE_CONF_DIR/sites-enabled"

echo -e "${GREEN}### Apache2-Konfigurationsanalyse ###${NC}"
echo

# Prüfe, ob das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bitte führe dieses Skript mit Root-Rechten aus.${NC}"
  exit 1
fi

# Prüfe, ob das Apache-Konfigurationsverzeichnis existiert
if [ ! -d "$APACHE_CONF_DIR" ]; then
  echo -e "${RED}Apache-Konfigurationsverzeichnis ($APACHE_CONF_DIR) nicht gefunden.${NC}"
  exit 1
fi

echo -e "${YELLOW}Apache-Konfigurationsverzeichnis: ${APACHE_CONF_DIR}${NC}"
echo

# Liste der VirtualHosts
echo -e "${GREEN}1. Gefundene VirtualHosts:${NC}"
VHOST_FILES=$(find "$SITES_AVAILABLE_DIR" -type f -name "*.conf")

if [ -z "$VHOST_FILES" ]; then
  echo -e "${RED}Keine VirtualHost-Konfigurationen gefunden.${NC}"
else
  for VHOST in $VHOST_FILES; do
    echo -e "${YELLOW}Konfigurationsdatei:${NC} $VHOST"
    echo "-------------------------------------"
    SERVER_NAME=$(grep -i "ServerName" "$VHOST" | awk '{print $2}')
    DOCUMENT_ROOT=$(grep -i "DocumentRoot" "$VHOST" | awk '{print $2}')
    SSL_CERT_FILE=$(grep -i "SSLCertificateFile" "$VHOST" | awk '{print $2}')
    SSL_CERT_KEY=$(grep -i "SSLCertificateKeyFile" "$VHOST" | awk '{print $2}')

    if [ -z "$SERVER_NAME" ]; then
      echo -e "${RED}Kein ServerName definiert.${NC}"
    else
      echo -e "${GREEN}ServerName:${NC} $SERVER_NAME"
    fi

    if [ -z "$DOCUMENT_ROOT" ]; then
      echo -e "${RED}Kein DocumentRoot definiert.${NC}"
    elif [ ! -d "$DOCUMENT_ROOT" ]; then
      echo -e "${RED}DocumentRoot existiert nicht:${NC} $DOCUMENT_ROOT"
      echo -e "  ${YELLOW}Lösungsvorschlag:${NC} Überprüfe den Pfad oder entferne die Konfiguration."
    else
      echo -e "${GREEN}DocumentRoot:${NC} $DOCUMENT_ROOT"
    fi

    if [ -n "$SSL_CERT_FILE" ]; then
      if [ ! -f "$SSL_CERT_FILE" ]; then
        echo -e "${RED}SSL-Zertifikatsdatei fehlt:${NC} $SSL_CERT_FILE"
        echo -e "  ${YELLOW}Lösungsvorschlag:${NC} Stelle sicher, dass das Zertifikat vorhanden ist oder entferne die SSL-Konfiguration."
      else
        echo -e "${GREEN}SSL-Zertifikatsdatei:${NC} $SSL_CERT_FILE"
      fi
    fi

    if [ -n "$SSL_CERT_KEY" ]; then
      if [ ! -f "$SSL_CERT_KEY" ]; then
        echo -e "${RED}SSL-Schlüsseldatei fehlt:${NC} $SSL_CERT_KEY"
        echo -e "  ${YELLOW}Lösungsvorschlag:${NC} Stelle sicher, dass der private Schlüssel vorhanden ist oder entferne die SSL-Konfiguration."
      else
        echo -e "${GREEN}SSL-Schlüsseldatei:${NC} $SSL_CERT_KEY"
      fi
    fi

    echo
  done
fi

echo -e "${GREEN}2. Aktivierte Sites:${NC}"
ENABLED_SITES=$(ls -1 "$SITES_ENABLED_DIR" 2>/dev/null)

if [ -z "$ENABLED_SITES" ]; then
  echo -e "${RED}Keine aktivierten Sites gefunden.${NC}"
else
  for SITE in $ENABLED_SITES; do
    echo -e "${YELLOW}Aktivierte Site:${NC} $SITE"
    if [ ! -f "$SITES_AVAILABLE_DIR/$SITE" ]; then
      echo -e "${RED}Warnung: Aktivierte Site verweist auf eine fehlende Konfigurationsdatei.${NC}"
      echo -e "  ${YELLOW}Lösungsvorschlag:${NC} Entferne die fehlerhafte Verknüpfung:"
      echo -e "    sudo a2dissite $SITE"
    fi
  done
fi

echo
echo -e "${GREEN}Analyse abgeschlossen.${NC}"
