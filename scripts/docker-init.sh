sudo /etc/init.d/docker start
/etc/conf.d/docker
DOCKER_OPTS="--bip=10.20.0.4 --ip=10.20.0.3 --ip-forward=true"
docker network create --driver=bridge --gateway=10.20.0.1 --subnet=10.20.44.0/32 bridge-dnssec-workshop
