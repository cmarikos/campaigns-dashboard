import pandas as pd

# List of CSV file paths
csv_files = [
    'ContactHistoryReport-1 - ContactHistoryReport-1160430803.csv',
    'ContactHistoryReport-2 - ContactHistoryReport-3215510414.csv',
    'ContactHistoryReport-3 - ContactHistoryReport-8785442276.csv',
    'ContactHistoryReport-4 - ContactHistoryReport-17273723297.csv'
]

# Read and concatenate all CSVs into one DataFrame
df_combined = pd.concat([pd.read_csv(file) for file in csv_files], ignore_index=True)

# Optional: Preview the combined DataFrame
print(df_combined.head())

# Export to a new CSV file
df_combined.to_csv('combined_CD7_2025.csv', index=False)
