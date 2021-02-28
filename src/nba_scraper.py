import requests
import pandas as pd
from bs4 import BeautifulSoup


#testing for Hawks
def get_team_contracts(team, max_players, year):
    #covert team name and year for URL
    t_conv = team.lower().replace(" ", "-")
    yr =  "" if year == 2020 else year
    URL = 'https://www.spotrac.com/nba/{t}/cap/{y}'.format(t = t_conv, y = year)
    page = requests.get(URL)

    soup = BeautifulSoup(page.content, 'html.parser')

    #get player names
    results = soup.find(id = "main")

    players = results.find_all('td', class_='player')

    ##15 players per team, append text of name
    player_names = []
    for player in players: 
        if(len(player_names) >= max_players):
            break
        player_names.append(player.find('a').get_text())

        
    cap_vals = results.find_all('span', class_='cap')

    #player data shows as 6 values, 4 of which are relevant
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
    data = {'Team': [team]*max_players,
            'Year': [year]*max_players,
            'Name':player_names,
            'Age':ages,
            'Pos':pos,
            'Contract Value':contracts,
            'Type': contract_types}
    print(data)
    df = pd.DataFrame(data)
    return df

if __name__ == '__main__':
    contracts = pd.DataFrame()
    teams = ["Atlanta Hawks", "Boston Celtics","Brooklyn Nets", 
            "Charlotte Hornets", "Chicago Bulls", "Cleveland Cavaliers", 
            "Dallas Mavericks", "Denver Nuggets", "Detroit Pistons",
            "Golden State Warriors", "Houston Rockets", "Indiana Pacers",
            "Los Angeles Clippers", "Los Angeles Lakers", "Memphis Grizzlies",
            "Miami Heat", "Milwaukee Bucks", "Minnesota Timberwolves",
            "New Orleans Pelicans", "New York Knicks", "Oklahoma City Thunder",
            "Orlando Magic","Philadelphia 76ers", "Phoenix Suns", 
            "Portland Trail Blazers", "Sacramento Kings", "San Antonio Spurs",
            "Toronto Raptors", "Utah Jazz", "Washington Wizards"]
    start = 2018
    stop = 2020
    
    for team in teams:
        for year in range(start, stop):
            max_players = 15
            contracts = contracts.append(get_team_contracts(team, 
                                                            max_players, year))
    contracts.to_csv (r'..\data\contract_data.csv', index = False, header=True)


