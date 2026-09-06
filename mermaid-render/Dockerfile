FROM minlag/mermaid-cli:latest 

USER root

RUN apk update && apk add bash curl imagemagick

COPY --chown=root:root entrypoint.sh /entrypoint.sh
COPY --chown=root:root install.sh    /install.sh
COPY --chown=root:root mermaid-render /usr/local/bin/mermaid-render
RUN chmod +x /entrypoint.sh /install.sh /usr/local/bin/mermaid-render

USER mermaidcli

ENTRYPOINT ["/entrypoint.sh"]
