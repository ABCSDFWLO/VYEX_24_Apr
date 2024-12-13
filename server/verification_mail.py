import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from fastapi import Depends
from pydantic import EmailStr

class VerificationMail:
    _instance = None

    sender_email = None
    password = None

    title = "Vyex : 인증 코드"
    html_style_highlight_color = "007bff"
    html_title = "이메일 인증 코드"
    html_text_title = "이메일 인증 코드"
    html_text_greetings = "안녕하세요!"
    html_text_please_verify_with_below = "아래의 인증 코드를 사용하여 이메일 인증을 완료해주세요:"
    html_text_valid_for_ten_minutes = "코드는 10분 동안만 유효합니다."
    html_text_if_not_your_request_then_deny = "만약 이 요청을 본인이 하지 않았다면, 이 이메일을 무시해주세요."
    html_text_left_of_support_mail = "문의사항이 있으시면 "
    html_support_mail = "axiotrium@gmail.com"
    html_text_right_of_support_mail = "로 연락주세요."
    html_text_thanks = "감사합니다."
    html_text_from = "Vyex : strategy of the walls"
    
    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(VerificationMail, cls).__new__(cls, *args, **kwargs)
        return cls._instance
    
    def __init__(self):
        if os.getenv("EMAIL") is not None:
            VerificationMail.sender_email = os.getenv("EMAIL")
        if os.getenv("EMAIL_PASSWORD") is not None:
            VerificationMail.password = os.getenv("EMAIL_PASSWORD")

    def send(self, verification_code : str, receiver_email : EmailStr):
        if VerificationMail.sender_email is None or VerificationMail.password is None:
            raise Exception("Email sender or password is not set")

        html_content = f"""<!DOCTYPE html>
            <html>

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>{VerificationMail.html_title}</title>
                <style>
                    body {{
                        font-family: 'Arial', sans-serif;
                        margin: 0;
                        padding: 0;
                        background-color: #f4f4f4;
                        color: #333;
                    }}

                    .email-container {{
                        max-width: 600px;
                        margin: 20px auto;
                        background: #ffffff;
                        border-radius: 8px;
                        overflow: hidden;
                        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    }}

                    .email-header {{
                        background-color: #{VerificationMail.html_style_highlight_color};
                        color: #ffffff;
                        text-align: center;
                        padding: 20px 10px;
                    }}

                    .email-header h1 {{
                        margin: 0;
                        font-size: 24px;
                    }}

                    .email-body {{
                        padding: 20px;
                        text-align: center;
                    }}

                    .email-body p {{
                        font-size: 16px;
                        line-height: 1.6;
                        margin: 10px 0;
                    }}

                    .email-body .verification-code {{
                        display: inline-block;
                        margin: 20px 0;
                        padding: 15px 30px;
                        font-size: 24px;
                        font-weight: bold;
                        letter-spacing: 5px;
                        color: #{VerificationMail.html_style_highlight_color};
                        background-color: #f4f4f4;
                        border: 1px dashed #{VerificationMail.html_style_highlight_color};
                        border-radius: 8px;
                    }}

                    .email-footer {{
                        text-align: center;
                        font-size: 14px;
                        color: #888888;
                        padding: 15px 20px;
                        border-top: 1px solid #eaeaea;
                    }}

                    .email-footer a {{
                        color: #{VerificationMail.html_style_highlight_color};
                        text-decoration: none;
                    }}

                    .email-footer a:hover {{
                        text-decoration: underline;
                    }}
                </style>
            </head>

            <body>
                <div class="email-container">
                    <!-- Header -->
                    <div class="email-header">
                        <h1>{VerificationMail.html_text_title}</h1>
                    </div>

                    <!-- Body -->
                    <div class="email-body">
                        <p>{VerificationMail.html_text_greetings}</p>
                        <p>{VerificationMail.html_text_please_verify_with_below}</p>
                        <div class="verification-code">{verification_code}</div>
                        <p>{VerificationMail.html_text_valid_for_ten_minutes}</p>
                        <p>{VerificationMail.html_text_if_not_your_request_then_deny}</p>
                    </div>

                    <!-- Footer -->
                    <div class="email-footer">
                        <p>{VerificationMail.html_text_left_of_support_mail} <a href="mailto:{VerificationMail.html_support_mail}">{VerificationMail.html_support_mail}</a>{VerificationMail.html_text_right_of_support_mail}</p>
                        <p>{VerificationMail.html_text_thanks}<br>{VerificationMail.html_text_from}</p>
                    </div>
                </div>
            </body>

            </html>
            """

        message = MIMEMultipart("alternative")
        message["Subject"] = VerificationMail.html_title
        message["From"] = VerificationMail.sender_email
        message["To"] = receiver_email

        html_part = MIMEText(html_content, "html")
        message.attach(html_part)

        try:
            with smtplib.SMTP("smtp.gmail.com", 587) as server:
                server.starttls()
                server.login(VerificationMail.sender_email, VerificationMail.password)
                server.sendmail(VerificationMail.sender_email, receiver_email, message.as_string())
        except Exception as e:
            raise Exception("Failed to send email : "+str(e))

def get_verification_mail():
    """
    Get the verification mail singleton instance.
    
    Returns:
        VerificationMail : The verification mail singleton.
    """
    return VerificationMail()

def send_verification_mail(verification_code : str, receiver_email : EmailStr, verification_mail: VerificationMail = Depends(get_verification_mail)):
    """
    Send a verification mail to the user.
    
    Parameters:
        verification_code (str) : The verification code.
        receiver_email (EmailStr) : The email of the receiver.
        verification_mail (VerificationMail) : The verification mail singleton.
    """
    verification_mail.send(verification_code, receiver_email)