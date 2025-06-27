# app.py
from flask import Flask, request, jsonify
import pdfplumber

app = Flask(__name__)

@app.route('/extract_invoice', methods=['POST'])
def extract_invoice():
    file = request.files['file']
    with pdfplumber.open(file) as pdf:
        page = pdf.pages[0]
        table = page.extract_table()
        items = []
        for row in table[1:]:  # skip header
            items.append(row)
        return jsonify(items)

if __name__ == '__main__':
    app.run(debug=True)
