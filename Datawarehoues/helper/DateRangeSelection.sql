/****                    MIT 3.0 License                           ****/
/**** e: Martin.job8@gmail.com t:Mallegrissimo 2020/01/23          ****/
/**** Generate Date Range to filter date table in Power BI        *****/
/**** Use [Date] column to join [Date] column in target Date table ****/
/**** Filter selection label [Date Range] order by [Seq] column    ****/
;
WITH dateRange as (
	SELECT 1 as Seq, 'Today' as [Date Range], 0 as MinBand, 0 as MaxBand, 'DAY' as Period
	UNION ALL 
	SELECT 2 as Seq, 'Yesterday' as [Date Range], -1 as MinBand, -1 as MaxBand, 'DAY' as Period
	UNION ALL
	SELECT 3 as Seq, 'Last 7 Days' as [Date Range], -7 as MinBand, -1 as MaxBand, 'DAY' as Period
	UNION ALL
	SELECT 4 as Seq, 'Last 8 Days' as [Date Range], -8 as MinBand, -1 as MaxBand, 'DAY' as Period
	UNION ALL
	SELECT 5 as Seq, 'Next 7 Days' as [Date Range], 1 as MinBand, 7 as MaxBand, 'DAY' as Period
	UNION ALL
	SELECT 6 as Seq, 'Last Month' as [Date Range], -1 as MinBand, -1 as MaxBand, 'MONTH' as Period
)
, calc_Month_DateRange as (
	SELECT  Seq, [Date Range], Period ,MinBand, MaxBand, DATEADD(DAY,1, EoMONTH(DATEADD(MONTH, MinBand -1,GETDATE()))) MinDate, EoMONTH(DATEADD(MONTH, MaxBand,GETDATE())) as MaxDate
		FROM dateRange
		WHERE Period  ='MONTH'
)
, calc_Day_DateRange as (
	SELECT  Seq, [Date Range], Period ,MinBand, MaxBand, DATEADD(DAY, MinBand, CAST(GETDATE() as DATE)) MinDate, DATEADD(DAY, MaxBand, CAST(GETDATE() as DATE)) as MaxDate
		FROM dateRange
		WHERE Period  ='DAY'
)
, calc_DateRanges as (
	SELECT * FROM calc_Month_DateRange
	UNION ALL
	SELECT * FROM calc_Day_DateRange
)
, calc_DateRanges2 as (
	SELECT *
	, DATEDIFF(DAY, case when MinBand<0 then MinDate else CAST(GETDATE() as date) end,case when MinBand<0 then CAST(GETDATE() as date) else MinDate end ) * SIGN(MinBand)   MinDaysDiff
	, DATEDIFF(DAY, case when MaxBand<0 then MaxDate else CAST(GETDATE() as date) end,case when MaxBand<0 then CAST(GETDATE() as date) else MaxDate end ) * SIGN(MaxBand)   MaxDaysDiff
	FROM calc_DateRanges
)
,cte_Dates(Seq,  [Date Range], MinDate, MaxDate, MinDaysDiff, MaxDaysDiff,Period, Date, nth) 
AS (
    SELECT Seq, [Date Range], MinDate, MaxDate,MinDaysDiff,MaxDaysDiff,Period,
        DATEADD(day, MinDaysDiff, CAST(GETDATE() AS Date))   tDate,
        MinDaysDiff 
	FROM calc_DateRanges2 
	--	WHERE cast(GETDATE() as date) = 
    UNION ALL
    SELECT    Seq, [Date Range],  MinDate, MaxDate,MinDaysDiff,MaxDaysDiff,Period,
        DATEADD(day, Nth + 1, CAST(GETDATE() AS Date))   tDate, 
        Nth + 1
    FROM    
        cte_Dates
	WHERE Nth < MaxDaysDiff 
)
SELECT 
    Seq,  [Date Range], MinDate, MaxDate, Date,Period, Nth
FROM 
    cte_Dates
--order by 1,2,5
