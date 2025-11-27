FROM mcr.microsoft.com/devcontainers/base:jammy

# Install Homebrew
USER vscode
ENV NONINTERACTIVE=1
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set up Homebrew environment
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/vscode/.bashrc

# Install Databricks CLI
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
    && brew install gcc \
    && brew tap databricks/tap \
    && brew install databricks

USER root
    
# Install Azure CLI and Databricks extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az config set extension.use_dynamic_install=yes_without_prompt \
    && az config set extension.dynamic_install_allow_preview=true \
    && az extension add --name databricks --upgrade

SHELL ["/bin/bash", "-c"]