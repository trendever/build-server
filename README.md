# build-server
Buildserver to automaticly build servers

How to deploy:

* Set up docker-machine configs for servers
  * Update services.conf to use them; see example.services.conf
* Registry should work at addr dev.trendever.com:5000, or change that in `img.conf` (move that to config?)
* Artifacts (now -- logs, in future -- anything else) will be put to `../artifacts`. Or change it in notify.sh
* Clone https://github.com/trendever/devops/ and link ``live-services`` to that repo's `docker/trendever.com` directory 
* Deploy hooks service:
  * Build it with `go build hooks.go`
  * Deploy it. Supervisor sample conf:
  ```
directory=/home/buildserver/build-server
environment = 
        CHAT=telegram_chat_id_here,
        SECRET_TOKEN=telegram_token_here,
        SECRET=github_chat_secret_here,
        HOME=/home/buildserver,
        SHELL=/bin/bash
autostart=true
autorestart=true
stderr_logfile=/home/buildserver/logs/hooksbot-err.log
stdout_logfile=/home/buildserver/logs/hooksbot-out.log
stderr_logfile_backups=10
loglevel=info
user=buildserver
group=buildserver

  ```
* Update repositories with hooks. Server will listen on `:8090`
* Invite bot to chat and use `/build service.test branch-name` to launch build && deploy
* Profit

# TODO

* buildserver inside docker
