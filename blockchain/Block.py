import hashlib
import json
from datetime import datetime

class Block:
    def __init__(self, index, data, previous_hash, merkle_root, timestamp=None, nonce=0):
        self.index = index
        self.timestamp = timestamp or str(datetime.now())
        self.data = data
        self.previous_hash = previous_hash
        self.merkle_root = merkle_root
        self.nonce = nonce
        self.hash = self.calculate_hash()

    def calculate_hash(self):
        """
        Calculates the block's hash using the Merkle Root for efficiency.
        """
        block_string = json.dumps({
            "index": self.index,
            "timestamp": self.timestamp,
            "merkle_root": self.merkle_root,
            "previous_hash": self.previous_hash,
            "nonce": self.nonce
        }, sort_keys=True).encode()
        
        return hashlib.sha256(block_string).hexdigest()

    def set_nonce(self, nonce):
        """
        Sets a new nonce for the block and recalculates its hash.
        """
        self.nonce = nonce
        self.hash = self.calculate_hash()

    def to_dict(self):
        """
        Returns a dictionary representation of the block.
        """
        return {
            "index": self.index,
            "timestamp": self.timestamp,
            "data": self.data,
            "previous_hash": self.previous_hash,
            "merkle_root": self.merkle_root,
            "nonce": self.nonce,
            "hash": self.hash
        }
