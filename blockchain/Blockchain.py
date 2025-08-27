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
        Creates the very first block and runs Proof-of-Work on it.
        """
        genesis_block = Block(
            index=0, 
            previous_hash="0", 
            data=[], 
            merkle_root=MerkleTree([]).get_root()
        )
        self.proof_of_work(genesis_block)
        self.chain.append(genesis_block)

    def proof_of_work(self, block: Block):
        """
        Finds a hash that satisfies the difficulty requirement, which increases
        as the chain grows.
        """
        # Difficulty increases by 1 for every 3 blocks
        difficulty = 1 + len(self.chain) // 3
        difficulty_target = '0' * difficulty
        
        while not block.hash.startswith(difficulty_target):
            block.set_nonce(block.nonce + 1)
            
        print(f"Proof-of-Work successful at difficulty {difficulty}. Found hash: {block.hash}")
        return block

    @property
    def last_block(self) -> Block:
        return self.chain[-1]

    def add_transaction(self, transaction: Transaction) -> None:
        self.mempool.append(transaction)
        print(f"Transaction added to mempool: {transaction.id}")

    def mine_block(self) -> Optional[Block]:
        """
        Mines a new block by performing Proof-of-Work.
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
        
        # Run the Proof-of-Work algorithm to find a valid hash
        self.proof_of_work(new_block)
        
        self.chain.append(new_block)
        
        print(f"Block {new_block.index} mined successfully.")
        self.mempool = []
        
        return new_block

    def to_dict(self):
        return {
            "chain": [block.to_dict() for block in self.chain],
            "length": len(self.chain)
        }
