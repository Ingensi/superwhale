# The aim is to create a lightweight docker image
# that provides a smart http reverse proxy using haproxy
# for docker network usage.
#
# Read the README.md file for more informations.
#
# Find more here : https://github.com/Bahaika/whale-haproxy

FROM alpine:3.3
MAINTAINER Jérémy SEBAN <jeremy@seban.eu>

# Installing haproxy, ruby
RUN apk add --update ruby haproxy

# Installing superwhale dependency
RUN gem install filewatcher --no-ri --no-rdoc

# Cleaning downloaded packages from image
RUN rm -rf /var/cache/apk/*

# Adding superwhale libraries files
RUN mkdir -p /usr/lib/superwhale
COPY ./lib/* /usr/lib/superwhale/

# Adding superwhale binary
COPY ./bin/superwhale /bin/superwhale
RUN chmod +x /bin/superwhale

# Adding entrypoint
COPY ./bin/entrypoint /bin/entrypoint
RUN chmod +x /bin/entrypoint

# Exposing HTTP and HTTPS ports
EXPOSE 80 443

# Setting /etc/superwhale.d as VOLUME
VOLUME ["/etc/superwhale.d"]

# Entrypoint to dispatch parameters
ENTRYPOINT ["/bin/entrypoint"]

# Setting the starting command
CMD ["/bin/superwhale"]