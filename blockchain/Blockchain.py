import requests
from Block import Block
from Transaction import Transaction
from MerkleTree import MerkleTree
from typing import List, Optional, Set

class Blockchain:
    def __init__(self):
        self.chain: List[Block] = []
        self.mempool: List[Transaction] = []
        self.create_genesis_block()

    def create_genesis_block(self):
        """
        Creates a hard-coded, universal genesis block.
        """
        genesis_block = Block(
            index=0,
            previous_hash="0",
            data=[],
            merkle_root="",
            # timestamp="0000-00-00T00:00:00",
            timestamp=None,
            nonce=0
        )
        # Manually set the known hash for consistency
        genesis_block.hash = genesis_block.calculate_hash()
        self.chain.append(genesis_block)

    def proof_of_work(self, block: Block):
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

    def add_block(self, block: Block) -> bool:
        if block.previous_hash != self.last_block.hash:
            print("Validation Failed: Previous hash does not match.")
            return False
        
        if block.hash != block.calculate_hash():
            print("Validation Failed: Block hash is incorrect.")
            return False
            
        difficulty = 1 + len(self.chain) // 3
        difficulty_target = '0' * difficulty
        if not block.hash.startswith(difficulty_target):
            print("Validation Failed: Proof-of-Work is not satisfied.")
            return False

        self.chain.append(block)
        
        mined_tx_ids = {tx['id'] for tx in block.data}
        self.mempool = [tx for tx in self.mempool if tx.id not in mined_tx_ids]

        print(f"Block {block.index} from peer added. Mempool updated.")
        return True

    def mine_block(self) -> Optional[Block]:
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
        
        self.proof_of_work(new_block)
        
        self.chain.append(new_block)
        
        print(f"Block {new_block.index} mined successfully.")
        self.mempool = []
        
        return new_block

    @staticmethod
    def is_chain_valid(chain: List[dict]) -> bool:
        if not chain: return False
        
        # We can't validate the hardcoded genesis block this way, so we check from block 1
        for i in range(1, len(chain)):
            current_block_data = chain[i]
            previous_block_data = chain[i - 1]

            if current_block_data['previous_hash'] != previous_block_data['hash']:
                return False

            block_to_validate = Block(
                index=current_block_data['index'], data=current_block_data['data'],
                previous_hash=current_block_data['previous_hash'], merkle_root=current_block_data['merkle_root'],
                timestamp=current_block_data['timestamp'], nonce=current_block_data['nonce']
            )
            
            if block_to_validate.calculate_hash() != current_block_data['hash']:
                return False
        
        return True

    async def resolve_conflicts(self, peers: Set[str]) -> bool:
        new_chain = None
        max_length = len(self.chain)

        for node in peers:
            try:
                response = requests.get(f'{node}/chain', timeout=5)
                if response.status_code == 200:
                    length = response.json()['length']
                    chain_data = response.json()['chain']

                    if length > max_length and self.is_chain_valid(chain_data):
                        max_length = length
                        new_chain = chain_data
            except requests.exceptions.RequestException as e:
                print(f"Could not fetch chain from peer {node}: {e}")

        if new_chain:
            reconstructed_chain = []
            for block_data in new_chain:
                block = Block(
                    index=block_data['index'], data=block_data['data'],
                    previous_hash=block_data['previous_hash'], merkle_root=block_data['merkle_root'],
                    timestamp=block_data['timestamp'], nonce=block_data['nonce']
                )
                block.hash = block_data['hash'] # Use the hash from the trusted chain
                reconstructed_chain.append(block)

            self.chain = reconstructed_chain
            self.mempool = []
            return True

        return False

    def to_dict(self):
        return {
            "chain": [block.to_dict() for block in self.chain],
            "length": len(self.chain)
        }
