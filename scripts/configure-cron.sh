#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

compare_time() {
    local current_time=$(date '+%Y-%m-%d %T')
    local shanghai_time=$(TZ='Asia/Shanghai' date '+%Y-%m-%d %T')
    log_info "当前时间: $current_time <-> 上海时间: $shanghai_time"
}

# 设置默认的 CRON 时间间隔（如果环境变量未定义）
CRON_SCHEDULE="${CRON_SCHEDULE:-1 1 * * *}" # 默认每天凌晨1点1分运行一次
# 调用函数
compare_time
# 输出当前的计划任务时间
log_info "设置的 crontab 时间为：$CRON_SCHEDULE"

# 生成 crontab 配置文件导入环境变量
touch /var/log/s-tip.log
echo "$CRON_SCHEDULE /usr/local/bin/s-tip.sh >> /var/log/s-tip.log 2>&1" > /etc/cron.d/s-tip-task

{
    echo "TZ='${TZ}'"
    echo "CRON_SCHEDULE='${CRON_SCHEDULE}'"
    echo "HOSTS_JSON='${HOSTS_JSON}'"
    echo "SCRIPT='${SCRIPT}'"
    echo "TELEGRAM_TOKEN='${TELEGRAM_TOKEN}'"
    echo "TELEGRAM_USERID='${TELEGRAM_USERID}'"
    echo "AUTHTYPE='${AUTHTYPE}'"
    echo "MAILADDR='${MAILADDR}'"
    echo "MAILPORT='${MAILPORT}'"
    echo "MAILUSERNAME='${MAILUSERNAME}'"
    echo "MAILFROM='${MAILFROM}'"
    echo "MAILPASSWORD='${MAILPASSWORD}'"
    echo "MAILSENDTO='${MAILSENDTO}'"
    echo "HTTP_PROXY='${HTTP_PROXY}'"
    echo "HTTPS_PROXY='${HTTPS_PROXY}'"
    echo "ALL_PROXY='${ALL_PROXY}'"
    echo "http_proxy='${http_proxy}'"
    echo "https_proxy='${https_proxy}'"
    echo "all_proxy='${all_proxy}'"
    echo "$CRON_SCHEDULE /usr/local/bin/s-tip.sh >> /var/log/s-tip.log 2>&1"
} > /etc/cron.d/s-tip-task

chmod 0644 /etc/cron.d/s-tip-task

# 加载 crontab 任务
crontab /etc/cron.d/s-tip-task

# 启动 cron 服务并在后台运行
log_info "启动 cron 服务并保持后台运行..."
cron -f &

# 实时跟踪日志文件输出
tail -f /var/log/s-tip.log