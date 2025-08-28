# COBOL + FastAPI Debug Task

Your task:
1. Fix `main.cob` so it works correctly.
2. Fix `Dockerfile` so the app runs end-to-end.

Rules:
- **Do NOT modify** `app.py` or `index.html`.
- You can change anything in `main.cob` and `Dockerfile`.
- Input/output files (`input.txt`, `output.txt`, `accounts.txt`) are provided.

How to test:
```bash
docker build -t cobol-app .
docker run -p 8000:8000 -e COBOL_ARGS="--apply-interest" cobol-app
```

### Working Deployed Application with HTTPS: https://scobol.ddns.net/

# Bonus yang dikerjakan

### Membuat konversi ke Indonesia Rupiah secara otomatis (asumsikan saat ini masih dalam bentuk Rai Stone dari Yap Island)

- Membuat paragraph baru yang mengkonversi nilai dari RAI menjadi IDR, hanya perkalian
``` cobol
CONVERT-IDR.
	MOVE TMP-BALANCE TO FORMATTED-AMOUNT
	MOVE FORMATTED-AMOUNT TO TMP-IDR-BALANCE_NUM    
	MULTIPLY 16270 BY TMP-IDR-BALANCE_NUM
	MULTIPLY 7358 BY TMP-IDR-BALANCE_NUM
	MOVE TMP-IDR-BALANCE_NUM TO TMP-IDR-BALANCE.
```

### Deploy menggunakan kubernetes
- Deploy menggunakan **Azure Kubernetes Service or AKS** dengan container registry **Azure Container Registry or ACR**
- Berikut langkah deploy menggunakan kubernetes dengan cloud provide Azure:

1. SSH to VPS
2. Login Azure Account
```
az login --use-device-code
```
3. Login ACR
```
az acr login --name <acr_name>
```
4. Build container and push to ACR
```
docker build -t cobol-app:v4 .
docker tag cobol-app:v4 <acr_name>.azurecr.io/cobol-app:v4
docker push <acr_name>.azurecr.io/cobol-app:v4
```
5. Get AKS Credentials to Connect:
```
az aks get-credentials --resource-group tstrun_group --name tstrun
```
6. Create Manifest Files: `deployment.yaml`, `service.yaml`, and `pvc.yaml`. After that, Apply (check directory kubernetes). We use PVC to ensure data consistency between pod resets
```
kubectl apply -f <manifest>.yaml
```
7. Grant AKS Access to ACR
```
az aks update --name tstrun --resource-group tstrun_group --attach-acr tstrunacr
```

### Menambahkan fitur yang dapat menghitung bunga tiap 23 detik berdasarkan saldo serta menambahkannya ke saldo secara otomatis. Fitur harus dijalankan dengan argumen khusus --apply-interest

- Mengubah konfigurasi dockerfile sehingga saat subprocess python memanggil file "main" maka sebuah entrypoint yang dibuat melalui dockerfile akan dipanggil, dan entrypoint digunakan untuk memanggil compiled cobol dengan flag --apply-interest
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends libcob4 && \
    rm -rf /var/lib/apt/lists/* && \
    echo '#!/bin/sh' > main && \
    echo 'exec /app/main.bin ${COBOL_ARGS}' >> main && \
    chmod +x main && \
    chown -R appuser:appuser /app
```

- Logic untuk interest yaitu menghitung waktu sejak request terakhir, sehingga interest (0.5%) akan di-apply sesuai dengan selisih waktu terakhir request.
- Informasi interest disimpan menggunakan logic yang sama dengan menyimpan account, menggunakan file baru yaitu `interest.txt` dengan format `<acc_id:6><time:18>`
``` cobol
PROCESS-INTERESTS.
	OPEN INPUT INTS-FILE
	OPEN OUTPUT INTS-TEMP
	PERFORM WITH TEST AFTER UNTIL 0 = 1
	READ INTS-FILE
		AT END
		EXIT PERFORM
		NOT AT END
		MOVE INTS-RECORD(1:6) TO ACC-ACCOUNT
		MOVE INTS-RECORD(7:18) TO INT_THEN
		IF ACC-ACCOUNT = IN-ACCOUNT
			MOVE "Y" TO INT-FOUND
			DISPLAY INT-FOUND
			PERFORM APPLY-INTEREST
		ELSE
			WRITE ITEMP-RECORD FROM INTS-RECORD
		END-IF
	END-PERFORM
	CLOSE INTS-FILE
	CLOSE INTS-TEMP.

APPLY-INTEREST.
	CALL "time" RETURNING WS-UNIX-TIMESTAMP
	MOVE WS-UNIX-TIMESTAMP TO TMP_TIMESTAMP
	DISPLAY "TIMESTAMP: " TMP_TIMESTAMP
	MOVE TMP_TIMESTAMP TO INT_NOW
	COMPUTE DIFF_TIME = INT_NOW - INT_THEN
	DISPLAY "TIME THEN: " INT_THEN
	DISPLAY "DIFFERENCE TIME: " DIFF_TIME
	COMPUTE N_INT = DIFF_TIME / 23
	MOVE IN-ACCOUNT TO ITEMP-RECORD(1:6)
	MOVE INT_NOW TO ITEMP-RECORD(7:18)
	WRITE ITEMP-RECORD.
	MOVE "Y" TO INT-UPDATED.
```

### Tambahkan Reverse Proxy (e.g. nginx, etc) & Pasang Domain (wajib HTTPS)

- Since we are using K8, install Helm for Nginx Ingress: 
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

- Install Nginx Ingress from Helm: 
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.config.strict-validate-path-type=false \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-tcp-idle-timeout"=30
```

- Get Pub IP for Ingress, this is used for DNS provide to create a new A record: 
```
kubectl get service ingress-nginx-controller -n ingress-nginx --watch
```

- Install Cert-Manager for HTTPS:
```
curl -LO https://cert-manager.io/public-keys/cert-manager-keyring-2021-09-20-1020CF3C033D4F35BAE1C19E1226061C665DF13E.gpg

helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --verify \
  --keyring ./cert-manager-keyring-2021-09-20-1020CF3C033D4F35BAE1C19E1226061C665DF13E.gpg \
  --set crds.enabled=true
```

- Create more manifest files, cluster-issuer.yaml and ingress.yaml, and Apply (check directory kubernetes)
```
kubectl apply -f <manifest>.yaml
```

- Configure IP with DNS Service Provider (free subdomains: noIP)

### Working Deployed Application with HTTPS: https://scobol.ddns.net/
