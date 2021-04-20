import pandas as pd
import numpy as np
if __name__  == '__main__':
    #read in data
    data = pd.read_csv("../data/old_salaries.csv")
    data_new = pd.read_csv("../data/contract_data.csv")

    #drop columns that are not in both and reformatting
    data.columns = ["Name", "Contract Value", "Year", "Season End", "Abrv", 
    "Team"]
    data = data.dropna(how = "all")
    data = data.astype({'Year': 'int32'})
    data = data.drop(columns = ["Season End", "Abrv"])
    data["Team"] = data["Team"].replace(['Boston Celtic'],'Boston Celtics')
    data_new = data_new.drop(columns = ["Age", "Pos"])
    
    #iterate and label first 4 years as rookie
    rookie_dict = {}
    contract_type = []

    for i, row in data.iterrows():
        curr_contract = row["Contract Value"]
        curr_contract = curr_contract.strip()[1:-3]
        curr_contract = int(curr_contract.replace(",", ""))
        if(row["Name"] not in rookie_dict and curr_contract <= 6200000):
            rookie_dict[row["Name"]] = row["Year"]
            contract_type.append("Rookie")
        elif(curr_contract <= 6200000 and row["Year"] <= rookie_dict[row["Name"]] + 3):
            contract_type.append("Rookie")
        else:
            contract_type.append("Non-rookie")

    data["Type"] = contract_type
    data = data.append(data_new)
    data.to_csv(r'../data/contract_all.csv')