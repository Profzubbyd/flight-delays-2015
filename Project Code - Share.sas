* Output options: page number, date, centering, or page breaks, page length and width;
OPTIONS NOnumber NOdate NOcenter FormDlim=" " PageSize=MAX LineSize=MAX;
* Eliminate SAS default titles and names of tables in output (TRACE ON to show);
TITLE; ODS TRACE OFF; ODS LISTING;

***********************************************************************************;
*******             MACRO PROGRAMS TO AUTOMATE CALCULATIONS                 *******;
*******               NOTHING IN HERE NEEDS TO BE CHANGED                   *******;
***********************************************************************************;

* To use FitTest macro;
* FitFewer = Name of ODS InfoCrit table for nested model;
* FitMore  = Name of ODS InfoCrit table for comparison model;
%MACRO FitTest(FitFewer=,FitMore=);
DATA &FitFewer.; LENGTH Name $30.; SET &FitFewer.; Name="&FitFewer."; RUN;
DATA &FitMore.;  LENGTH Name $30.; SET &FitMore.;  Name="&FitMore.";  RUN;
DATA FitCompare; LENGTH Name $30.; SET &FitFewer. &FitMore.; RUN;
DATA FitCompare; SET FitCompare; DevDiff=Lag1(Neg2LogLike)-Neg2LogLike;
     DFdiff=Parms-LAG1(Parms); Pvalue=1-PROBCHI(DevDiff,DFdiff);
     DROP AICC HQIC CAIC; RUN;
TITLE9 "Likelihood Ratio Test for &FitFewer. vs. &FitMore.";
PROC PRINT NOOBS DATA=FitCompare; RUN; TITLE9;
%MEND FitTest;

* To use PseudoR2 macro;
* Ncov =     TOTAL # entries in covariance parameter estimates table;
* CovFewer = Name of ODS CovParms table for nested model;
* CovMore =  Name of ODS CovParms table for comparison model;
%MACRO PseudoR2(NCov=,CovFewer=,CovMore=);
DATA &CovFewer.; LENGTH Name $30.; SET &CovFewer.; Name="&CovFewer."; RUN;
DATA &CovMore.;  LENGTH Name $30.; SET &CovMore.;  Name="&CovMore.";  RUN;
DATA CovCompare; LENGTH Name $30.; SET &CovFewer. &CovMore.; RUN;
DATA CovCompare; SET CovCompare; 
     PseudoR2=(LAG&Ncov.(Estimate)-Estimate)/LAG&Ncov.(Estimate); RUN;
DATA CovCompare; SET CovCompare; 
     IF CovParm IN("UN(2,1)","UN(3,1)","UN(4,1)","UN(3,2)","UN(4,2)","UN(4,3)") 
     THEN DELETE; RUN;
TITLE9 "PsuedoR2 (% Reduction) for &CovFewer. vs. &CovMore.";
PROC PRINT NOOBS DATA=CovCompare; RUN; TITLE9;
%MEND PseudoR2;

***********************************************************************************;
*******                    DESCRIPTIVES AND PLOTS                           *******;
***********************************************************************************;


/* Import the File */
proc import datafile='/home/sasuser.v94/Project/airlines.csv'
    out=airlines
    dbms=csv
    replace;
run;

libname project '/home/sasuser.v94/Project';


/* Create the long format dataset by stacking each HBA1C column with its corresponding Time value */
data airlines_2015;
    set airlines;
    Delay_m = input(strip('Statistics.Minutes Delayed.Tota'n), best12.);
    carriers = input(strip('Statistics.Carriers.Total'n), best12.);
    cancelled = input(strip('Statistics.Flights.Cancelled'n), best12.);
    delay_flights = input(strip('Statistics.Flights.Delayed'n), best12.);
    on_time_flights = input(strip('Statistics.Flights.On Time'n), best12.);
    diverted_flights = input(strip('Statistics.Flights.Diverted'n), best12.);
    delay_weather = input(strip('Statistics.# of Delays.Weather'n), best12.);
    carrier_minutes = input(strip('Statistics.Minutes Delayed.Carr'n), best12.);
    total_flights = input(strip('Statistics.Flights.Total'n), best12.);
    delayed_late_aircrafts = input(strip('Statistics.Minutes Delayed.Late'n), best12.);
    delay_weather_minutes = input(strip('Statistics.Minutes Delayed.Weat'n), best12.);
    Delay_in_hours = Delay_m / 60;
    if Time.Year = 2015;
    rename 'Airport.Code'n = AID;
    time_cts = Time.Month - 1; output;
    drop 'Statistics.Minutes Delayed.Tota'n 'Statistics.Carriers.Total'n 'Statistics.Flights.Cancelled'n
    		'Statistics.Flights.Delayed'n 'Statistics.Flights.On Time'n 'Statistics.# of Delays.Weather'n
    		'Statistics.Flights.Diverted'n 'Statistics.Minutes Delayed.Carr'n 'Statistics.Flights.Total'n 
			'Statistics.Minutes Delayed.Late'n 'Statistics.Minutes Delayed.Weat'n;

