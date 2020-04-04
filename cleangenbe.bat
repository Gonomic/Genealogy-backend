docker container stop GENBE01
docker container prune -f
docker container ps -a
docker volume prune -f
docker volume ls
docker volume create GENDATA01
docker volume ls
docker image rm fransdekkers/genbackend:1.0 -f
docker image build -t fransdekkers/genbackend:1.0 .
docker run --name GENBE01 -it -d -p 3306:3306 -v GENDATA01:/var/lib/mysql fransdekkers/genbackend:1.0 
docker start GENBE01
docker exec -it GENBE01 /bin/bash