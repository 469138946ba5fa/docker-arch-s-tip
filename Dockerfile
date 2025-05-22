FROM ubuntu:rolling

# 添加文件
ADD scripts /app/
# 环境变量上海
ENV TZ=Asia/Shanghai

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
