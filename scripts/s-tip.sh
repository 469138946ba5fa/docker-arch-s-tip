#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

compare_time() {
    local current_time=$(date '+%Y-%m-%d %T')
    local shanghai_time=$(TZ='Asia/Shanghai' date '+%Y-%m-%d %T')
    log_info "当前时间: $current_time <-> 上海时间: $shanghai_time"
}
log_info '开始执行 server 登陆进程'
compare_time
TEMPDIR=$(mktemp -d)
cp -fv /app/s-tip.py ${TEMPDIR}/
cd ${TEMPDIR}

# 判断 HOSTS_JSON 变量是否在环境中存在
# 不存在则打印提示并退出，返回一个退出号
if [[ -z "$HOSTS_JSON" ]]; then
    log_error "Please set 'HOSTS_JSON' for linux"
    exit 1
else
    log_info "HOSTS_JSON ok"
fi

log_info "开始运行主任务..."
tgsend() {
  local message_text="$1"
  local MODE="HTML"
  local URL="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"
  if [[ -z "${TELEGRAM_TOKEN}" ]]; then
    log_info "未配置TG推送"
  else
    local res=$(timeout 20s curl -s -X POST "$URL" -d chat_id="${TELEGRAM_USERID}" -d parse_mode="$MODE" -d text="$message_text")
    local resSuccess=$(echo "$res" | jq -cr ".ok")
    if [[ "$resSuccess" == "true" ]]; then
      log_info "TG推送成功"
    else
      log_info "TG推送失败，请检查TG机器人token和ID"
    fi
  fi
}

# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
for info in $(jq -cr '.info[]' <<<"${HOSTS_JSON}");do
  user=$(jq -cr '.username' <<<"$info")
  host=$(jq -cr '.host' <<<"$info")
  port=$(jq -cr '.port' <<<"$info")
  pass=$(jq -cr '.password' <<<"$info")

  # 判断 SCRIPT 变量是否在环境中存在
  # 不存在则打印提示并退出，返回一个退出号
  if [[ -z "$SCRIPT" ]]; then
      # 自定义执行命令
      SCRIPT="cd ~/ ; clear ; ps -o pid,%cpu,%mem,comm ; uname -moprsv ; exit"
      log_info "'SCRIPT' is Null use default for linux"
      log_info "${SCRIPT}"
  else
      log_info "'SCRIPT' ok"
  fi
  if output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$port" -tt "$user@$host" sh <<<"$SCRIPT" 2>/dev/null | grep -v "$SCRIPT"); then
    log_info "登录成功"
    outputs="登录成功请检查! "$(echo -e "\n主机: ${host}\n用户: ${user}\n日志: ${output}")
  else
    log_info "登录失败"
    outputs="登录失败请检查! "$(echo -e "\n主机: ${host}\n用户: ${user}\n日志: ${output}")
  fi
  echo "${outputs}" >> result.txt
done

# 判断 TELEGRAM_TOKEN 变量是否在环境中存在
# 判断 TELEGRAM_USERID 变量是否在环境中存在
# 不存在则打印提示并退出，返回一个退出号
if [[ -z "$TELEGRAM_TOKEN" &&  -z "$TELEGRAM_USERID" ]]; then
    log_info "Please set 'TELEGRAM_TOKEN' and 'TELEGRAM_USERID' for linux"
else
    log_info "'TELEGRAM_TOKEN' and 'TELEGRAM_USERID' ok"
    tgsend "$(cat result.txt)"
fi

# 判断 AUTHTYPE 变量是否在环境中存在
# 判断 MAILADDR 变量是否在环境中存在
# 判断 MAILPORT 变量是否在环境中存在
# 判断 MAILUSERNAME 变量是否在环境中存在
# 判断 MAILFROM 变量是否在环境中存在
# 判断 MAILPASSWORD 变量是否在环境中存在
# 判断 MAILSENDTO 变量是否在环境中存在
# 不存在则打印提示并退出，返回一个退出号
if [[ -z "$MAILADDR" && -z "$MAILPORT" && -z "$MAILUSERNAME" && -z "$MAILPASSWORD" && -z "$MAILSENDTO" ]]; then
    log_error "Please set 'MAILADDR' and 'MAILPORT' and 'MAILUSERNAME'  and 'MAILPASSWORD' and 'MAILSENDTO' for linux"
    exit 3
else
    log_info "'AUTHTYPE' or 'MAILADDR' and 'MAILPORT' and 'MAILUSERNAME' or 'MAILFROM' and 'MAILPASSWORD' and 'MAILSENDTO' ok"
    # 发送附件到邮件
    python3 s-tip.py
fi

cd -
rm -frv ${TEMPDIR}

# 清理日志，保留最近 200 行
log_info '清理日志，保留最近 200 行'
if [[ -f /var/log/s-tip.log ]]; then
    tail -n 200 /var/log/s-tip.log > /var/log/s-tip.log.tmp
    mv /var/log/s-tip.log.tmp /var/log/s-tip.log
    echo "$(date '+%Y-%m-%d %T') 防止日志自行增大，日志文件已清理" >> /var/log/s-tip.log
fi

log_info '执行结束'
compare_time