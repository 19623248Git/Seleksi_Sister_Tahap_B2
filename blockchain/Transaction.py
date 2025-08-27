import hashlib
import json
from datetime import datetime

class Transaction:
    def __init__(self, sender, recipient, amount):
        """
        Initializes a new transaction.
        """
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.timestamp = str(datetime.now())
        # The transaction ID is a hash of its core contents
        self.id = self.calculate_hash()

    def calculate_hash(self):
        """
        Calculates the SHA-256 hash of the transaction to serve as its unique ID.
        """
        # We must sort the dictionary to ensure consistent hashes
        transaction_string = json.dumps({
            "sender": self.sender,
            "recipient": self.recipient,
            "amount": self.amount,
            "timestamp": self.timestamp
        }, sort_keys=True).encode()
        
        return hashlib.sha256(transaction_string).hexdigest()

    def to_dict(self):
        """
        Returns a dictionary representation of the transaction.
        """
        return {
            "id": self.id,
            "timestamp": self.timestamp,
            "sender": self.sender,
            "recipient": self.recipient,
            "amount": self.amount
        }

    def __repr__(self):
        """

        A string representation of the Transaction object for easy printing.
        """
        return str(self.to_dict())