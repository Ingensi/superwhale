![SuperWhale Logo](https://raw.githubusercontent.com/Ingensi/superwhale/develop/doc/superwhale.png)
*Logo by Camille BRIZARD*

### Superwhale
*This project is licensed under the terms of the MIT license.*

#### Aim
Docker introduced Docker Networks with version [1.9](https://github.com/docker/docker/blob/master/CHANGELOG.md#190-2015-11-03). With that update you can now have multiple web servers linked to the same network and a reverse proxy in front of them all without having to manage links manually. First, I was using HAProxy to do this role but HAProxy wasn't flexible enough : I was facing an issue, sometimes my containers weren't running while I was starting up my reverse and because HAProxy force name resolving at startup it was crashing almost every time. So I decided to create a system that add a smart layer upon HAProxy using a simple ruby script.

#### How it works
It uses alpine as a base distribution to provide a lightweight image. It includes ruby (with 1 gem : [FileWatcher](https://github.com/thomasfl/filewatcher)) and [HAProxy](http://www.haproxy.org/), that's all. At startup, SuperWhale will launch `/bin/superwhale` : the main process of the container.

`superwhale` will search for services inside the `/etc/superwhale.d` folder, create HAProxies configurations and then start HAProxies. It will also watch for file modifications inside `/etc/hosts` or `/etc/superwhale.d` and will gracefully reload HAProxies if there is any.

#### How to use it

##### Defining services

A service is the `superwhale` representation of a backend webserver that needs to be reverse proxied. To declare a service create an `YAML` file and put it inside the `/etc/superwhale.d` folder. For instance :

```
git:
  domain_name: git.mydomain.tld
  backends:
   - host: git_container
     port: 80
  options:
   - option forwardfor
   - http-request set-header X-Client-IP %[src]
   - http-request set-header Host git.mydomain.tld
```

Will output this inside HAProxies configuration ONLY if a `git_container` is present on the relevant `docker network` :

```
[...]

frontend public
  [...]
  acl host_git hdr(host) -i git.mydomain.tld
  use_backend git_backend if host_git

backend git_backend
  server git1 git:80
  option forwardfor
  http-request set-header X-Client-IP %[src]
  http-request set-header Host git.mydomain.tld
  
[...]
```

You can define multiple backends to create a load-balanced backend and the load-balancing algorithm used between them.

Here is an exhaustive list of what you can define for a service :


| Option        | Type                | Usage |
|---------------|---------------------|-------|
| *domain_name* | `string`            | Define the domain name used to determine the backend |
| *backends*    | `{host: 'hostname',port: port_int}[]` | Address of the backend server |
| *balance*     | `string`            | Define the load-balance algorithm for the backend pool |
| *options*     | `string[]`          | Options added to the backend block |
| *is_default*  | `bool`              | If true, add `default_backend` with this backend. Only one service can define this option. |


##### Configuring `superwhale`

You can tune `superwhale` configuration using the its configuration file : `/etc/superwhale.d/configs/superwhale.yml`. Here is the default version of this file :

```
# Redirect all HTTP traffic to its HTTPS counterpart
force_ssl: false

# If you want some domains/sub-domains to not be ssl forced, uncomment this
#ssl_noforce_domain:
# - my.domain.tld
# - [...]

# Change the log level : debug, info (default) and warning
log_level: info

# Uncomment this to add some directive to the dispatcher frontend declaration :
#dispatcher_frontend:
# - myoption true
# - [...]
```

##### Gracefull reload

When you modify services if we restart HAProxy on-the-fly it will interrupt all active connections, breaking current downloads, streamings etc... To avoid this, there is not one HAProxy, but three. There is one in the front named `dispatcher`, and 2 behinds : `master` and `slave`. When configuration is changed, slave is restarted, then master is. Using the capability of HAProxy to exit the process only when all connections are closed, there is no lost of connections.

Here is what HAProxy documentation says about soft-stop : 
```
2.4) Soft stop
--------------
It is possible to stop services without breaking existing connections by the
sending of the SIGUSR1 signal to the process. All services are then put into
soft-stop state, which means that they will refuse to accept new connections,
except for those which have a non-zero value in the 'grace' parameter, in which
case they will still accept connections for the specified amount of time, in
milliseconds. This makes it possible to tell a load-balancer that the service
is failing, while still doing the job during the time it needs to detect it.
```

##### Setting `haproxy.cfg` header

You can modify `header.cfg` or `dispatcher_header.cfg` (depending with instance you want to tune) file in `/etc/superwhale.d`.

##### Using HTTPS

You can use HTTPS by simply adding certificate file : `/etc/superwhale.d/https.pem`. This certificate is the concatenation of the certificate and the private key :

```
$ cat server.crt server.key > /etc/superwhale.d/https.pem
```

If you want to redirect all traffic to HTTPS, switch the `force_ssl` boolean to true inside the superwhale configuration file.

##### Launching the container

There is two way of using this container :

###### With volumes

While launching the container, use the `-v` argument :
```
docker run -d \
	-v /mnt/volumes/superwhale/:/etc/superwhale.d \
	-p 80:80 -p 443:443 --net=dockernet bahaika/whale-haproxy
```

###### With inheritance

Create a `Dockerfile` and inherits from `bahaika/whale-haproxy` :

```
FROM bahaika/whale-haproxy:latest

COPY ./service1.yml /etc/superwhale.d/service1.yml
```

#### Contributions

##### Want to contribute ?

* Fork the project.
* Make your feature addition or bug fix.
* Commit, do not mess with version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull).
* Send me a pull request.

##### Contibutors

Jérémy SEBAN - Main contributor - (GitHub: https://github.com/HipsterWhale)

