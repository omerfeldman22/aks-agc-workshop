import os
from flask import Flask

app = Flask(__name__)
APP_NAME = os.getenv("APP_NAME", "None")

@app.route('/')
def hello_world():
    return f'Hello World from {APP_NAME}!'

@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
