FROM  debian:buster-slim

RUN apt-get update
RUN apt-get install -y nginx mariadb-server php-fpm php-mysql wget

#configure nginx to load automacly wordpress page
COPY src/nginx-host-conf /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/nginx-host-conf /etc/nginx/sites-enabled/

#SLL SETUP
RUN mkdir ~/mkcert && \
  cd ~/mkcert && \
  wget https://github.com/FiloSottile/mkcert/releases/download/v1.1.2/mkcert-v1.1.2-linux-amd64 && \
  mv mkcert-v1.1.2-linux-amd64 mkcert && \
  chmod +x mkcert && \
./mkcert -install && \
./mkcert localhost
RUN rm var/www/html/index.nginx-debian.html

#config wordpress
RUN cd var/www/html && wget http://wordpress.org/latest.tar.gz  && \
tar -xzvf latest.tar.gz && rm latest.tar.gz 
RUN cd var/www/html && cp -a wordpress/* . && rm -r wordpress
RUN chown -R www-data:www-data /var/www/html/ && chmod -R 755 /var/www/html/  
COPY src/wp-config.php /var/www/html/

#DATABASE SETUP
COPY src/wordpress.sql ./root/
RUN service mysql start && \
echo "CREATE DATABASE wordpress;" | mysql -u root && \
echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost';" | mysql -u root && \
echo "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root  && \
mysql wordpress -u root --password=  < ./root/wordpress.sql

#PHPMYADMIN INSTALL
COPY src/config.inc.php ./root/
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-english.tar.gz && \
mkdir /var/www/html/phpmyadmin && \
tar xzf phpMyAdmin-4.9.0.1-english.tar.gz --strip-components=1 -C /var/www/html/phpmyadmin && \
cp /root/config.inc.php /var/www/html/phpmyadmin/ 


#restart services
RUN service nginx restart

EXPOSE 80 443

CMD service nginx start && \
  service mysql start && \
  service php7.3-fpm start && \
  sleep infinity