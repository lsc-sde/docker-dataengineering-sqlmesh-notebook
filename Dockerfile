# Docker image with JupyterLab and Code Server for data engineering with SQLMesh
# Provides the following IDEs
# - JupyterLab
# - Code Server

ARG OWNER=lscsde
ARG BASE_CONTAINER=quay.io/jupyter/minimal-notebook:python-3.12.11
FROM $BASE_CONTAINER
ARG TARGETOS TARGETARCH
LABEL maintainer="lscsde"
LABEL image="dataengineering-sqlmesh-notebook"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

COPY vsix vsix

RUN mamba install code-server \
  && mamba clean --all -f -y \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "/home/${NB_USER}"



# Install all extensions in one layer: aids faster build and smaller image
RUN code-server --install-extension charliermarsh.ruff \
  && code-server --install-extension databricks.databricks \
  && code-server --install-extension databricks.sqltools-databricks-driver \
  && code-server --install-extension davidanson.vscode-markdownlint \
  && code-server --install-extension ms-python.black-formatter \
  && code-server --install-extension ms-python.python \
  && code-server --install-extension mtxr.sqltools \
  && code-server --install-extension njpwerner.autodocstring \
  && code-server --install-extension tobikodata.sqlmesh \
  && code-server --install-extension vsix/github.copilot-1.350.0-web.vsix --force \
  && code-server --install-extension vsix/github.copilot-chat-0.29.0.vsix --force
  
# RUN code-server --install-extension charliermarsh.ruff 
# RUN code-server --install-extension databricks.databricks 
# RUN code-server --install-extension databricks.sqltools-databricks-driver 
# RUN code-server --install-extension davidanson.vscode-markdownlint 
# RUN code-server --install-extension jannisx11.batch-rename-extension 
# RUN code-server --install-extension ms-python.black-formatter 
# RUN code-server --install-extension ms-python.python 
# RUN code-server --install-extension ms-toolsai.jupyter 
# RUN code-server --install-extension ms-toolsai.jupyter-renderers 
# RUN code-server --install-extension ms-toolsai.vscode-jupyter-cell-tags 
# RUN code-server --install-extension ms-toolsai.vscode-jupyter-keymap 
# RUN code-server --install-extension mtxr.sqltools 
# RUN code-server --install-extension njpwerner.autodocstring 
# RUN code-server --install-extension tobikodata.sqlmesh 
# RUN code-server --install-extension vsix/github.copilot-1.350.0-web.vsix 
# RUN code-server --install-extension vsix/github.copilot-chat-0.29.0.vsix

RUN rm -rf vsix
# Copy custom config for jupyter
COPY jupyter_notebook_config.json /etc/jupyter/jupyter_notebook_config.json

# Install UV
# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install packages
COPY environment.yaml environment.yaml
COPY requirements.txt requirements.txt

RUN mamba env update --name base --file environment.yaml \
  && rm environment.yaml \
  && mamba clean --all -f -y 


RUN uv pip install --system -r requirements.txt && rm requirements.txt
# Fix folder permissions and switch back to jovyan to avoid accidental container runs as root
RUN fix-permissions "${CONDA_DIR}" \
  && fix-permissions "/home/${NB_USER}" 
USER ${NB_UID}
