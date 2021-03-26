import pandas as pd
import numpy as np
if __name__  == '__main__':
    data = pd.read_csv("../data/old_salaries.csv")
    data_new = pd.read_csv("../data/contract_data.csv")
    data.columns = ["Name", "Contract Value", "Year", "Season End", "Abrv", 
    "Team"]
    data = data.dropna(how = "all")
    print(data.isnull().sum())
    data = data.astype({'Year': 'int32'})
    print(data.head())
    #print(data_new.head())