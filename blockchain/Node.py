import uvicorn
import argparse
import requests
from typing import Set, List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

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
host_url: str = ""

@app.get("/chain")
async def get_chain():
    return blockchain.to_dict()

@app.post("/transactions")
async def new_transaction(transaction_data: TransactionModel):
    new_tx = Transaction(
        sender=transaction_data.sender,
        recipient=transaction_data.recipient,
        amount=transaction_data.amount
    )
    blockchain.add_transaction(new_tx)
    return {"message": f"Transaction {new_tx.id} added to local mempool."}

@app.get("/mine")
async def mine():
    mined_block = blockchain.mine_block()
    if not mined_block:
        raise HTTPException(status_code=400, detail="Mempool is empty, no block to mine.")
    
    return {
        "message": "New block forged (local only)",
        "block": mined_block.to_dict()
    }

@app.post("/register-node")
async def register_node(payload: NodesModel, broadcast: bool = True):
    nodes_to_add = payload.nodes
    newly_added_nodes = []

    if not nodes_to_add:
        raise HTTPException(status_code=400, detail="No nodes provided in the request.")

    for node_url in nodes_to_add:
        if node_url != host_url and node_url not in peers:
            peers.add(node_url)
            newly_added_nodes.append(node_url)

    if broadcast and newly_added_nodes:
        for peer in list(peers):
            if peer not in newly_added_nodes:
                try:
                    requests.post(f"{peer}/register-node?broadcast=false", json={"nodes": newly_added_nodes})
                except requests.exceptions.RequestException as e:
                    print(f"Failed to broadcast to peer {peer}: {e}")

    return {
        "message": "Peer list updated.",
        "all_peers": list(peers)
    }

@app.get("/peers")
async def get_peers():
    return {"peers": list(peers)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run a single blockchain node.')
    parser.add_argument('-p', '--port', type=int, default=8000, help='Port to run the node on.')
    parser.add_argument('--bootstrap-node', type=str, help='The address of a node to register with on startup.')
    args = parser.parse_args()

    port = args.port
    host_url = f"http://localhost:{port}"

    if args.bootstrap_node:
        print(f"Registering with bootstrap node: {args.bootstrap_node}")
        try:
            response = requests.post(f"{args.bootstrap_node}/register-node", json={"nodes": [host_url]})
            
            if response.status_code == 200:
                all_peers = response.json().get("all_peers", [])
                for peer_url in all_peers:
                    if peer_url != host_url:
                        peers.add(peer_url)
            
            if args.bootstrap_node != host_url:
                peers.add(args.bootstrap_node)
            
            print(f"Successfully registered. Known peers: {peers}")

        except requests.exceptions.RequestException as e:
            print(f"Could not connect to bootstrap node {args.bootstrap_node}: {e}")

    print(f"Starting blockchain node on {host_url}")
    uvicorn.run(app, host="0.0.0.0", port=port)
