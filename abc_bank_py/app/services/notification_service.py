import logging
import smtplib
from email.message import EmailMessage

from sqlalchemy.orm import Session

from app.config import Settings
from app.enums import NotificationType
from app.models.notification import Notification
from app.repos import notification_repo
from app.schemas.notification import NotificationDTO

logger = logging.getLogger(__name__)


def send_email(
    db: Session, settings: Settings, dto: NotificationDTO, user_id: int | None = None
) -> Notification:
    """Persist a notification record. Sends via SMTP only if SMTP settings are configured."""

    if dto.type == NotificationType.EMAIL and settings.smtp_host:
        try:
            msg = EmailMessage()
            msg["Subject"] = dto.subject
            msg["From"] = settings.smtp_from or (settings.smtp_username or "")
            msg["To"] = dto.recipient
            msg.set_content(dto.body)
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
                server.starttls()
                if settings.smtp_username and settings.smtp_password:
                    server.login(settings.smtp_username, settings.smtp_password)
                server.send_message(msg)
        except Exception:
            logger.exception("Failed to send email")

    notification = Notification(
        subject=dto.subject,
        recipient=dto.recipient,
        body=dto.body,
        type=dto.type,
        user_id=user_id,
    )
    return notification_repo.add(db, notification)
