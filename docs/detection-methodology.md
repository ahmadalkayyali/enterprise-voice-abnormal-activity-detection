# Detection Methodology

## Purpose

This document explains the detection methodology used in this repository to identify abnormal caller activity in enterprise voice and contact center environments.

The methodology is designed to help telecom, voice, and contact center engineering teams detect suspicious inbound calling patterns using historical call-detail data.

## Detection Scope

The detection logic focuses on five abnormal activity patterns:

1. Repeat ANI activity
2. ANI hitting multiple DNIS numbers
3. High short-call volume
4. After-hours suspicious activity
5. DNIS burst activity

## Data Requirements

The methodology requires historical call-detail records with the following fields:

- Call timestamp
- ANI or calling party number
- DNIS or called party number
- Call duration
- Call disposition
- Unique call identifier

The exact table and column names may vary depending on the voice platform or contact center reporting database.

## 1. Repeat ANI Activity

Repeat ANI detection identifies callers that generate unusually high call volume during a selected reporting period.

This can help identify callers, bots, misconfigured dialers, or automated systems repeatedly contacting enterprise numbers.

## 2. ANI Hitting Multiple DNIS Numbers

This model identifies a single caller reaching multiple destination numbers.

A caller hitting many DNIS numbers may indicate scanning, probing, toll-free abuse, routing abuse, or automated dialing behavior.

## 3. High Short-Call Volume

Short-call detection identifies callers that generate many calls below a defined duration threshold.

High short-call volume may indicate robocall behavior, call pumping, failed automation, abandoned automated dialing, or attempts to test number reachability.

## 4. After-Hours Suspicious Activity

After-hours detection identifies callers generating significant traffic outside normal business hours.

This is useful because abnormal traffic may be easier to detect when legitimate call volume is normally lower.

## 5. DNIS Burst Detection

DNIS burst detection identifies destination numbers receiving sudden high call volume during a short time window.

This can help detect targeted abuse against toll-free numbers, public-facing business numbers, or specific contact center queues.

## Tuning Thresholds

The SQL script includes configurable thresholds for:

- Reporting start and end time
- Short-call duration
- Repeat ANI call count
- Number of DNIS values reached by one ANI
- After-hours time window
- DNIS burst call count

Each organization should adjust these thresholds based on normal call volume, business hours, queue design, and carrier exposure.

## Operational Review

The output of this detection logic should be reviewed by telecom, security, or contact center engineering personnel before action is taken.

Possible follow-up actions may include:

- Reviewing call recordings or call metadata
- Comparing against carrier records
- Checking affected toll-free numbers
- Validating whether the ANI belongs to a legitimate customer, partner, vendor, or automated system
- Opening a carrier investigation
- Creating internal monitoring dashboards
- Adding temporary blocks or rate-limiting controls where appropriate

## Privacy and Safety

This repository intentionally does not include production phone numbers, customer information, company-specific routing data, server names, database names, screenshots, internal tickets, or proprietary reporting output.

Any organization adapting this methodology should sanitize all sensitive data before sharing results publicly.

## Disclaimer

This methodology is intended as a detection and reporting aid. It is not a complete fraud prevention, security, or carrier enforcement system.
