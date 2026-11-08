FROM ghostchat-flutter:latest

USER root

# Installa le dipendenze di sistema per Rust
RUN apt update && apt install -y curl build-essential

# Installa Rust e cargo-ndk
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . /root/.cargo/env && \
    rustup target add aarch64-linux-android && \
    cargo install cargo-ndk

# Assicura che cargo sia nel PATH per tutti gli utenti
ENV PATH="/root/.cargo/bin:${PATH}"

# Imposta la directory di lavoro
WORKDIR /workspace-v2
