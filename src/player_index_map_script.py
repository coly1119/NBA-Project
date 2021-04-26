import pandas as pd
import numpy as np 
import sys

path_to_data = sys.argv[1] # user inputs the path to the play-by-play data
path_to_playerlist = sys.argv[2]
path_to_save = sys.argv[3] # user inputs path to where they want to store the resulting csv file

data = pd.read_csv(path_to_data)

playerlist = pd.read_csv(path_to_playerlist)

subdata = data[['GAME_ID', 'HOME_TEAM', 'AWAY_TEAM', 'PCTIMESTRING', 'PERIOD', 'SCOREMARGIN', 'SUB_ENTERED_PLAYER_ID', 'SHOT_PLAYER_ID', 'TURNOVER_PLAYER_ID', 'FREE_THROW_PLAYER_ID', 'REBOUND_PLAYER_ID', 'HOME_PLAYER_ID_1', 'HOME_PLAYER_ID_2', 'HOME_PLAYER_ID_3', 'HOME_PLAYER_ID_4', 'HOME_PLAYER_ID_5', 'AWAY_PLAYER_ID_1', 'AWAY_PLAYER_ID_2', 'AWAY_PLAYER_ID_3', 'AWAY_PLAYER_ID_4', 'AWAY_PLAYER_ID_5']]

new_scoremargin = subdata.SCOREMARGIN.replace("TIE", 0)

subdata.drop("SCOREMARGIN", axis = 1, inplace = True)
subdata.insert(3, 'SCOREMARGIN', new_scoremargin, True)


def calculate_possessions(fga, to, fta, oreb):
    """
    This function takes in field goal attemps (fga), turnovers (to), free throw attempts (fta), and offensive rebounds 
    (oreb) and outputs the number of possessions from this run of play.
    """
    return 0.96 * (fga + to + 0.44 * fta - oreb)

# Initialize some variables that will keep track of various statistics to be used for computing possessions and point differential for shifts
home_players = set()
away_players = set()
# initialize home and road team variables
home_team = None
away_team = None
new_shift = True
game_id = None
initial_margin = 0 # this will keep track of the score margin at the start of each shift. Note: score margin = home - road scores
final_margin = 0 # this will keep track of the score margin at the end of each shift.
fg_attempts = 0 # field goal attempts
turnovers = 0
free_throws = 0
oreb = 0 # offensive rebounds
last_shooter = 0 # this keeps track of the most recent field goal shooter so we can check if the subsequent rebound is offensive or defensive

results = [] # initialize results list. We will append lists to this, so it will end up as a 2d list which we can then cast to a dataframe.

##################################################

# CREATE SHIFTS DATASET  
for i in range(len(subdata)):
    
    if i % 10000 == 0: print(i)
        
    if new_shift:
        # clear old players from sets and add new players for this new shift
        home_players.clear()
        away_players.clear()
        # add home players
        for j in range(1, 6):
            player = subdata['HOME_PLAYER_ID_' + str(j)].iloc[i]
            home_players.add(player)
        # add away players
        for j in range(1, 6):
            player = subdata['AWAY_PLAYER_ID_' + str(j)].iloc[i]
            away_players.add(player)
            
        # reset home and away teams
        home_team = subdata.iloc[i]['HOME_TEAM']
        away_team = subdata.iloc[i]['AWAY_TEAM']
            
        new_shift = False
        
        # reset these stats
        fg_attempts = 0 
        turnovers = 0
        free_throws = 0
        oreb = 0 
        initial_margin = final_margin # the new initial margin gets reset to the old final margin
        
        # NOTE - DO NOT RESET last_shooter UNLESS IT'S A NEW GAME
        cur_game_id = subdata.iloc[i]['GAME_ID']
        if cur_game_id != game_id: # then we have a new game
            game_id = cur_game_id # reset game_id
            last_shooter = 0
            initial_margin = 0
        
    # if a sub enters then we start a new shift and record the old shift
    
    cur_game_id = subdata.iloc[i]['GAME_ID']
    
    # two ways for a shift to end: substitution or new game
    if (not pd.isna(subdata.iloc[i]['SUB_ENTERED_PLAYER_ID'])) or cur_game_id != game_id:
        new_shift = True
 
        # record total point differential
        point_diff = int(final_margin) - int(initial_margin)
        
        # record total number of possessions
        num_possessions = calculate_possessions(fg_attempts, turnovers, free_throws, oreb)
        
        # if we somehow end up in a strange situation with zero possessions, then just continue and don't bother saving this data
        if num_possessions == 0:
            continue
            
        # add this data to some results dataframe
        shift = [point_diff, num_possessions, home_team, away_team]
        for player in home_players: # add home players to shift
            shift.append(player)
        for player in away_players: # add away players to shift
            shift.append(player)
        
        results.append(shift) # add this shift to our results list
    
    else:
        # first check to update the final_margin - this will be kept on a rolling basis (each time we see a new score margin this is the current final margin)
        if not pd.isna(subdata.iloc[i]['SCOREMARGIN']):
            final_margin = subdata.iloc[i]['SCOREMARGIN']
            
        # start aggregating point fg attempts, ft attempts, o-rebounds, and turnovers
        if not pd.isna(subdata.iloc[i]['SHOT_PLAYER_ID']):
            fg_attempts += 1
            last_shooter = subdata.iloc[i]['SHOT_PLAYER_ID'] # update most recent shooter
        if not pd.isna(subdata.iloc[i]['TURNOVER_PLAYER_ID']):
            turnovers += 1
        if not pd.isna(subdata.iloc[i]['FREE_THROW_PLAYER_ID']):
            free_throws += 1
            last_shooter = subdata.iloc[i]['FREE_THROW_PLAYER_ID'] # update most recent shooter for free throws as well
        if not pd.isna(subdata.iloc[i]['REBOUND_PLAYER_ID']):
            # now we need to check if the rebounder is on the same team as the most recent shooter
            rebounder = subdata.iloc[i]['REBOUND_PLAYER_ID']
            # if last shooter and rebounder are on the same team - increment offensive rebounds
            if ((last_shooter in home_players) and (rebounder in home_players)) or ((last_shooter in away_players) and (rebounder in away_players)):
                oreb += 1
                
        
