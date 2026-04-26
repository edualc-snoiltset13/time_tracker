from sqlalchemy.orm import Session

from app.models.notification import Notification


def add(db: Session, notification: Notification) -> Notification:
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification
