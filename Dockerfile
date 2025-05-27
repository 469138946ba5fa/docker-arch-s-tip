# ubuntu 滚动版，追求新颖，不稳定
FROM docker.io/library/ubuntu:rolling

# 添加文件
ADD scripts /app/
# 环境变量上海
ENV TZ=Asia/Shanghai

# 添加常用LABEL（根据需要修改）添加标题 版本 作者 代码仓库 镜像说明，方便优化
LABEL org.opencontainers.image.description='docker multi-arch s-tip support amd64 and arm64/v8' \
    org.opencontainers.image.title='Multi-arch s-tip' \
    org.opencontainers.image.version='1.0.0' \
    org.opencontainers.image.authors='469138946ba5fa <af5ab649831964@gmail.com>' \
    org.opencontainers.image.source='https://github.com/469138946ba5fa/docker-arch-s-tip' \
    org.opencontainers.image.licenses='MIT'

# 安装必要工具，包括 cron
RUN apt-get update && \
    apt-get install -y tini sshpass jq sudo curl systemd psmisc python3 cron tzdata && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && \
    chmod -v a+x /app/*.sh && \
    mv -fv /app/*.sh /usr/local/bin

# 使用 tini 作为入口，调用 entrypoint 脚本或者直接启动 /usr/local/bin/configure-cron.sh
ENTRYPOINT ["tini", "--"]
# 脚本执行
CMD [ "/usr/local/bin/configure-cron.sh" ]
