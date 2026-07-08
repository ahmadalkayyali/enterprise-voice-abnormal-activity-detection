# Enterprise Voice Abnormal Activity Detection

## Overview

This repository provides a SQL-based methodology for detecting abnormal inbound caller activity in enterprise voice and contact center environments.

The purpose of this project is to help voice, telecom, and contact center engineering teams identify suspicious call patterns before they create operational impact, carrier cost exposure, queue disruption, or service-quality degradation.

The detection logic focuses on common abnormal activity indicators such as repeat ANI behavior, callers hitting multiple DNIS numbers, high short-call volume, after-hours traffic, and DNIS burst activity.

## Why This Project Matters

Large enterprise contact centers often support hundreds or thousands of public-facing numbers, toll-free numbers, queues, and routing paths. In that type of environment, abnormal caller behavior can be difficult to identify through standard call reports alone.

This project demonstrates how historical call-detail data can be converted into a repeatable monitoring methodology for voice infrastructure risk detection.

The approach may be useful for:

- Telecom fraud investigation
- Toll-free abuse detection
- Contact center resiliency monitoring
- Voice infrastructure risk reporting
- Security and operations analytics
- Historical call-pattern investigation
- Early detection of abnormal inbound traffic

## Detection Models

The SQL logic includes five primary detection models:

### 1. Repeat ANI Activity

Identifies callers that generate unusually high call volume within the selected reporting period.

### 2. ANI Hitting Multiple DNIS Numbers

Flags callers that reach multiple destination numbers, which may indicate probing, scanning, misrouted automated traffic, or abuse patterns.

### 3. High Short-Call Volume

Identifies callers that generate many short-duration calls. This may indicate failed automation, robocall behavior, call pumping, toll-free abuse, or misconfigured dialing systems.

### 4. After-Hours Suspicious Activity

Highlights callers generating significant traffic outside normal operating hours.

### 5. DNIS Burst Detection

Detects destination numbers receiving sudden call bursts during a short time window.

## Platform

This project was designed for Microsoft SQL Server and Cisco UCCE / Contact Center Enterprise-style historical call-detail data.

The logic can be adapted to other voice and contact center platforms that store similar fields, including:

- Call timestamp
- ANI / calling number
- DNIS / dialed number
- Call duration
- Call disposition
- Unique call identifier

## Repository Structure

```text
enterprise-voice-abnormal-activity-detection/
│
├── README.md
├── LICENSE
├── sql/
│   └── abnormal_caller_activity_detection.sql
└── docs/
    └── detection-methodology.md
