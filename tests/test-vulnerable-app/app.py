#!/usr/bin/env python3
"""
Intentionally Vulnerable Test Application
This file contains various security vulnerabilities for testing VAPT tools.
DO NOT USE IN PRODUCTION!
"""

import os
import sqlite3
from flask import Flask, request, render_template_string

app = Flask(__name__)

# Vulnerability 1: Hardcoded credentials
DATABASE_PASSWORD = "admin123"  # Insecure: Hardcoded password
API_KEY = "sk_live_abc123xyz789"  # Insecure: Hardcoded API key
AWS_SECRET = "AKIAIOSFODNN7EXAMPLE"  # Insecure: Hardcoded AWS key

# Vulnerability 2: SQL Injection
@app.route('/user')
def get_user():
    user_id = request.args.get('id')
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    # Insecure: SQL injection vulnerability
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor.execute(query)
    result = cursor.fetchone()
    return str(result)

# Vulnerability 3: XSS (Cross-Site Scripting)
@app.route('/search')
def search():
    query = request.args.get('q', '')
    # Insecure: XSS vulnerability
    return render_template_string(f"<h1>Search results for: {query}</h1>")

# Vulnerability 4: Command Injection
@app.route('/ping')
def ping():
    host = request.args.get('host')
    # Insecure: Command injection vulnerability
    result = os.system(f"ping -c 1 {host}")
    return f"Ping result: {result}"

# Vulnerability 5: Path Traversal
@app.route('/file')
def read_file():
    filename = request.args.get('name')
    # Insecure: Path traversal vulnerability
    with open(f"/var/www/files/{filename}", 'r') as f:
        content = f.read()
    return content

# Vulnerability 6: Weak Cryptography
import hashlib

def hash_password(password):
    # Insecure: Using MD5 for password hashing
    return hashlib.md5(password.encode()).hexdigest()

# Vulnerability 7: Insecure Deserialization
import pickle

@app.route('/load')
def load_data():
    data = request.args.get('data')
    # Insecure: Deserializing untrusted data
    obj = pickle.loads(data.encode())
    return str(obj)

# Vulnerability 8: Missing Authentication
@app.route('/admin/delete_user')
def delete_user():
    # Insecure: No authentication check
    user_id = request.args.get('id')
    # Delete user logic here
    return f"User {user_id} deleted"

# Vulnerability 9: Insecure Random
import random

def generate_token():
    # Insecure: Using non-cryptographic random
    return str(random.randint(1000, 9999))

# Vulnerability 10: Debug Mode Enabled
if __name__ == '__main__':
    # Insecure: Debug mode in production
    app.run(debug=True, host='0.0.0.0')
