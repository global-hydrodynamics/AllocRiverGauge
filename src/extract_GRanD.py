import pandas as pd
import os

raw_file = "./input/GRanD_alloc_full.csv"  # path to raw GRanD file
out_file = "./input/GRanD_allocated.csv"  # output file

###################################################

#if not os.path.exists("inp/GRanD"):
#    os.symlink(raw_file, "inp/GRanD")
#df = pd.read_csv("./inp/GRanD")
df = pd.read_csv(raw_file)

name_l = []
for i, row in df.iterrows():

    ## fill name column (DAMNAME)
    name = row['DAM_NAME_c']
    print(name)
    if name != name or len(name)==0:
        name = row['RES_NAME_c']
    if name != name or len(name) == 0:
        name = 'NoName'
    ## remove spaces
    name = name.replace(' ', '')
    name_l.append(name)


name2_l = []
for i, row in df.iterrows():

    ## fill name column
    name2 = row['RIVER_c']
    print(name2)
    if name2 != name2 or len(name2) == 0:
        name2 = 'NoName'

    ## remove spaces
    name2 = name2.replace(' ', '')
    name2_l.append(name2)


df['DAM_NAME_c'] = name_l
df['RIVER_c']    = name2_l

df_new = df.rename(columns={'DAM_NAME_c':'DamName', 'RIVER_c':'RiverName', 'DAM_HGT':'DamHeight'})

df_new[['ID', 'lat_alloc','lon_alloc','area_alloc', 'DamName','RiverName', 'CAP_MCM', 'YEAR','ALT_YEAR','REM_YEAR', 'ELEV_MASL','DAM_HGT_M', 'lat_ori','lon_ori','area_ori']].to_csv(out_file, index=None)
