import pandas as pd
import glob
import os

#change name of current to the one provided by shell/py?


myFolder = 'csv_data'
files = []
results = []
#new scan
current_file_name = 'csv_data/today_data.csv'
current_file = pd.read_csv(current_file_name)

#results of comparasion
results_file_name = 'results.csv'


if not os.path.exists(myFolder):
    os.makedirs(myFolder)


#Multi csv files
for file in glob.glob('csv_data/*.csv'):
    if file == current_file_name:
        continue;
    files.append(file)

    with open(os.path.join(os.getcwd(),file),mode='r') as myfile:
        df = pd.read_csv(myfile)
        for port in current_file['PORT']:
            if port not in df.values:
                results.append({'PORT': port})

                
                
results_df = pd.DataFrame(results, columns = ['PORT'])
if len(results_df)>0:
    print("\nNEW "+str(len(results_df))+" PORTS DETECTED!!")
    print(results_df)


