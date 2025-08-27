# Test the blockchain locally (localhost)

- Run Bootstrap Node:
```
python3 Node.py -p 8000
```

- Run Extra Nodes:
```
python3 Node.py -p 8001 --bootstrap-node http://localhost:8000
```

```
python3 Node.py -p 8002 --bootstrap-node http://localhost:8000
```