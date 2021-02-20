# Etherpad Lite Dockerfile
#
# https://github.com/ether/etherpad-lite
#
# Author: chenyilin37

FROM node:10-buster-slim
LABEL maintainer="Etherpad team, https://github.com/ether/etherpad-lite"

# plugins to install while building the container. By default no plugins are
# installed.
# If given a value, it has to be a space-separated, quoted list of plugin names.
#
# EXAMPLE:
#   ETHERPAD_PLUGINS="ep_codepad ep_author_neat"
ARG ETHERPAD_PLUGINS="ep_adminpads2 ep_align ep_comments_page ep_embedded_hyperlinks2 ep_font_color ep_font_family ep_font_size ep_headings2 ep_tables4 ep_markdown ep_webrtc"
   

# By default, Etherpad container is built and run in "production" mode. This is
# leaner (development dependencies are not installed) and runs faster (among
# other things, assets are minified & compressed).
ENV NODE_ENV=production

USER root
RUN apt-get update && \
    apt-get install -y curl git-core

RUN useradd --uid 5001 --create-home etherpad

RUN mkdir /opt/etherpad-lite

WORKDIR /opt
RUN git clone --branch develop https://github.com/ether/etherpad-lite.git etherpad-lite && \
    chown -R etherpad:0 etherpad-lite

RUN apt-get purge -y curl git-core && \
    apt-get autoremove -y && \
    rm -r /var/lib/apt/lists/*
    
# Follow the principle of least privilege: run as unprivileged user.
#
# Running as non-root enables running this image in platforms like OpenShift
# that do not allow images running as root.


USER etherpad

WORKDIR /opt/etherpad-lite

# install node dependencies for Etherpad
RUN bin/installDeps.sh && \
	rm -rf ~/.npm/_cacache

# Install the plugins, if ETHERPAD_PLUGINS is not empty.
#
# Bash trick: in the for loop ${ETHERPAD_PLUGINS} is NOT quoted, in order to be
# able to split at spaces.
RUN for PLUGIN_NAME in ${ETHERPAD_PLUGINS}; do npm install "${PLUGIN_NAME}" || exit 1; done

# Copy the configuration file.
RUN cp settings.json.docker settings.json

# Fix permissions for root group
RUN chmod -R g=u .

EXPOSE 9001
CMD ["node", "node_modules/ep_etherpad-lite/node/server.js"]
