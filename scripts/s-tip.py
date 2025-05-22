import smtplib, os, ssl, re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

def is_email(address):
    """简单检查字符串是否为邮箱格式"""
    return bool(re.match(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$", address))

def send_email(server, port, username, mail_from, auth_type, password=None, receiver=None, subject="", body="", filenames=[], use_ssl=False):
    # 创建邮件对象
    message = MIMEMultipart()
    message['From'] = mail_from
    message['To'] = receiver
    message['Subject'] = subject

    # 添加正文
    message.attach(MIMEText(body, 'plain', 'utf-8'))

    # 添加附件
    for filename in filenames:
        if not os.path.isfile(filename):
            print(f"⚠️ 附件文件未找到: {filename}，跳过")
            continue
        try:
            with open(filename, 'rb') as attachment:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(attachment.read())
            encoders.encode_base64(part)
            part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(filename)}"')
            message.attach(part)
        except Exception as e:
            print(f'❌ 无法打开附件 {filename}，错误：{e}')

    # 发送邮件
    try:
        if use_ssl:
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL(server, port, context=context) as smtp_server:
                authenticate_and_send(smtp_server, auth_type, username, password, message, mail_from, receiver)
        else:
            with smtplib.SMTP(server, port) as smtp_server:
                if port != 25:
                    smtp_server.starttls()
                authenticate_and_send(smtp_server, auth_type, username, password, message, mail_from, receiver)
        print("✅ 邮件发送成功！")
    except Exception as e:
        print(f"❌ 邮件发送失败。错误：{e}")

def authenticate_and_send(smtp_server, auth_type, username, password, message, mail_from, receiver):
    if auth_type == "password":
        smtp_server.login(username, password)
    elif auth_type == "oauth2":
        auth_string = f"user={username}\x01auth=Bearer {password}\x01\x01"
        smtp_server.docmd('AUTH XOAUTH2', auth_string)
    else:
        raise ValueError("未知的认证类型")
    
    smtp_server.sendmail(mail_from, receiver, message.as_string())

if __name__ == "__main__":
    # 获取环境变量
    auth_type = os.getenv('AUTHTYPE', 'password') # 认证类型, 默认值为 'password', 可选 'oauth2'
    server = os.getenv('MAILADDR') # 邮件服务器地址
    port = int(os.getenv('MAILPORT', 587)) # 邮件服务器端口, 默认值为 587
    username = os.getenv('MAILUSERNAME') # 用户名, 通常是邮箱地址
    mail_from = os.getenv('MAILFROM') # 发件人邮箱地址, 如果为空则自动推测

    # 修正 mail_from：如果为空，则自动推测
    if not mail_from:
        if is_email(username):
            mail_from = username
        else:
            # 提取域名部分并拼接成完整邮箱
            domain_parts = server.split('.')
            domain = '.'.join(domain_parts[1:]) if len(domain_parts) > 1 else server
            mail_from = f"{username}@{domain}"

    password = os.getenv('MAILPASSWORD') # 密码, 如果使用 oauth2 则为 token
    receiver = os.getenv('MAILSENDTO') # 收件人邮箱地址
    subject = "创建 s-tip 信息"
    body = "Run job of s-tip completed successfully!"
    filenames = ['result.txt']

    print(f"server={server}\nport={port}\nusername={username}\nmail_from={mail_from}\nauth_type={auth_type}\nreceiver={receiver}\n")

    send_email(server, port, username, mail_from, auth_type, password=password, receiver=receiver, subject=subject, body=body, filenames=filenames, use_ssl=(port == 465))
