# cast2gif image -- wraps ghcr.io/asciinema/agg with the cast2gif wrapper
# script and an entrypoint that handles volume-mount wiring automatically.
#
# The base image already contains the `agg` binary; we add:
#   - bash (for entrypoint and wrapper scripts)
#   - the cast2gif wrapper script at /usr/local/bin/cast2gif
#   - install.sh so `docker run ... install` drops cast2gif into the caller's CWD
#
# Usage (via wrapper):
#   cast2gif demo.cast          # derives demo.gif automatically
#   cast2gif -- --help          # passthrough to agg
#
# Usage (raw Docker):
#   docker run --rm \
#     -u "$(id -u):$(id -g)" \
#     -v "$PWD:/data" \
#     ghcr.io/rondomondo/cast2gif:latest \
#     demo.cast demo.gif

FROM ghcr.io/asciinema/agg:latest

USER root

# -- Apt packages + Fonts ----------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make htop less git procps sudo curl wget unzip \
        zsh lsof file iptables ipset iproute2 dnsutils aggregate locate


COPY --chown=root:root demo.cast /demo.cast
COPY --chown=root:root entrypoint.sh /entrypoint.sh
COPY --chown=root:root install.sh    /install.sh
COPY --chown=root:root cast2gif      /usr/local/bin/cast2gif
RUN chmod +x /entrypoint.sh /install.sh /usr/local/bin/cast2gif

WORKDIR /data

ENTRYPOINT ["/entrypoint.sh"]
