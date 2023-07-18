import os
import getpass
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# Get the current username
username = getpass.getuser()

# Construct the file path using the current username
file_path = f"/home/{username}/ocn_automation/finalresult"

# Read the content of the file
with open(file_path, 'r') as file:
    file_content = file.read()

# Specify your Slack token
slack_token = "API_TOKEN"

# Specify the Slack channel name
channel_name = "exedge-monitoring-results"

# Create a Slack WebClient instance
client = WebClient(token=slack_token)

# Format the output as a code block with a headline
output = f"*Cyber-Node Status Report*\n\n{file_content}\n"

# Send the formatted output to the Slack channel
try:
    response = client.chat_postMessage(
        channel=channel_name,
        text=output
    )
    print("Message sent successfully!")
except SlackApiError as e:
    print(f"Error sending message to Slack: {e.response['error']}")
