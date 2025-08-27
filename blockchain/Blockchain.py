from Block import Block
from Transaction import Transaction
from typing import List, Optional

class Blockchain:
    def __init__(self):
        """
        Initializes the Blockchain, creates the mempool, and adds the genesis block.
        """
        self.chain: List[Block] = []
        self.mempool: List[Transaction] = []
        self.create_genesis_block()

    def create_genesis_block(self):
        """
        Creates the very first block (Block 0) and adds it to the chain.
        """
        genesis_block = Block(index=0, previous_hash="0", data=[])
        self.chain.append(genesis_block)

    @property
    def last_block(self) -> Block:
        """
        A property to easily retrieve the most recent block in the chain.
        """
        return self.chain[-1]

    def add_transaction(self, transaction: Transaction) -> None:
        """
        Adds a new transaction to the mempool (list of pending transactions).
        """
        self.mempool.append(transaction)
        print(f"Transaction added to mempool: {transaction.id}")

    def mine_block(self) -> Optional[Block]:
        """
        Mines a new block, adds it to the chain, and clears the mempool.
        This is a simplified version without Proof-of-Work.
        """
        if not self.mempool:
            print("Mempool is empty. No block mined.")
            return None 

        new_block = Block(
            index=self.last_block.index + 1,
            previous_hash=self.last_block.hash,
            data=self.mempool
        )
        
        self.chain.append(new_block)
        
        print(f"Block {new_block.index} mined successfully with {len(self.mempool)} transactions.")
        self.mempool = []
        
        return new_block

    def to_dict(self):
        """
        Returns a dictionary representation of the entire blockchain.
        """
        return {
            "chain": [block.to_dict() for block in self.chain],
            "length": len(self.chain)
        }