# Make sure we also append the last shift when we reach the end of the dataset

# record total point differential
point_diff = int(final_margin) - int(initial_margin)

# record total number of possessions
num_possessions = calculate_possessions(fg_attempts, turnovers, free_throws, oreb)

# if we somehow end up in a strange situation with zero possessions, then just continue and don't bother saving this data
if num_possessions == 0:
    go = False
else:
    go = True

if go:
    # add this data to some results dataframe
    shift = [point_diff, num_possessions]
    for player in home_players: # add home players to shift
        shift.append(player)
    for player in away_players: # add away players to shift
        shift.append(player)

    results.append(shift) # add this shift to our results list
            

shifts = pd.DataFrame(results)
shifts.columns = ['point_differential', 'num_possessions', 'home_team', 'away_team', 'home_player_1', 'home_player_2', 'home_player_3', 'home_player_4', 'home_player_5', 'away_player_1', 'away_player_2', 'away_player_3', 'away_player_4', 'away_player_5']

shifts.dropna(subset=['away_player_5'], how='all', inplace=True)
shifts.dropna(subset=['away_player_4'], how='all', inplace=True)
shifts.dropna(subset=['away_player_3'], how='all', inplace=True)
shifts.dropna(subset=['away_player_2'], how='all', inplace=True)
shifts.dropna(subset=['away_player_1'], how='all', inplace=True)

shifts.dropna(subset=['home_player_5'], how='all', inplace=True)
shifts.dropna(subset=['home_player_4'], how='all', inplace=True)
shifts.dropna(subset=['home_player_3'], how='all', inplace=True)
shifts.dropna(subset=['home_player_2'], how='all', inplace=True)
shifts.dropna(subset=['home_player_1'], how='all', inplace=True)

##################################################

# Now start creating player index map

index = 0 # initialize index to zero
player_index_map = dict() # initialize player to index mapping as dictionary
# first iterate through home columns (this should cover everything, but we will also do away columns just in case)
for i in range(1, 6):
    name = "home_player_" + str(i)
    players = pd.unique(shifts[name])
    for player in players:
        if player not in player_index_map:
            player_index_map[player] = index
            index += 1
        else:
            continue # if player is already in the index then continue
            
# now iterate through away columns to catch any special cases of players who only participated in away games
for i in range(1,6):
    name = "away_player_" + str(i)
    players = pd.unique(shifts[name])
    for player in players:
        if player not in player_index_map:
            player_index_map[player] = index
            index += 1
        else:
            continue # if player is already in the index then continue

player_index_df = pd.DataFrame(list(player_index_map.items()))
player_index_df.columns = ["player_id", "index"]

player_ids = player_index_df.player_id
player_names = []
for item in player_ids:
    cur_id = item
    # if pd.isna(cur_id): 
    #     na_indexes.append(cur_id)
    #     continue # skip NA's
    cur_row = playerlist.loc[playerlist.PERSON_ID == cur_id]
    name = cur_row.DISPLAY_FIRST_LAST.iloc[0]
    player_names.append(name)


player_index_df['player_name'] = player_names

player_index_df.to_csv(path_to_save)



