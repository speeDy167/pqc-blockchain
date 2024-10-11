import asyncio
import websockets
import json
import requests
import logging
from web3 import Web3


# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Define WebSocket and HTTP URLs for source Besu node
WS_URL = "ws://192.168.169.133:8546"  # Replace with your Besu WebSocket URL
HTTP_URL = "http://192.168.169.133:8545"  # Replace with your Besu HTTP URL

# Define HTTP URL for destination Besu network (where the smart contract is deployed)
DEST_BESU_URL = "http://192.168.169.133:8585"  # Replace with your destination Besu network HTTP URL

# Your deployed contract address and ABI (Make sure to replace this with actual deployed contract details)
CONTRACT_ADDRESS = "0x8CdaF0CD259887258Bc13a92C0a6dA92698644C0"
ABI = """
[
  {
    "inputs": [],
    "name": "lastBlockData",
    "outputs": [
      {
        "internalType": "string",
        "name": "blockHash",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "parentHash",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "transactionsRoot",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_blockHash",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "_parentHash",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "_transactionsRoot",
        "type": "string"
      }
    ],
    "name": "storeBlockData",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getBlockData",
    "outputs": [
      {
        "components": [
          {
            "internalType": "string",
            "name": "blockHash",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "parentHash",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "transactionsRoot",
            "type": "string"
          }
        ],
        "internalType": "struct BlockDataStorage.BlockData",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  }
]
"""

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
                        process_block_data(block_data)  # Process the block data (log, analyze, send to contract, etc.)
                    else:
                        logging.error(f"Failed to retrieve data for block hash: {block_hash}")

            except websockets.ConnectionClosed as e:
                logging.error(f"WebSocket connection closed: {e}")
                break  # Optionally handle reconnection here

# Function to send block data to the smart contract
def send_data_to_contract(block_hash, parent_hash, transactions_root):
    # Initialize a Web3 instance for the destination Besu network
    web3 = Web3(Web3.HTTPProvider(DEST_BESU_URL))
    
    if not web3.is_connected():
        logging.error("Failed to connect to the destination Besu network")
        return

    # Load the contract
    contract = web3.eth.contract(address=CONTRACT_ADDRESS, abi=ABI)
    functions = dir(contract.functions)
    print(functions)  # Check if storeBlockData is listed here


    # Set the default account (you need to replace this with the correct private key or address)
    private_key = "0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"  # Replace with your private key
    account = web3.eth.account.from_key(private_key)


    # Convert block hash, parent hash, and transactions root to strings (hex format is already string in this case)
    block_hash_str = block_hash
    parent_hash_str = parent_hash
    transactions_root_str = transactions_root

    # Prepare the transaction to call the smart contract function `storeBlockData`
    txn = contract.functions.storeBlockData(
        block_hash_str,  # block hash as string
        parent_hash_str,  # parent hash as string
        transactions_root_str  # transactions root as string
    ).build_transaction({
        'from': account.address,
        'nonce': web3.eth.get_transaction_count(account.address),
        'gas': 2000000,  # Adjust gas limit as needed
        'gasPrice': 0,
        'chainId': 1338  
    })

    # Sign and send the transaction
    signed_txn = web3.eth.account.sign_transaction(txn, private_key)
    txn_hash = web3.eth.send_raw_transaction(signed_txn.raw_transaction)

    logging.info(f"Sent transaction with hash: {txn_hash.hex()}")


# Function to process block data and send it to the smart contract
def process_block_data(block_data):
    block_info = block_data.get("result")
    if block_info:
        block_number = block_info["number"]
        block_hash = block_info["hash"]
        parent_hash = block_info["parentHash"]
        transactions_root = block_info["transactionsRoot"]

        logging.info(f"Processing block {block_number}")
        logging.info(f"Block Hash: {block_hash}")
        logging.info(f"Parent Hash: {parent_hash}")
        logging.info(f"Transactions Root: {transactions_root}")

        # Send the block data to the smart contract on the destination Besu network
        send_data_to_contract(block_hash, parent_hash, transactions_root)
    else:
        logging.error("No block data found to process.")

# Entry point for the service
if __name__ == "__main__":
    try:
        # Run the WebSocket listener as a long-running service
        asyncio.get_event_loop().run_until_complete(listen_for_new_blocks())
    except KeyboardInterrupt:
        logging.info("Service interrupted and stopped.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")
