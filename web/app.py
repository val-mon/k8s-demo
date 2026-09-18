import os
import socket

import requests
from flask import Flask, jsonify

API_URL = os.environ.get("API_URL", "http://api:5000")

app = Flask(__name__)


@app.get("/")
def index():
    try:
        r = requests.get(API_URL, timeout=2)
        return jsonify(web=socket.gethostname(), api_url=API_URL, api_response=r.json())
    except requests.RequestException as e:
        return jsonify(web=socket.gethostname(), api_url=API_URL, error=str(e)), 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
