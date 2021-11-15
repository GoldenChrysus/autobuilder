FROM ubuntu:18.04

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y git && \
	apt-get install -y ftp && \
	apt-get install -y curl && \
	curl -sL https://deb.nodesource.com/setup_14.x | bash && \
	apt-get install -y nodejs && \
	apt-get install -y lftp

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
