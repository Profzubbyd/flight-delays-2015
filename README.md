# U.S. Airport Flight Delay Analysis

This repository contains an in-depth analysis of flight delay patterns across major U.S. airports. Using [this dataset](https://corgis-edu.github.io/corgis/csv/airlines/) from 2015, we examine how flight delay hours are influenced by various factors, such as on-time, diverted, canceled flights, and the number of carriers. The project applies longitudinal data analysis methods, focusing on multilevel modeling, to capture both fixed and random effects over time.

## Project Structure

- **Data Preparation**: The dataset includes delay minutes, on-time flight counts, carrier counts, and other relevant variables for 29 major U.S. airports. We prepared the data by converting the delay minutes into hours, which was used for the analysis.
- **Descriptive Analysis**: Initial visualizations, including time plot, spaghetti plot, correlation matrix, bar charts, and heatmap visualizations, are used to explore delay patterns by month and airport.
- **Statistical Modeling**: We employ a series of multilevel models with fixed and random effects to understand the influence of time and covariates (e.g., on-time flights) on flight delay hours. Model selection was based on fit indices such as -2LL, AIC and BIC.
- **Visualizations**: Key findings are presented through maps, heatmaps, and bar charts, illustrating the distribution of delay times across the U.S. and the temporal trends within each airport.

## Key Findings

1. **High Delays in Certain Airports**: Airports like Chicago O'Hare (ORD) and Atlanta (ATL) experienced the highest average delay durations, with delays peaking above 5,000 hours.
2. **Impact of On-Time Flights**: There is a positive association between on-time, diverted, canceled flights and delay hours, suggesting that things affecting other flights may contribute to longer delays.
3. **Monthly Trends**: The interaction between on-time flights and month indicates that this association diminishes over time, possibly reflecting operational adjustments or seasonal effects.

## Repository Contents

- **data**: Contains the raw and processed datasets with delay information for U.S. airports.
- **models**: Contains the code for multilevel models, including model selection and fit statistics.
- **visualizations/**: Generated visualizations, including heatmaps, bar charts, and maps, illustrating the findings.
- **README.md**: Project overview, setup instructions, and findings.
