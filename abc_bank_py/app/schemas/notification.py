from pydantic import BaseModel

from app.enums import NotificationType


class NotificationDTO(BaseModel):
    recipient: str
    subject: str
    body: str
    type: NotificationType = NotificationType.EMAIL
