import json
from google.cloud import firestore
from typing import Any
from data.plugins import Plugin

import logging
logger = logging.getLogger(__name__)


class FirestorePlugin(Plugin):

    def __init__(
        self,
        resource_type: str,
        gcloud_project: str,
        firestore_database: str = "(default)"
    ):
        self.collection = firestore.Client(project=gcloud_project, database=firestore_database).collection(resource_type)
        self.description = f"FIRESTORE-{resource_type}"

    def __iter__(self) -> Any:
        logger.debug(f"[__iter__]: {self.description}")

        for record in self.collection.stream():
            yield record.id

    def __delitem__(self, id: str) -> None:
        logger.debug(f"[__delitem__]: {self.description}, id={id}")

        ref = self.collection.document(id)
        ref.delete()

    def __getitem__(self, id: str) -> Any:
        logger.debug(f"[__getitem__]: {self.description}, id={id}")

        ref = self.collection.document(id)
        return ref.get().to_dict()

    def __setitem__(self, id: str, details: Any) -> None:
        logger.debug(
            f"[__setitem__]: {self.description}, id:{id}, details: {details}"
        )

        ref = self.collection.document(id)
        ref.set(json.loads(details))
