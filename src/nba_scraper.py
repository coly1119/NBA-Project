import requests
import pandas as pd
from bs4 import BeautifulSoup


#testing for Hawks
URL = 'https://www.spotrac.com/nba/atlanta-hawks//cap'
page = requests.get(URL)

soup = BeautifulSoup(page.content, 'html.parser')

#get player names
results = soup.find(id = "main")

players = results.find_all('td', class_='player')

##15 players per team, append text of name
max_players = 15   #fn input later
player_names = []
for player in players: 
    if(len(player_names) > max_players):
        break
    player_names.append(player.find('a').get_text())

#print(player_names)
    
cap_vals = results.find_all('span', class_='cap')

#player data shows as 7 values, 4 of which are relevant
html_step = 6
i = 0
ages = []
pos = []
contracts = []
contract_types = []

for cap_val in cap_vals:
    if(i >= html_step * max_players):
        break
    if i % html_step == 0:
        ages.append(cap_val.get_text())
    elif i % html_step == 1:
        pos.append(cap_val.get_text())
    elif i % html_step == 2:
        contracts.append(cap_val.get_text())
    elif i % html_step == 3:
        contract_types.append(cap_val.get_text())
    i += 1


