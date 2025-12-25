from fastapi import FastAPII

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello World"}