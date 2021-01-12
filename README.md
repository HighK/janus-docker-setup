# Janus gateway

`docker-compose`

Build the image
```shell
$ docker build -t linagora/janus-gateway .
```

Where ports:
  - **80**: expose janus documentation and admin/monitoring website (port 10201 from external IP)
  - **7088**: expose Admin/monitor server
  - **8088**: expose Janus server
  - **8188**: expose Websocket server
  - **10000-10200/udp**: Used during session establishment


origin [from this repo](https://github.com/linagora/docker-janus-gateway)
