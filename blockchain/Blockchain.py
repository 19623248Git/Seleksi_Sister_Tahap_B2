from Block import Block
from Transaction import Transaction
from MerkleTree import MerkleTree
from typing import List, Optional

class Blockchain:
    def __init__(self):
        self.chain: List[Block] = []
        self.mempool: List[Transaction] = []
        self.create_genesis_block()

    def create_genesis_block(self):
        """
        Creates the very first block with an empty Merkle Root.
        """
        genesis_block = Block(
            index=0, 
            previous_hash="0", 
            data=[], 
            merkle_root=MerkleTree([]).get_root()
        )
        self.chain.append(genesis_block)

    @property
    def last_block(self) -> Block:
        return self.chain[-1]

    def add_transaction(self, transaction: Transaction) -> None:
        self.mempool.append(transaction)
        print(f"Transaction added to mempool: {transaction.id}")

    def mine_block(self) -> Optional[Block]:
        """
        Mines a new block, calculates its Merkle Root, and adds it to the chain.
        """
        if not self.mempool:
            print("Mempool is empty. No block mined.")
            return None 

        transaction_data = [tx.to_dict() for tx in self.mempool]
        transaction_ids = [tx.id for tx in self.mempool]

        merkle_tree = MerkleTree(transaction_ids)
        merkle_root = merkle_tree.get_root()

        new_block = Block(
            index=self.last_block.index + 1,
            previous_hash=self.last_block.hash,
            data=transaction_data,
            merkle_root=merkle_root
        )
        
        # TODO: POW
        
        self.chain.append(new_block)
        
        print(f"Block {new_block.index} mined successfully with Merkle Root: {merkle_root}")
        self.mempool = []
        
        return new_block

    def to_dict(self):
        return {
            "chain": [block.to_dict() for block in self.chain],
            "length": len(self.chain)
        }
