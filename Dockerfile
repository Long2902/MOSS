FROM ubuntu:20.04

WORKDIR /app
COPY . .

ENV DEBIAN_FRONTEND="noninteractive" TZ="Africa/Johannesburg"

# Cài đặt các gói cần thiết
RUN apt-get update && apt-get install -y \
    make \
    sudo \
    mysql-server \
    libmysqlclient-dev \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean

# Tạo môi trường ảo và cài đặt các gói Python
RUN python3 -m venv venv
RUN /bin/bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements_dev.txt"

# Install remaining dependencies
RUN make install

# Khởi động MySQL và thay đổi mật khẩu root
RUN service mysql start && mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '';FLUSH PRIVILEGES;"

# Thiết lập MySQL
RUN service mysql start && \
    mysql -e "CREATE USER 'automoss'@'localhost' IDENTIFIED BY 'password';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'automoss'@'localhost';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Thiết lập quyền thực thi cho start script
RUN chmod +x start.sh

# Khởi động MySQL và chạy start script
CMD ["/bin/bash", "/app/start.sh"]

