FROM python:3.12-slim

RUN pip install --no-cache-dir pikepdf

COPY strip.py /usr/local/bin/strip.py
RUN chmod +x /usr/local/bin/strip.py

COPY --chown=root:root entrypoint.sh /entrypoint.sh
COPY --chown=root:root install.sh    /install.sh
COPY --chown=root:root pdf-strip     /usr/local/bin/pdf-strip
RUN chmod +x /entrypoint.sh /install.sh /usr/local/bin/pdf-strip

WORKDIR /data
ENTRYPOINT ["/entrypoint.sh"]
