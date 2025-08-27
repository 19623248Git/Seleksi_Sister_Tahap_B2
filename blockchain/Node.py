import uvicorn
import argparse
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Set, List
import requests

from Blockchain import Blockchain
from Transaction import Transaction

class TransactionModel(BaseModel):
    sender: str
    recipient: str
    amount: float

class NodesModel(BaseModel):
    nodes: List[str]

app = FastAPI()

blockchain = Blockchain()

peers: Set[str] = set()


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

@app.post("/register-node")
async def register_node(payload: NodesModel):
    """
    Registers new nodes with this node and adds them to the peer list.
    """
    nodes_to_add = payload.nodes
    if not nodes_to_add:
        raise HTTPException(status_code=400, detail="No nodes provided in the request.")

    for node_url in nodes_to_add:
        if node_url: # Basic validation
            peers.add(node_url)

    return {
        "message": "New nodes have been added to the peer list.",
        "total_peers": list(peers)
    }

@app.get("/peers")
async def get_peers():
    """Returns the list of known peers."""
    return {"peers": list(peers)}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run a single blockchain node.')
    parser.add_argument('-p', '--port', type=int, default=8000, help='Port to run the node on.')
    parser.add_argument('--bootstrap-node', type=str, help='The address of a node to register with on startup.')
    args = parser.parse_args()

    port = args.port
    host_url = f"http://localhost:{port}"

    # On startup, register with the bootstrap node if one is provided
    if args.bootstrap_node:
        print(f"Registering with bootstrap node: {args.bootstrap_node}")
        try:
            # Tell the bootstrap node about ourselves
            requests.post(f"{args.bootstrap_node}/register-node", json={"nodes": [host_url]})
            
            # Ask the bootstrap node for its list of peers to add to our own
            response = requests.get(f"{args.bootstrap_node}/peers")
            if response.status_code == 200:
                known_peers = response.json().get("peers", [])
                for peer_url in known_peers:
                    peers.add(peer_url)

            # Finally, add the bootstrap node itself to our peer list
            peers.add(args.bootstrap_node)
            print(f"Successfully registered. Known peers: {peers}")

        except requests.exceptions.RequestException as e:
            print(f"Could not connect to bootstrap node {args.bootstrap_node}: {e}")

    print(f"Starting blockchain node on {host_url}")
    uvicorn.run(app, host="0.0.0.0", port=port)