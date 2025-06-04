FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN chmod +x mvnw
RUN ./mvnw install -DskipTests

# Final image with both MySQL and Spring Boot app
FROM eclipse-temurin:17-jre-alpine

# Install MySQL
RUN apk update && apk add --no-cache mysql mysql-client bash

# Configure MySQL
ENV MYSQL_DATABASE=demo
ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_USER=user
ENV MYSQL_PASSWORD=password

# Copy the MySQL initialization script
WORKDIR /app
COPY --from=build /workspace/app/target/*.jar app.jar

# Create startup script to run both MySQL and Spring Boot app
RUN echo '#!/bin/sh \n\
echo "Starting MySQL..." \n\
mkdir -p /run/mysqld \n\
chown -R mysql:mysql /run/mysqld \n\
mysql_install_db --user=mysql --datadir=/var/lib/mysql \n\
mysqld --user=mysql --datadir=/var/lib/mysql --init-file=/app/init.sql & \n\
sleep 10 \n\
echo "MySQL started. Starting Spring Boot application..." \n\
java -jar /app/app.jar \n\
' > /app/startup.sh

# Create MySQL initialization SQL
RUN echo "CREATE DATABASE IF NOT EXISTS demo; \n\
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; \n\
GRANT ALL ON *.* TO 'root'@'localhost'; \n\
CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'password'; \n\
GRANT ALL ON demo.* TO 'user'@'%'; \n\
FLUSH PRIVILEGES;" > /app/init.sql

RUN chmod +x /app/startup.sh

EXPOSE 8080 3306

CMD ["/app/startup.sh"]
