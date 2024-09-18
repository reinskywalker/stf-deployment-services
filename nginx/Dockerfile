FROM nginx:mainline
RUN apt-get update && apt-get install -y dos2unix
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
