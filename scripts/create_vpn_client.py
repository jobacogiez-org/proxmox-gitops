import sqlite3
import uuid
import sys
import os
import subprocess

def create_client(db_path, client_name):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT address FROM clients_table ORDER BY address DESC LIMIT 1")
    last_ip = c.fetchone()
    if last_ip:
        last_ip = last_ip[0]
        last_ip = last_ip.split('/')[0]
        last_octet = int(last_ip.split('.')[3])
        new_ip = f"10.8.0.{last_octet + 1}/32"
    else:
        new_ip = "10.8.0.2/32"

    private_key = subprocess.check_output(['wg', 'genkey']).decode('utf-8').strip()
    public_key = subprocess.check_output(['wg', 'pubkey'], input=private_key.encode('utf-8')).decode('utf-8').strip()
    client_id = str(uuid.uuid4())

    c.execute("INSERT INTO clients_table (id, name, address, private_key, public_key, created_at, updated_at) VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))",
              (client_id, client_name, new_ip, private_key, public_key))
    conn.commit()
    conn.close()
    print(f"Client {client_name} created with IP {new_ip}. Private key: {private_key}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 create_vpn_client.py <db_path> <client_name>")
        sys.exit(1)
    create_client(sys.argv[1], sys.argv[2])
