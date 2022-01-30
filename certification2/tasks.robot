*** Settings ***
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Robocorp.Vault
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Documentation     Certification 2 task

*** Variables ***
${RECEIPTS_FOLDER_PATH}    ${OUTPUT_DIR}${/}receipts

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Add icon    Warning
    Add heading    Ready to begin process?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF    $result.submit == "Yes"
        Begin process
    ELSE
        Goodbye dialog
    END

*** Keywords ***
Goodbye dialog
    Add icon    Success
    Add heading    Goodbye. Call me when ready
    Run dialog    title=Success

Begin process
    Open the browser
    Log in using vault credentials
    Move to the orders page
    Fill the orders form
    Zip the folder with receipts
    [Teardown]    Log out and close browser

Open the browser
    Open Available Browser    https://robotsparebinindustries.com/

Log in using vault credentials
    ${secret}=    Get Secret    credentials
    Input Text    username    ${secret}[username]
    Input Text    password    ${secret}[password]
    Submit Form

Move to the orders page
    Click Link    Order your robot!
    Dismiss annoying dialog

Dismiss annoying dialog
    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the orders form
    Download the orders file
    Submit orders from file

Zip the folder with receipts
    Archive Folder With Zip    ${RECEIPTS_FOLDER_PATH}    ${OUTPUT_DIR}${/}receipts.zip    recursive=True

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Submit orders from file
    ${table}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{table}
        Populate Order Form    ${order}
        Preview order
        Submit until success
        Save Receipts    ${order}[Order number]
        Initialize new order
        Dismiss annoying dialog
    END

Populate Order Form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview order
    Click Button    preview

Submit until success
    FOR    ${i}    IN RANGE    999999
        Submit order
        ${res}=    Does Page Contain Button    order-another
        Exit For Loop If    ${res}
    END

Initialize new order
    Click Button    order-another

Submit order
    Click Button    order

Save Receipts
    [Arguments]    ${order_number}
    ${folder_to_order_info}=    Set Variable    ${RECEIPTS_FOLDER_PATH}${/}order - ${order_number}
    ${receipt_path}=    Set Variable    ${folder_to_order_info}${/}receipt.pdf
    ${robot_img_path}=    Set Variable    ${folder_to_order_info}${/}image.png
    Create folder to save receipt    ${folder_to_order_info}
    Save receipt details    ${receipt_path}
    Save robot picture    ${robot_img_path}
    Embed robot picture to receipt    ${receipt_path}    ${robot_img_path}

Get order number
    ${order_number}=    Get Element Attribute    xpath:/html/body/div/div/div[1]/div/div[1]/div/div/p[1]    innerHTML
    [Return]    ${order_number}

Create folder to save receipt
    [Arguments]    ${path}
    Create Directory    ${path}    parents=True

Save receipt details
    [Arguments]    ${path}
    ${recipt_info_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${recipt_info_html}    ${path}

Save robot picture
    [Arguments]    ${path}
    Screenshot    id:robot-preview-image    ${path}

Embed robot picture to receipt
    [Arguments]    ${receipt_path}    ${robot_img_path}
    ${files}=    Create List    ${robot_img_path}
    Add Files To Pdf    ${files}    ${receipt_path}    append=True

Log out and close browser
    Click Button    Log out
    Close Browser
