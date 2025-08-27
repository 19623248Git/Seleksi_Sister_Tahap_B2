import hashlib

class MerkleTree:
    def __init__(self, transaction_ids: list[str]):
        """
        Initializes the Merkle Tree with a list of transaction IDs.
        """
        self.transactions = transaction_ids
        self.tree = []
        self.root = self._build_tree()

    def _hash(self, data: str) -> str:
        """
        Helper function to create a SHA-256 hash.
        """
        return hashlib.sha256(data.encode()).hexdigest()

    def _build_tree(self) -> str:
        """
        Builds the Merkle Tree from the list of transactions and returns the root.
        """
        leaves = [self._hash(tx) for tx in self.transactions]
        
        if not leaves:
            return self._hash('')

        current_level = leaves
        
        while len(current_level) > 1:
            next_level = []
            
            if len(current_level) % 2 != 0:
                current_level.append(current_level[-1])
            
            for i in range(0, len(current_level), 2):
                left_child = current_level[i]
                right_child = current_level[i+1]
                combined_hash = self._hash(left_child + right_child)
                next_level.append(combined_hash)
            
            current_level = next_level
            
        return current_level[0]

    def get_root(self) -> str:
        """
        Returns the calculated Merkle Root of the tree.
        """
        return self.root

