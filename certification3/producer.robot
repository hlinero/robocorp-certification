*** Settings ***
Documentation     Inhuman Insurance, Inc. Artificial Intelligence System robot.
...               Produces traffic data work items.
Library           RPA.Tables
Library           Collections
Resource          shared.robot

*** Variables ***
${TRAFFIC_JSON_FILE_PATH}=    ${OUTPUT_DIR}${/}traffic.json
# JSON keys
${COUNTRY_COLUMN}=    SpatialDim
${RATE_COLUMN}=    NumericValue
${GENDER_COLUMN}=    Dim1
${YEAR_COLUMN}=    TimeDim

*** Tasks ***
Produce traffic data work items
    Download traffic data
    ${traffic_data}=    Load traffic data as table
    ${filtered_data}=    Filter and sort traffic data    ${traffic_data}
    ${filtered_data}=    Get latest data by country    ${filtered_data}
    ${payloads}=    Create work items payloads    ${filtered_data}
    Save work item payloads    ${payloads}

*** Keywords ***
Download traffic data
    Download
    ...    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
    ...    ${TRAFFIC_JSON_FILE_PATH}
    ...    overwrite=True

Load traffic data as table
    ${json}=    Load JSON from file    ${TRAFFIC_JSON_FILE_PATH}
    ${table}=    Create Table    ${json}[value]
    [Return]    ${table}

Filter and sort traffic data
    [Arguments]    ${table}
    ${max_valid_rate}=    Set Variable    ${5.0}
    ${both_genders}=    Set Variable    BTSX
    Filter Table By Column    ${table}    ${RATE_COLUMN}    <    ${max_valid_rate}
    Filter Table By Column    ${table}    ${GENDER_COLUMN}    ==    ${both_genders}
    Sort Table By Column    ${table}    ${YEAR_COLUMN}    False
    [Return]    ${table}

Get latest data by country
    [Arguments]    ${table}
    ${country_key}=    Set Variable    SpatialDim
    ${table}=    Group Table By Column    ${table}    ${country_key}
    ${latest_data_by_country}=    Create List
    FOR    ${group}    IN    @{table}
        ${first_row}=    Pop Table Row    ${group}
        Append To List    ${latest_data_by_country}    ${first_row}
    END
    [Return]    ${latest_data_by_country}

Create work items payloads
    [Arguments]    ${table}
    ${payloads}=    Create List
    FOR    ${row}    IN    @{table}
        ${payload}=
        ...    Create Dictionary
        ...    country=${row}[${COUNTRY_COLUMN}]
        ...    year=${row}[${YEAR_COLUMN}]
        ...    rate=${row}[${RATE_COLUMN}]
        Append To List    ${payloads}    ${payload}
    END
    [Return]    ${payloads}

Save work item payloads
    [Arguments]    ${payloads}
    FOR    ${payload}    IN    @{payloads}
        Create Output Work Item
        Set Work Item Variable    ${WORK_ITEM_NAME}    ${payload}
        Save Work Item
    END
