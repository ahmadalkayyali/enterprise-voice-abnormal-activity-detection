/*
================================================================================
 Project: Enterprise Voice Abnormal Caller Activity Detection
 Platform: Microsoft SQL Server
 Target: Cisco UCCE / Enterprise Contact Center historical call-detail data

 Purpose:
   Detect abnormal inbound caller activity using historical call-detail records.

 Detection Models:
   1. Top repeat ANI callers
   2. ANI hitting multiple DNIS numbers
   3. High short-call volume
   4. After-hours suspicious activity
   5. DNIS burst detection

 Notes:
   - Replace table and column names if your environment uses different naming.
   - Validate against a reporting copy or HDS/AW database before production use.
   - Do not publish real ANI/DNIS values from production systems.
================================================================================
*/

DECLARE @StartDateTime DATETIME = '2026-01-01 00:00:00';
DECLARE @EndDateTime   DATETIME = '2026-01-31 23:59:59';

DECLARE @ShortCallSeconds INT = 10;
DECLARE @RepeatANIThreshold INT = 50;
DECLARE @MultiDNISThreshold INT = 5;
DECLARE @AfterHoursStart INT = 18; -- 6 PM
DECLARE @AfterHoursEnd   INT = 7;  -- 7 AM
DECLARE @DNISBurstThreshold INT = 100;

;WITH BaseCalls AS
(
    SELECT
        -- Adjust these fields if your schema uses different names
        t.DateTime AS CallDateTime,
        CAST(t.DateTime AS DATE) AS CallDate,
        DATEPART(HOUR, t.DateTime) AS CallHour,

        NULLIF(LTRIM(RTRIM(t.ANI)), '') AS ANI,
        NULLIF(LTRIM(RTRIM(t.DNIS)), '') AS DNIS,

        ISNULL(t.Duration, 0) AS DurationSeconds,
        t.CallDisposition,

        -- Use the most reliable unique call key available in your environment
        CONCAT(
            ISNULL(CAST(t.RouterCallKeyDay AS VARCHAR(20)), '0'),
            '-',
            ISNULL(CAST(t.RouterCallKey AS VARCHAR(20)), '0')
        ) AS UniqueCallKey
    FROM dbo.Termination_Call_Detail t
    WHERE
        t.DateTime >= @StartDateTime
        AND t.DateTime <= @EndDateTime
        AND NULLIF(LTRIM(RTRIM(t.ANI)), '') IS NOT NULL
        AND NULLIF(LTRIM(RTRIM(t.DNIS)), '') IS NOT NULL

        -- Optional: focus on external North American callers only
        -- AND t.ANI LIKE '+1%'

        -- Optional: exclude internal extensions if needed
        -- AND LEN(t.ANI) > 6
),

/* ---------------------------------------------------------------------------
   1. Top Repeat ANI Activity
--------------------------------------------------------------------------- */
RepeatANI AS
(
    SELECT
        ANI,
        COUNT(*) AS TotalCalls,
        COUNT(DISTINCT DNIS) AS UniqueDNISCount,
        MIN(CallDateTime) AS FirstSeen,
        MAX(CallDateTime) AS LastSeen,
        AVG(DurationSeconds) AS AvgDurationSeconds,
        SUM(CASE WHEN DurationSeconds <= @ShortCallSeconds THEN 1 ELSE 0 END) AS ShortCallCount
    FROM BaseCalls
    GROUP BY ANI
    HAVING COUNT(*) >= @RepeatANIThreshold
),

/* ---------------------------------------------------------------------------
   2. ANI Hitting Multiple DNIS Numbers
--------------------------------------------------------------------------- */
ANI_Multiple_DNIS AS
(
    SELECT
        ANI,
        COUNT(*) AS TotalCalls,
        COUNT(DISTINCT DNIS) AS UniqueDNISCount,
        MIN(CallDateTime) AS FirstSeen,
        MAX(CallDateTime) AS LastSeen
    FROM BaseCalls
    GROUP BY ANI
    HAVING COUNT(DISTINCT DNIS) >= @MultiDNISThreshold
),

