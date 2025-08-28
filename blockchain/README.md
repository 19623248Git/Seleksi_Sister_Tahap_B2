# Test the blockchain locally (localhost)

- Run Bootstrap Node **(THIS MUST RUN FIRST)**:
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

<a href="https://drive.google.com/drive/folders/17PgJlTWTSNqC666X3n3cAKTY1ZhwQFy5?usp=drive_link">Video demonstrasi</a>