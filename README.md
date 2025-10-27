# product-automation



# GameBot Automation

A comprehensive automation system for integrating 3rd party gaming products using AI-powered workflows and database automation.

## Overview

The GameBot system consists of two main workflows that automate the product integration process:

### 1. Game Bot - PO Integration ([GameBot/workflow/Game Bot - PO Integration.json](GameBot/workflow/Game%20Bot%20-%20PO%20Integration.json))
- **AI Agent Integration**: Uses OpenAI GPT-4 for intelligent product information gathering
- **Slack Integration**: Interactive forms and notifications via Slack
- **Product Validation**: Checks product and sport name availability
- **Environment Management**: Supports LOCAL, SIT, and PROD environments

### 2. Game Bot - Devs Execution ([GameBot/workflow/Game Bot - Devs Execution.json](GameBot/workflow/Game%20Bot%20-%20Devs%20Execution.json))
- **Automated SQL Script Generation**: Creates deployment scripts using templates
- **Multi-Environment Database Operations**: Executes on multiple database environments
- **File Processing**: Generates Excel reports and compressed archives
- **Progress Tracking**: Real-time Slack notifications for development teams

## Database Components

### Stored Procedures
- [`dbo.GameBot_ReferenceSetting_Init`](GameBot/DB/dbo.GameBot_ReferenceSetting_Init.sql) - Initialize reference settings
- [`dbo.GameBot_ProductSetting_Credit`](GameBot/DB/dbo.GameBot_ProductSetting_Credit.sql) - Credit settings configuration
- [`dbo.GameBot_ProductSetting_Deposit`](GameBot/DB/dbo.GameBot_ProductSetting_Deposit.sql) - Deposit settings configuration
- [`dbo.GameBot_ProductSport_Init`](GameBot/DB/dbo.GameBot_ProductSport_Init.sql) - Product sport initialization
- [`dbo.GameBot_SettingScript_Init`](GameBot/DB/dbo.GameBot_SettingScript_Init.sql) - Script template initialization

### Script Templates
The system includes 16 SQL script templates ([GameBot/DB/Templates/](GameBot/DB/Templates/)) for various operations:
- **Template 01-09**: Communication and licensing scripts
- **Template 10-16**: Product configuration and environment updates

## Key Features

### Intelligent Product Setup
- AI-powered product information extraction
- Automatic validation of existing products/sports
- Dynamic form generation based on product type

### Automated Development Process
1. **Dev_1**: Initialize Products-Sports-Bettype (Events)
2. **Dev_2**: Initialize Product Status/Settings (Credit)
3. **Dev_3**: Initialize Settings DCS/Comm (Deposit)

### Multi-Database Support
- **DBPRO_bodb02**: Main operational database
- **DBCUST-CustDB**: Customer database
- **DBCUST-bodb_licensee**: Licensee database
- **DBGLOB-GlobCustDB**: Global customer database
- **Local environments**: For testing and development

### File Generation
- Excel reports for SportBettypeMatrix, ProductStatusProfile
- Compressed archives with SQL scripts
- Automated file uploads to Slack

## Getting Started

### Prerequisites
- n8n workflow automation platform
- Microsoft SQL Server access
- Slack workspace with bot permissions
- OpenAI API access

### Setup
1. Import the workflow files into your n8n instance
2. Configure database connections in n8n credentials
3. Set up Slack bot credentials
4. Configure OpenAI API credentials

### Usage
1. Trigger the PO Integration workflow via Slack
2. Provide product information through the AI