/* ---------------------------------------------------------------------------
   3. High Short-Call Volume
--------------------------------------------------------------------------- */
HighShortCallVolume AS
(
    SELECT
        ANI,
        COUNT(*) AS TotalCalls,
        SUM(CASE WHEN DurationSeconds <= @ShortCallSeconds THEN 1 ELSE 0 END) AS ShortCallCount,
        CAST(
            100.0 * SUM(CASE WHEN DurationSeconds <= @ShortCallSeconds THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0)
            AS DECIMAL(5,2)
        ) AS ShortCallPercentage,
        MIN(CallDateTime) AS FirstSeen,
        MAX(CallDateTime) AS LastSeen
    FROM BaseCalls
    GROUP BY ANI
    HAVING
        SUM(CASE WHEN DurationSeconds <= @ShortCallSeconds THEN 1 ELSE 0 END) >= 25
),

/* ---------------------------------------------------------------------------
   4. After-Hours Suspicious Activity
--------------------------------------------------------------------------- */
AfterHoursActivity AS
(
    SELECT
        ANI,
        COUNT(*) AS AfterHoursCalls,
        COUNT(DISTINCT DNIS) AS UniqueDNISCount,
        MIN(CallDateTime) AS FirstSeen,
        MAX(CallDateTime) AS LastSeen
    FROM BaseCalls
    WHERE
        CallHour >= @AfterHoursStart
        OR CallHour < @AfterHoursEnd
    GROUP BY ANI
    HAVING COUNT(*) >= 20
),

/* ---------------------------------------------------------------------------
   5. DNIS Burst Detection
--------------------------------------------------------------------------- */
DNISBurst AS
(
    SELECT
        CallDate,
        CallHour,
        DNIS,
        COUNT(*) AS CallsReceived,
        COUNT(DISTINCT ANI) AS UniqueANICount
    FROM BaseCalls
    GROUP BY
        CallDate,
        CallHour,
        DNIS
    HAVING COUNT(*) >= @DNISBurstThreshold
)

/* ---------------------------------------------------------------------------
   Final Unified Output
--------------------------------------------------------------------------- */

SELECT
    'Repeat ANI Activity' AS DetectionType,
    ANI,
    NULL AS DNIS,
    TotalCalls AS EventCount,
    UniqueDNISCount,
    ShortCallCount,
    AvgDurationSeconds,
    FirstSeen,
    LastSeen,
    'Caller generated high repeat call volume during the selected period.' AS DetectionReason
FROM RepeatANI

UNION ALL

SELECT
    'ANI Hitting Multiple DNIS' AS DetectionType,
    ANI,
    NULL AS DNIS,
    TotalCalls AS EventCount,
    UniqueDNISCount,
    NULL AS ShortCallCount,
    NULL AS AvgDurationSeconds,
    FirstSeen,
    LastSeen,
    'Caller reached multiple destination numbers, which may indicate probing or abnormal routing activity.' AS DetectionReason
FROM ANI_Multiple_DNIS

UNION ALL

SELECT
    'High Short-Call Volume' AS DetectionType,
    ANI,
    NULL AS DNIS,
    TotalCalls AS EventCount,
    NULL AS UniqueDNISCount,
    ShortCallCount,
    NULL AS AvgDurationSeconds,
    FirstSeen,
    LastSeen,
    'Caller generated a high number of short-duration calls.' AS DetectionReason
FROM HighShortCallVolume

UNION ALL

SELECT
    'After-Hours Suspicious Activity' AS DetectionType,
    ANI,
    NULL AS DNIS,
    AfterHoursCalls AS EventCount,
    UniqueDNISCount,
    NULL AS ShortCallCount,
    NULL AS AvgDurationSeconds,
    FirstSeen,
    LastSeen,
    'Caller generated abnormal activity outside normal business hours.' AS DetectionReason
FROM AfterHoursActivity

UNION ALL

SELECT
    'DNIS Burst Detection' AS DetectionType,
    NULL AS ANI,
    DNIS,
    CallsReceived AS EventCount,
    UniqueANICount AS UniqueDNISCount,
    NULL AS ShortCallCount,
    NULL AS AvgDurationSeconds,
    CAST(CallDate AS DATETIME) AS FirstSeen,
    DATEADD(HOUR, CallHour, CAST(CallDate AS DATETIME)) AS LastSeen,
    'Destination number received a burst of calls in a short time window.' AS DetectionReason
FROM DNISBurst

ORDER BY
    DetectionType,
    EventCount DESC;
