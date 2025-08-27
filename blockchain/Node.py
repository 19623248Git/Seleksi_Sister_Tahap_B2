import uvicorn
import argparse
import requests
from typing import Set, List
from fastapi import FastAPI, HTTPException, Body, status
from pydantic import BaseModel

from Blockchain import Blockchain
from Transaction import Transaction
from Block import Block

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
async def new_transaction(transaction_data: TransactionModel, broadcast: bool = True):
    if not transaction_data.sender or not transaction_data.recipient:
        raise HTTPException(status_code=400, detail="Transactions must include a sender and recipient.")
        
    new_tx = Transaction(
        sender=transaction_data.sender,
        recipient=transaction_data.recipient,
        amount=transaction_data.amount
    )
    blockchain.add_transaction(new_tx)

    if broadcast:
        for peer in peers:
            try:
                requests.post(f"{peer}/transactions?broadcast=false", json=transaction_data.model_dump(), timeout=5)
            except requests.exceptions.RequestException as e:
                print(f"Failed to broadcast transaction to peer {peer}: {e}")
        return {"message": f"Transaction {new_tx.id} added and broadcast to peers."}

    return {"message": f"Transaction {new_tx.id} added from a broadcast."}

@app.get("/transactions")
async def get_transactions():
    return {
        "transactions": [tx.to_dict() for tx in blockchain.mempool],
        "count": len(blockchain.mempool)
    }

@app.get("/mine")
async def mine():
    mined_block = blockchain.mine_block()
    if not mined_block:
        raise HTTPException(status_code=400, detail="Mempool is empty, no block to mine.")
    
    for peer in peers:
        try:
            requests.post(f"{peer}/add-block", json=mined_block.to_dict(), timeout=5)
        except requests.exceptions.RequestException as e:
            print(f"Could not broadcast block to peer {peer}: {e}")
    
    return {
        "message": "New block forged and broadcast",
        "block": mined_block.to_dict()
    }

@app.post("/add-block")
async def add_block(block_data: dict = Body(...)):
    block = Block(
        index=block_data['index'],
        data=block_data['data'],
        previous_hash=block_data['previous_hash'],
        merkle_root=block_data['merkle_root'],
        timestamp=block_data['timestamp'],
        nonce=block_data['nonce']
    )
    block.hash = block_data['hash']

    if not blockchain.add_block(block):
        replaced = await resolve_conflicts()
        
        if replaced['message'] == "Our chain was replaced by a longer, valid chain.":
             detail_message = "Invalid block. Chain was out of sync and has been replaced."
        else:
             detail_message = "Invalid block. Chain is authoritative but block was still rejected."

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, 
            detail=detail_message
        )
    
    return {"message": "New block added to the chain."}

@app.post("/add-false-block")
async def add_false_block():
    """
    Creates a block with an invalid previous_hash and broadcasts it.
    This is for testing purposes only.
    """
    last_block = blockchain.last_block
    
    false_block = Block(
        index=last_block.index + 1,
        data=[{"sender": "test", "recipient": "test", "amount": 0}],
        previous_hash="THIS_IS_A_FALSE_HASH", # Intentionally incorrect
        merkle_root=""
    )
    
    print("Broadcasting an intentionally false block...")
    for peer in peers:
        try:
            requests.post(f"{peer}/add-block", json=false_block.to_dict(), timeout=5)
        except requests.exceptions.RequestException as e:
            print(f"Could not broadcast false block to peer {peer}: {e}")
            
    return {"message": "False block broadcast to network.", "block": false_block.to_dict()}


@app.get("/resolve")
async def resolve_conflicts():
    replaced = await blockchain.resolve_conflicts(peers)
    if replaced:
        message = "Our chain was replaced by a longer, valid chain."
    else:
        message = "Our chain is authoritative."

    return {
        "message": message,
        "chain": blockchain.to_dict()['chain']
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
                    requests.post(f"{peer}/register-node?broadcast=false", json={"nodes": newly_added_nodes}, timeout=5)
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
            response = requests.post(f"{args.bootstrap_node}/register-node", json={"nodes": [host_url]}, timeout=5)
            
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
