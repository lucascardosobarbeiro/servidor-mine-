FROM openjdk:21-slim
LABEL maintainer="Your Name"

WORKDIR /opt/minecraft-server

# Instala as dependências necessárias
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copia o script de inicialização
COPY start_server.sh .
RUN chmod +x start_server.sh

EXPOSE 25565
VOLUME ["/opt/minecraft-server"]

# Comando para iniciar o servidor
CMD ["./start_server.sh"]
