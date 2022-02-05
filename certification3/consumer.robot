*** Settings ***
Documentation     Inhuman Insurance, Inc. Artificial Intelligence System robot.
...               Consumes traffic data work items.
Resource          shared.robot

*** Tasks ***
Consume traffic data work items
    For Each Input Work Item    Process traffic data

*** Keywords ***
Process traffic data
    ${payload}=    Get Work Item Payload
    ${traffic_data}=    Set Variable    ${payload}[${WORK_ITEM_NAME}]
    ${is_data_valid}=    Validate traffic data    ${traffic_data}
    IF    ${is_data_valid}
        Log    IS valid = ${is_data_valid}
        Post traffic data to sales system    ${traffic_data}
    ELSE
        Handle invalid traffic data    ${traffic_data}
    END

Validate traffic data
    [Arguments]    ${traffic_data}
    ${country}=    Get value from JSON    ${traffic_data}    $.country
    Log    ${country}
    ${is_valid}=    Evaluate    len("${country}") == 3
    [Return]    ${is_valid}

Post traffic data to sales system
    [Arguments]    ${traffic_data}
    ${status}    ${return}    Run Keyword And Ignore Error
    ...    POST
    ...    https://robocorp.com/inhuman-insurance-inc/sales-system-api
    ...    json=${traffic_data}
    IF    "${status}" == "PASS"
        Handle traffic API OK response
    ELSE
        Handle traffic API error response    ${return}    ${traffic_data}
    END

Handle invalid traffic data
    [Arguments]    ${traffic_data}
    ${message}=    Set Variable    Invalid traffic data: ${traffic_data}
    Log    ${message}    WARN
    Release Input Work Item
    ...    state=FAILED
    ...    exception_type=BUSINESS
    ...    code=INVALID_TRAFFIC_DATA
    ...    message=${message}

Handle traffic API OK response
    Release Input Work Item    DONE

Handle traffic API error response
    [Arguments]    ${return}    ${traffic_data}
    Log
    ...    Traffic posting failure: ${traffic_data} ${return}
    ...    ERROR
    Release Input Work Item
    ...    state=FAILED
    ...    exception_type=APPLICATION
    ...    code=TRAFFIC_DATA_POST_FAILED
    ...    message=${return}
