import uvicorn
import argparse
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from Blockchain import Blockchain
from Transaction import Transaction

class TransactionModel(BaseModel):
    sender: str
    recipient: str
    amount: float

app = FastAPI()

blockchain = Blockchain()


@app.get("/chain")
async def get_chain():
    """Returns the node's full copy of the blockchain."""
    return blockchain.to_dict()

@app.post("/transactions")
async def new_transaction(transaction_data: TransactionModel):
    """Adds a new transaction to this node's mempool."""
    new_tx = Transaction(
        sender=transaction_data.sender,
        recipient=transaction_data.recipient,
        amount=transaction_data.amount
    )
    blockchain.add_transaction(new_tx)
    return {"message": f"Transaction {new_tx.id} added to mempool."}

@app.get("/transactions")
async def get_transactions():
    """Returns all transactions currently in the mempool."""
    return {
        "transactions": [tx.to_dict() for tx in blockchain.mempool],
        "count": len(blockchain.mempool)
    }

@app.get("/mine")
async def mine():
    """Triggers the node to mine a new block with all pending transactions."""
    mined_block = blockchain.mine_block()
    
    if not mined_block:
        raise HTTPException(status_code=400, detail="Mempool is empty, no block to mine.")
    
    
    return {
        "message": "New block forged",
        "block": mined_block.to_dict()
    }

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run a single blockchain node.')
    parser.add_argument('-p', '--port', type=int, default=8000, help='Port to run the node on.')
    args = parser.parse_args()

    port = args.port
    
    print(f"Starting blockchain node on http://localhost:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)