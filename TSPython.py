# -*- coding: utf-8 -*-
"""
Created on Fri Oct 16 11:58:39 2026

@author: tingzhang
"""

import os
os.chdir("C:/Users/tingzhang/OneDrive - Cochlear Ltd/Documents/simulation")
os.getcwd()

import pandas as pd
df1 = pd.read_csv('API_EG.ELC.ACCS.ZS_DS2_en_csv_v2_987.csv', skiprows=4, index_col='Country Code', parse_dates=True)
df2 = pd.read_csv('Metadata_Country_API_EG.ELC.ACCS.ZS_DS2_en_csv_v2_987.csv', index_col='Country Code', parse_dates=True)
df1.head()
df2.head()
df = df1.join(df2)

df.info()
df = df.drop(columns=['Unnamed: 70', 'Unnamed: 5', 'SpecialNotes', 'TableName'])
new_order = list(df.columns[:1]) + list(df.columns[-2:]) + list(df.columns[1:-2])
df = df[new_order]

extra_cols = ['Country Name', 'Region', 'IncomeGroup', 'Indicator Name', 'Indicator Code']
df = df.reset_index().melt(id_vars=['Country Code'] + extra_cols,
                               var_name='Year', 
                               value_name='Electricity (%)')

import matplotlib.pyplot as plt
import seaborn as sns; sns.set()
df_pivot_avg = df.pivot_table(
    index=['Region', 'Year'], 
    values=['Electricity (%)'], 
    aggfunc='mean'
).reset_index()
df_pivot_avg.set_index('Year', inplace=True)
sns.lineplot(data=df_pivot_avg, x="Year", y="Electricity (%)", hue="Region", marker="o", linewidth=2.5)

import numpy as np
df['Year'] = df['Year'].astype(int)
df_region = df.pivot_table(
    index='Year',
    columns='Region',
    values='Electricity (%)',
    aggfunc='mean'
    )
yearly_ticks = np.arange(1990, 2026, 5)
df_region.plot(xticks=yearly_ticks, style=[':', '--', '-', '*', '+', '.', '^'], figsize=(12, 7))
#plt.legend(loc="center left", bbox_to_anchor=(0.88, 0.5), title="Region")
plt.title("Trend Analysis by Region Group (1990–2025)", fontsize=14, pad=15)
plt.xlabel("Year", fontsize=12)
plt.ylabel("Access to electricity (% of population)", fontsize=12)

