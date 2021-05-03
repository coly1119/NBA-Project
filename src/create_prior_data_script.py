import pandas as pd 
import numpy as np 
from sklearn.linear_model import RidgeCV

# read in all veteran data
vet10 = pd.read_csv("../data/Contract+team2010_NonRookie.csv")
vet11 = pd.read_csv("../data/Contract+team2011_NonRookie.csv")
vet12 = pd.read_csv("../data/Contract+team2012_NonRookie.csv")
vet13 = pd.read_csv("../data/Contract+team2013_NonRookie.csv")
vet14 = pd.read_csv("../data/Contract+team2014_NonRookie.csv")
vet15 = pd.read_csv("../data/Contract+team2015_NonRookie.csv")
vet16 = pd.read_csv("../data/Contract+team2016_NonRookie.csv")
vet17 = pd.read_csv("../data/Contract+team2017_NonRookie.csv")

# read in all rookie data
rookie10 = pd.read_csv("../data/Contract+team2010_Rookie.csv")
rookie11 = pd.read_csv("../data/Contract+team2011_Rookie.csv")
rookie12 = pd.read_csv("../data/Contract+team2012_Rookie.csv")
rookie13 = pd.read_csv("../data/Contract+team2013_Rookie.csv")
rookie14 = pd.read_csv("../data/Contract+team2014_Rookie.csv")
rookie15 = pd.read_csv("../data/Contract+team2015_Rookie.csv")
rookie16 = pd.read_csv("../data/Contract+team2016_Rookie.csv")
rookie17 = pd.read_csv("../data/Contract+team2017_Rookie.csv")

# read in all player index maps
player_index_map_2010 = pd.read_csv("../data/player_index_map_2010-11.csv")
player_index_map_2011 = pd.read_csv("../data/player_index_map_2011-12.csv")
player_index_map_2012 = pd.read_csv("../data/player_index_map_2012-13.csv")
player_index_map_2013 = pd.read_csv("../data/player_index_map_2013-14.csv")
player_index_map_2014 = pd.read_csv("../data/player_index_map_2014-15.csv")
player_index_map_2015 = pd.read_csv("../data/player_index_map_2015-16.csv")
player_index_map_2016 = pd.read_csv("../data/player_index_map_2016-17.csv")
player_index_map_2017 = pd.read_csv("../data/player_index_map_2017-18.csv")

# read in all shifts data
shifts_2010 = pd.read_csv("../data/shifts_data_final_2010_11.csv")
shifts_2011 = pd.read_csv("../data/shifts_data_final_2011_12.csv")
shifts_2012 = pd.read_csv("../data/shifts_data_final_2012_13.csv")
shifts_2013 = pd.read_csv("../data/shifts_data_final_2013_14.csv")
shifts_2014 = pd.read_csv("../data/shifts_data_final_2014_15.csv")
shifts_2015 = pd.read_csv("../data/shifts_data_final_2015_16.csv")
shifts_2016 = pd.read_csv("../data/shifts_data_final_2016_17.csv")
shifts_2017 = pd.read_csv("../data/shifts_data_final_2017_18.csv")

vet_lst = [vet10, vet11, vet12, vet13, vet14, vet15, vet16, vet17]
rookie_lst = [rookie10, rookie11, rookie12, rookie13, rookie14, rookie15, rookie16, rookie17]
player_index_map_lst = [player_index_map_2010, player_index_map_2011, player_index_map_2012, player_index_map_2013, player_index_map_2014, player_index_map_2015, player_index_map_2016, player_index_map_2017]
shifts_lst = [shifts_2010, shifts_2011, shifts_2012, shifts_2013, shifts_2014, shifts_2015, shifts_2016, shifts_2017]

for i in range(len(vet_lst)):
    vet_lst[i].drop(vet_lst[i].columns[0], axis = 1, inplace = True)
for i in range(len(rookie_lst)):
    rookie_lst[i].drop(rookie_lst[i].columns[0], axis = 1, inplace = True)
for i in range(len(player_index_map_lst)):
    player_index_map_lst[i].drop(player_index_map_lst[i].columns[0], axis = 1, inplace = True)
for i in range(len(shifts_lst)):
    shifts_lst[i].drop(shifts_lst[i].columns[0], axis = 1, inplace = True)


