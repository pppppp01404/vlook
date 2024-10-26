import os
import requests
import pandas as pd
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
api_token = os.getenv('eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjQyODQ2OTMzOCwiYWFpIjoxMSwidWlkIjo2NzcxNzE5MSwiaWFkIjoiMjAyNC0xMC0yNlQwMDo1NTozMS4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MjYxMzYzMjYsInJnbiI6InVzZTEifQ.Boo7RM7ti9O2uAI6JEABnk-U2XpgihlnGYY574yBFT0')

if not api_token:
    raise ValueError("API token not found. Please set the MONDAY_API_TOKEN environment variable.")

# monday.com API endpoint
url = 'https://api.monday.com/v2'

# Headers for API requests
headers = {
    'Authorization': api_token,
    'Content-Type': 'application/json'
}

# Fetch user boards
def fetch_user_boards():
    query = '''
    {
        boards {
            id
            name
        }
    }'''
    
    response = requests.post(url, json={'query': query}, headers=headers)
    
    if response.status_code == 200:
        return response.json()['data']['boards']
    else:
        print('Error fetching boards:', response.status_code, response.text)
        return []

# Fetch board columns
def fetch_board_columns(board_id):
    query = f'''
    {{
        boards (ids: {board_id}) {{
            columns {{
                id
                title
                type
            }}
        }}
    }}'''
    
    response = requests.post(url, json={'query': query}, headers=headers)
    
    if response.status_code == 200:
        return response.json()['data']['boards'][0]['columns']
    else:
        print('Error fetching board columns:', response.status_code, response.text)
        return []

# Fetch board items (with column values)
def fetch_board_data(board_id):
    query = f'''
    {{
        boards (ids: {board_id}) {{
            items {{
                id
                name
                column_values {{
                    id
                    title
                    text
                }}
            }}
        }}
    }}'''
    
    response = requests.post(url, json={'query': query}, headers=headers)
    
    if response.status_code == 200:
        return response.json()['data']['boards'][0]['items']
    else:
        print('Error fetching board items:', response.status_code, response.text)
        return []

# VLOOKUP-like function
def vlookup(lookup_value, items, column_title):
    for item in items:
        for column in item['column_values']:
            if column['title'] == column_title and column['text'] == lookup_value:
                return item['name']  # Return the item name if found
    return None

if __name__ == "__main__":
    # Fetch and display user boards
    boards = fetch_user_boards()
    if not boards:
        print("No boards found or there was an error fetching boards.")
        exit()

    for i, board in enumerate(boards, start=1):
        print(f"{i}. Board ID: {board['id']}, Name: {board['name']}")
    
    # User selects a board
    board_index = int(input("Select the board number: ")) - 1
    selected_board_id = boards[board_index]['id']
    
    # Fetch and display columns of the selected board
    columns = fetch_board_columns(selected_board_id)
    if not columns:
        print("No columns found or there was an error fetching columns.")
        exit()

    for i, column in enumerate(columns, start=1):
        print(f"{i}. Column Title: {column['title']}, ID: {column['id']}, Type: {column['type']}")
    
    # User selects the column for VLOOKUP
    column_index = int(input("Select the column number for VLOOKUP: ")) - 1
    column_title = columns[column_index]['title']
    
    # Fetch items (rows) of the selected board
    items = fetch_board_data(selected_board_id)
    if not items:
        print("No items found or there was an error fetching items.")
        exit()
    
    # User inputs the lookup value
    lookup_value = input("Enter the value to look for: ")
    result = vlookup(lookup_value, items, column_title)
    
    # Display the result
    if result:
        print(f'Lookup result for "{lookup_value}": {result}')
    else:
        print(f'"{lookup_value}" not found in column "{column_title}".')
