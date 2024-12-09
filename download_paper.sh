#!/usr/bin/env sh

PROJECT="paper"
MINECRAFT_VERSION="1.21.1"  # Altere para a versão desejada
SERVER_JAR="server.jar"
CURRENT_VERSION=""

# Verifica se o arquivo JAR do servidor existe e obtém a versão
if [ -f "$SERVER_JAR" ]; then
    CURRENT_VERSION=$(java -jar $SERVER_JAR --version | grep -oP 'version \K[0-9]+\.[0-9]+\.[0-9]+')
    echo "Versão atual do servidor: $CURRENT_VERSION"
else
    echo "Arquivo $SERVER_JAR não encontrado."
    CURRENT_VERSION=""
fi

# Obtém a versão mais recente disponível
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/${PROJECT}/versions/${MINECRAFT_VERSION}/builds | \
    jq -r '.builds | map(select(.channel == "default") | .build) | .[-1]')

if [ "$LATEST_BUILD" != "null" ]; then
    JAR_NAME=${PROJECT}-${MINECRAFT_VERSION}-${LATEST_BUILD}.jar
    PAPERMC_URL="https://api.papermc.io/v2/projects/${PROJECT}/versions/${MINECRAFT_VERSION}/builds/${LATEST_BUILD}/downloads/${JAR_NAME}"

    # Verifica se a versão atual é diferente da mais recente
    if [ "$CURRENT_VERSION" != "$LATEST_BUILD" ]; then
        # Download da versão mais recente
        curl -o $SERVER_JAR $PAPERMC_URL
        echo "Download da versão mais recente concluído: $JAR_NAME"
    else
        echo "A versão mais recente já está instalada: $CURRENT_VERSION"
    fi
else
    echo "Nenhuma build estável para a versão $MINECRAFT_VERSION encontrada :("
fi

