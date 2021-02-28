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
max_players = 15
player_names = []
for player in players: 
    if(len(player_names) > max_players):
        continue
    player_names.append(player.find('a').get_text())

print(player_names)
    
