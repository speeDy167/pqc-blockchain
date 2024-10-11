import asyncio
import websockets
import json
import requests
import logging

# Configure logging to store service logs
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Define WebSocket and HTTP URLs for Besu node
WS_URL = "ws://192.168.169.133:8546"  # Replace with your Besu WebSocket URL
HTTP_URL = "http://192.168.169.133:8545"  # Replace with your Besu HTTP URL

# Function to fetch the full block details using HTTP JSON-RPC
def get_block_by_hash(block_hash):
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_getBlockByHash",
        "params": [block_hash, True],  # True to include full transaction objects
        "id": 53
    }
    headers = {'Content-Type': 'application/json'}
    
    try:
        response = requests.post(HTTP_URL, json=payload, headers=headers)
        response.raise_for_status()  # Check for HTTP errors
        return response.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching block by hash: {e}")
        return None

# Async function to listen for new block events over WebSockets
async def listen_for_new_blocks():
    async with websockets.connect(WS_URL) as websocket:
        # Subscribe to new block headers
        subscription_request = {
            "jsonrpc": "2.0",
            "method": "eth_subscribe",
            "params": ["newHeads"],
            "id": 1
        }
        await websocket.send(json.dumps(subscription_request))
        logging.info("Subscribed to new block headers...")

        # Infinite loop to keep listening for block events
        while True:
            try:
                response = await websocket.recv()
                message = json.loads(response)

                # Check if it's a new block event
                if message.get("method") == "eth_subscription":
                    block_hash = message["params"]["result"]["hash"]
                    logging.info(f"New block with hash: {block_hash}")

                    # Fetch the full block details
                    block_data = get_block_by_hash(block_hash)
                    if block_data:
                        logging.info(block_data)  # Process the block data (store, analyze, etc.)
                    else:
                        logging.error(f"Failed to retrieve data for block hash: {block_hash}")

            except websockets.ConnectionClosed as e:
                logging.error(f"WebSocket connection closed: {e}")
                break  # Optionally handle reconnection here

# Function to process block data (e.g., store in a database or analyze)
def process_block_data(block_data):
    block_info = block_data.get("result")
    if block_info:
        block_number = block_info["number"]
        transactions = block_info["transactions"]
        logging.info(f"Processing block {block_number} with {len(transactions)} transactions")
        
        # Example: Print out the transactions or store them in a database
        for tx in transactions:
            logging.info(f"Transaction {tx['hash']} from {tx['from']} to {tx.get('to', 'Contract Creation')}")

        # Add additional logic to store block data in a database, send notifications, etc.
    else:
        logging.error("No block data found to process.")

# Entry point for the back-end service
if __name__ == "__main__":
    try:
        # Run the WebSocket listener as a long-running service
        asyncio.get_event_loop().run_until_complete(listen_for_new_blocks())
    except KeyboardInterrupt:
        logging.info("Service interrupted and stopped.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")