run;

/* Convert Time_Month_Zero to categorical by creating a character version */
data airlines_2015;
    set airlines_2015;
    Time = put(time_cts, 2.); /* Creates a character variable */
run;




/* Means and Variances for the Whole Cohort */
proc means data=airlines_2015 mean var;
	class TIME;
    var Delay_in_hours; 
    title "Means and Variances of Minutes Delayed by All Flights";
run;

/* Set a higher resolution and larger image size */
ods graphics / width=1200px height=800px imagefmt=png ;

/* Time Plot of Mean Hemoglobin A1c for Each Group by Time */
/* TIME PLOT */
PROC SGPLOT data=airlines_2015;
	scatter y=Delay_in_hours x=time_cts;
	yaxis label="Flight Delay Duration (Hours)";
    xaxis label="Month" values=(0 to 11) 
    valuesdisplay=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec");
    title "Figure 1: Time Plot of Average Flight Delay Duration (Hours) Across 29 Airports";
RUN;


/* Spaghetti Plot of Hemoglobin A1c for Each Subject by Group*/
proc sgplot data=airlines_2015;
    series x=time_cts y=Delay_in_hours / group=AID lineattrs=(thickness=1); 
    yaxis label="Flight Delay Duration (Hours)";
    xaxis label="Month" values=(0 to 11) 
    valuesdisplay=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec");
    title "Figure 2: Spaghetti Plot of Flight Delay Duration (Hours) by Airport";
run;

/* Heatmap of Delay Minutes by Month and Airport with Labels */
proc sgplot data=airlines_2015;
    heatmap x='Time.Month'n y=AID / colorresponse=Delay_in_hours colormodel=(blue yellow red);
    xaxis label="Month" values=(1 to 12)
    valuesdisplay=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec");
    yaxis label="Airport Code";
    title "Figure 3: Monthly Heatmap of Average Flight Delays by Airport (in Hours)";
run;


/* Average Delay Minutes by Airport */
proc sgplot data=airlines_2015;
    vbar AID / response=Delay_in_hours stat=mean;
    yaxis label="Flight Delay Duration (Hours)";
    xaxis label="Airport Code";
    title "Average Flight Delay Duration (Hours) by Airport";
run;

/* Reset graphics options to default after the map */
ods graphics / reset;




/* COVARIANCE AND CORRELATION */
proc sort data = airlines_2015;
	by AID;
run; 

/* WIDE FORMAT DATA: COLUMNS FOR EACH TIME */
proc transpose data=airlines_2015 out=airlines_wide prefix=T_;
    by AID;
    id TIME;
    var Delay_in_hours;  
run;

*proc print data = diabetes_wide;
*run;

 
proc corr data =airlines_wide cov;
	title "Covariance and Correlation for All Cohort";
	var T_0 T_1 T_2 T_3 T_4 T_5 T_6 T_7 T_8 T_9 T_10 T_11;
run;

/* Residual Scatterplot Matrix */
/* FIRST OBTAIN RESIDUALS FROM WEIGHT VERSUS DIET MODEL */

proc glm data=airlines_2015 noprint;
	class TIME;
	model Delay_in_hours = carriers cancelled on_time_flights diverted_flights;
	output out=newairlinesdata r=resid;
	title "GLM Model: Hours Delayed as Dependent and All Variables as Independent";
run;
quit;



/* RE-SHAPE THE DATA TO WIDE FORMAT */
proc sort data =newairlinesdata;
	by AID TIME;
run;

proc transpose data=newairlinesdata out=airlineswide prefix=resid;
    by AID;
    id TIME;
    var Delay_in_hours;  
run;

/* SCATTERPLOT MATRIX */
proc sgscatter data=airlineswide;
  title "Scatterplot Matrix for Diabetes";
  matrix resid0 resid1 resid2 resid3 resid4 resid5 resid6 resid7 resid8 resid9 resid10 resid11;
   title 'Residual ScatterPlot Matrix';
run;

/* RESIDUAL CORRELATION MATRIX */
proc corr data =airlineswide;
	title 'RESIDUAL CORRELATION MATRIX';
	var resid0 resid1 resid2 resid3 resid4 resid5 resid6 resid7 resid8 resid9 resid10 resid11;
run;



***********************************************************************************;
*******                      THE ANSWER KEY MODEL                           *******;
***********************************************************************************;


* Open output directory to save results to;
ODS RTF FILE="/home/sasuser.v94/Project/Project_Output.rtf" BODYTITLE STARTPAGE=NO STYLE=HTMLBlue;

