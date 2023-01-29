docker run --name=FD-GEN-DB-1 -it -d -p=3306:3306 -v=MariaDB:/var/lib/mysql -e MARIADB_ROOT_PASSWORD=ErgGeheim --network=DN-GEN mariadb:latest
