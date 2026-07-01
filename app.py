from flask import Flask, render_template
import os, datetime, socket

app = Flask(__name__)
DATA_DIR = "/data"
LOG_FILE = os.path.join(DATA_DIR, "visits.log")

@app.route("/")
def index():
    try:
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(LOG_FILE, "a") as f:
            f.write(f"{datetime.datetime.now()}\n")
        with open(LOG_FILE) as f:
            count = len(f.readlines())
    except Exception as e:
        count = "Error"
        print(f"Error accessing PVC: {e}")

    hostname = socket.gethostname()
    return render_template("index.html", count=count, hostname=hostname)

@app.route("/health")
def health():
    return "ok\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