TITLE1 "Saturated Means, Unstructured Variance Model --TOTAL ANSWER KEY";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time / SOLUTION DDFM=Satterthwaite;
     REPEATED time / R RCORR TYPE=UN SUBJECT=AID;
     LSMEANS time / DIFF=ALL;
RUN; TITLE1; TITLE2;

***********************************************************************************;
*******                      THE EMPTY MEANS MODEL                          *******;
***********************************************************************************;

TITLE1 "Empty Means, Random Intercept Model";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours =  / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R TYPE=VC SUBJECT=AID;
     ODS OUTPUT CovParms=CovEmpty; * Save for pseudo-R2;
RUN; TITLE1;
 

***********************************************************************************;
*******                    FINDING THE BEST MODEL                           *******;
***********************************************************************************;

TITLE1 "Fixed Linear Time, Random Intercept Model";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R TYPE=VC SUBJECT=AID;
     ODS OUTPUT CovParms=CovFixLin InfoCrit=FitFixLin; * Save for pseudo-R2 and LRT; 
RUN; 
TITLE1 "Calculate pseudo R2 -- variance accounted for by fixed linear time";
%PseudoR2(NCov=2, CovFewer=CovEmpty, CovMore=CovFixLin); TITLE1;
 
TITLE1 "Random Linear Time Model";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT time_cts / G GCORR V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R TYPE=VC SUBJECT=AID;
     ODS OUTPUT CovParms=CovRandLin InfoCrit=FitRandLin; * Save for pseudo-R2 and LRT;
RUN; 
TITLE1 "Calculate LRT -- does random linear time slope improve model fit?";
%FitTest(FitFewer=FitFixLin, FitMore=FitRandLin); TITLE1;

TITLE1 "Test AR1 Residual Correlation in Fixed Linear Time, Random Intercept Model";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G GCORR V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R RCORR TYPE=AR(1) SUBJECT=AID; 
     ODS OUTPUT InfoCrit=FitFixLinAR1; * Save for LRT;
RUN;
TITLE1 "Calculate LRT -- does AR1 residual correlation improve model fit?";
%FitTest(FitFewer=FitFixLin, FitMore=FitFixLinAR1); TITLE1;


TITLE1 "Test ARH(1) Residual Correlation in Fixed Linear Time, Random Intercept Model";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G GCORR V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R RCORR TYPE=ARH(1) SUBJECT=AID;
     ODS OUTPUT InfoCrit=FitFixLinARH1;
RUN;
TITLE1 "Calculate LRT -- does ARH(1) residual correlation improve model fit?";
%FitTest(FitFewer=FitFixLinAR1, FitMore=FitFixLinARH1); TITLE1;

/* Optional: Create summary table of all fit statistics */
DATA AllFitStats;
    SET FitFixLin
    	FitRandLin
    	FitFixLinAR1 
        FitFixLinARH1;
RUN;

PROC PRINT DATA=AllFitStats;
    TITLE "Comparison of Fit Statistics Across All Models";
RUN;



***********************************************************************************;
*******                   THE BEST MODEL WITH COVARIATES                    *******;
***********************************************************************************;

/* Fixed Linear Time, Random Intercept Model with Covariates and AR(1) */
TITLE1 "Fixed Linear Time, Random Intercept Model with Covariates using AR(1) Residual Correlation";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts carriers cancelled 
     on_time_flights diverted_flights / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G GCORR V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R RCORR TYPE=AR(1) SUBJECT=AID;
     ODS OUTPUT InfoCrit=FitFixLinAR1_Cov;
RUN;
TITLE1 "Calculate LRT -- does adding covariates improve model fit?";
%FitTest(FitFewer=FitFixLinAR1, FitMore=FitFixLinAR1_Cov); TITLE1;


/* Fixed Linear Time, Random Intercept Model with Covariates and AR(1) and CrossLevel Interactions */
TITLE1 "Fixed Linear Time, Random Intercept Model with Covariates using AR(1) and Cross Level Interactions";
PROC MIXED DATA=work.airlines_2015 COVTEST NOCLPRINT NAMELEN=100 IC METHOD=REML;
     CLASS AID time;
     MODEL Delay_in_hours = time_cts carriers cancelled 
     on_time_flights diverted_flights carriers*time_cts cancelled*time_cts 
     on_time_flights*time_cts diverted_flights*time_cts / SOLUTION DDFM=Satterthwaite;
     RANDOM INTERCEPT / G GCORR V VCORR TYPE=UN SUBJECT=AID;
     REPEATED time / R RCORR TYPE=AR(1) SUBJECT=AID;
     ODS OUTPUT InfoCrit=FitFixLinAR1_CovCrossLvl;
RUN;
TITLE1 "Calculate LRT -- does adding covariates improve model fit?";
%FitTest(FitFewer=FitFixLinAR1_Cov, FitMore=FitFixLinAR1_CovCrossLvl); TITLE1;


* Close output directory;
ODS RTF CLOSE;