for w in range(4):
    print("ROUND ", w)
    main_train_df_vets = None # 5 year data of vets
    main_train_df_rookies = None # 5 year data of rookies
    train_df_vets = None # 4 year data of vets (to train, before validation)
    train_df_rookies = None # 4 year data of rookies (to train, before validation)
    validate_df_vets = None # 1 most recent year of data for vets - validation set
    validate_df_rookies = None # 1 most recent year of data for rookies - validation set

    count = -1 # this will keep track of when we concatenate to train_df or validate_df

    for j in range(w, w+5):
        print("progress")
        count += 1

        cur_vet = vet_lst[j]
        cur_rookie = rookie_lst[j]
        cur_player_index_map = player_index_map_lst[j]
        cur_shift = shifts_lst[j]

        # get index and player_id into rookie and vet dfs by joining with player index maps
        cur_rookie = cur_rookie.merge(cur_player_index_map, how = "inner", left_on = "name", right_on = "player_name")
        cur_vet = cur_vet.merge(cur_player_index_map, how = "inner", left_on = "name", right_on = "player_name")

        # Now prepare data for ridge model training
        if 'home_team' in cur_shift.columns and 'away_team' in cur_shift.columns:
            cur_shift.drop(['home_team', 'away_team'], axis = 1, inplace = True)

        new_cols = []
        for i in range(np.shape(cur_shift)[1]):
            if i == 0:
                new_cols.append("point_diff")
            else:
                new_cols.append("p" + str(i-1))

        x_df = cur_shift
        x_df.columns = new_cols

        # Now fit ridge model
        x = np.array(x_df.iloc[:,1:])
        y = np.array(x_df.iloc[:,0])

        # cross validate for lambda
        ridge_model = RidgeCV(alphas=[1e-3, 1e-2, 1e-1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100]).fit(x, y)

        # get dataframe of ridge coefficients
        coef_df = pd.DataFrame({'coefs': ridge_model.coef_, 'index': [i for i in range(len(ridge_model.coef_))]})

        cur_rookie = cur_rookie.merge(coef_df, how = "inner", on = "index")
        cur_vet = cur_vet.merge(coef_df, how = "inner", on = "index")

        if isinstance(main_train_df_rookies, pd.DataFrame):
            # concatenate 
            main_train_df_rookies = pd.concat([main_train_df_rookies, cur_rookie], ignore_index = True)
        else:
            main_train_df_rookies = cur_rookie
        if isinstance(main_train_df_vets, pd.DataFrame):
            # concatenate
            main_train_df_vets = pd.concat([main_train_df_vets, cur_vet], ignore_index = True)
        else:
            main_train_df_vets = cur_vet
        if count < 4:
            if isinstance(train_df_rookies, pd.DataFrame):
                train_df_rookies = pd.concat([train_df_rookies, cur_rookie], ignore_index = True)
            else:
                train_df_rookies = cur_rookie
            if isinstance(train_df_vets, pd.DataFrame):
                train_df_vets = pd.concat([train_df_vets, cur_vet], ignore_index = True)
            else:
                train_df_vets = cur_vet
                
        else:
            validate_df_rookies = cur_rookie
            validate_df_vets = cur_vet

    # Now write the dataframes to csv in their respective folders
    if w == 0:
        # we are pre 15/16 season
        main_train_df_rookies.to_csv("../data/pre_2015_16/main_train_rookies.csv")
        main_train_df_vets.to_csv("../data/pre_2015_16/main_train_vets.csv")
        train_df_rookies.to_csv("../data/pre_2015_16/train_rookies.csv")
        train_df_vets.to_csv("../data/pre_2015_16/train_vets.csv")
        validate_df_rookies.to_csv("../data/pre_2015_16/validate_rookies.csv")
        validate_df_vets.to_csv("../data/pre_2015_16/validate_vets.csv")

    elif w == 1:
        # we are pre 16/17 season
        main_train_df_rookies.to_csv("../data/pre_2016_17/main_train_rookies.csv")
        main_train_df_vets.to_csv("../data/pre_2016_17/main_train_vets.csv")
        train_df_rookies.to_csv("../data/pre_2016_17/train_rookies.csv")
        train_df_vets.to_csv("../data/pre_2016_17/train_vets.csv")
        validate_df_rookies.to_csv("../data/pre_2016_17/validate_rookies.csv")
        validate_df_vets.to_csv("../data/pre_2016_17/validate_vets.csv")

    elif w == 2:
        # we are pre 17/18 season
        main_train_df_rookies.to_csv("../data/pre_2017_18/main_train_rookies.csv")
        main_train_df_vets.to_csv("../data/pre_2017_18/main_train_vets.csv")
        train_df_rookies.to_csv("../data/pre_2017_18/train_rookies.csv")
        train_df_vets.to_csv("../data/pre_2017_18/train_vets.csv")
        validate_df_rookies.to_csv("../data/pre_2017_18/validate_rookies.csv")
        validate_df_vets.to_csv("../data/pre_2017_18/validate_vets.csv")

    else:
        # we are pre 18/19 season
        main_train_df_rookies.to_csv("../data/pre_2018_19/main_train_rookies.csv")
        main_train_df_vets.to_csv("../data/pre_2018_19/main_train_vets.csv")
        train_df_rookies.to_csv("../data/pre_2018_19/train_rookies.csv")
        train_df_vets.to_csv("../data/pre_2018_19/train_vets.csv")
        validate_df_rookies.to_csv("../data/pre_2018_19/validate_rookies.csv")
        validate_df_vets.to_csv("../data/pre_2018_19/validate_vets.csv")
            

