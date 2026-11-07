FROM mariadb:10.11

RUN mkdir -p /backups && chown mysql:mysql /backups
COPY --chown=mysql:mysql docker/backup.sh /usr/local/bin/backup.sh

USER mysql
CMD ["/bin/bash", "/usr/local/bin/backup.sh"]
