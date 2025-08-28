# Overview
This is a project build using x86 Assembly for its backend. The project has features such as getting, uploading, editing, and deleting PNG images within a directory in the server. This project parses the HTTP Request from devices and serve static files or do API services if detected. This service utilizes the C Binary for parsing the HTTP request more efficiently.

### Deployment (if it works 😭): https://sasm.ddns.net/

## Run the server locally

Build the server: 
```
make build
```

Run the server;
```
make run
```

Open the server in a web browser, google chrome is preferable:
```
http://localhost:8080
```

## Features

### `GET /gallery`

This endpoint will get all PNG images within the server's directory `app/img` and returns a JSON array of all the PNG filenames found

- Example in bash: 
``` bash
└─$ curl http://localhost:8080/gallery     
["e.png","d.png","c.png","competition.png","b.png","g.png","f.png"]      
```

- Example in Application: 

![GET.png](/http_asm/docs/GET.png)

### `POST /gallery`

This endpoint will upload an image within the server's directory `app/img`. Basically reconstruct the server request's content. Handles `Expect Continue 100` or large image file aswell.

- Example in bash: 
```bash
└─$ curl -F "file=@GET.png" -X POST http://localhost:8080/
```

- Result: 
![POST.png](/http_asm/docs/POST.png)

The application uses Javascript with the same result when using the CURL expression above.

### `PUT /gallery/<filename>`

This endpoint will replace a current existing image. If the image doesn't exist, then it will create a new one. `<filename>` is the name of the image without the extension

- Example in bash:
```bash
└─$ curl -X PUT -T POST.png http://localhost:8080/gallery/GET
```

- Before: 
![POST.png](/http_asm/docs/POST.png)

- After:
![PUT.png](/http_asm/docs/PUT.png)

The application uses Javascript with the same result when using the CURL expression above.

### `DELETE /gallery/<filename>`

This endpoint will delete a current existing image. If there's no image that is specified then nothing happens. `<filename>` is the name of the image without the extension

- Example is bash:
```bash
curl -X DELETE http://localhost:8080/gallery/GET
```

- Before:
![PUT.png](/http_asm/docs/PUT.png) 

- After:
![DELETE.png](/http_asm/docs/DELETE.png)

The application uses Javascript with the same result when using the CURL expression above.

### [KREATIVITAS?] Gallery Idea I guess?