# +
*** Settings ***
Documentation     Order robots from robotsparebinindustires.
Library           RPA.HTTP
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           OperatingSystem
Library           RPA.Robocorp.Vault

*** Variables ***
${output_folder}    ${CURDIR}${/}RobotOutput

*** Tasks ***
Download And Begin
    ${URL} =    Get Secret    URL
    Log    ${URL}
    Open Available Browser    ${URL}[orderURL]
    Sleep    5s
    Download    ${URL}[csvURL]    overwrite=True
#Foreach row in csv file complete order, take screenshot and Create pdf

Complete Order
    ${roboPrefix}=    Get The Robot Prefix
    #
    ${listOrders}=    Get List of Orders from Csv
    FOR    ${order}    IN    @{listOrders}
        FOR    ${i}    IN RANGE    9999999
            Fill Order Details    ${order}
            Click Button    Order
            ${elementExist}=    Does Page Contain Element    //div[@class="alert alert-success"]
            Exit For Loop If    ${elementExist}
        END
        Take Robot Screenshot    id:robot-preview-image
        ${reciept_html}=    Extract HTML Content    id:receipt
        Create reciept PDF    ${reciept_html}    ${order}[Order number]    ${roboPrefix}
        Click Button    Order another robot
    END
#Create ZIP from pdfs generated

Create ZipFile And Release Resources
    Create Zip File
    [Teardown]    Close the browser

*** Keywords ***
Directory Cleanup
    Create Directory    ${output_folder}
    Empty Directory    ${output_folder}

Get List of Orders from Csv
    ${table}=    Read Table From Csv    orders.csv    header=True
    [Return]    ${table}

Fill Order Details
    [Arguments]    ${order}
    Reload Page
    Click Element If Visible    //button[@class="btn btn-dark"]
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Via XPath    //input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Via XPath    //input[@placeholder="Shipping address"]    ${order}[Address]
    Click Button    Preview

Take Robot Screenshot
    [Arguments]    ${imgSelector}
    Wait Until Element Is Visible    ${imgSelector}
    Sleep    1sec
    Capture Element Screenshot    ${imgSelector}    ${output_folder}${/}robotImage.png

Input via XPath
    [Arguments]    ${xpath}    ${value}
    ${result}=    Execute Javascript    document.evaluate('${xpath}',document.body,null,9,null).singleNodeValue.value='${value}';
    [Return]    ${result}

Extract HTML Content
    [Arguments]    ${selector}
    Wait Until Element Is Visible    ${selector}
    ${html_content}=    Get Element Attribute    ${selector}    outerHTML
    [Return]    ${html_content}

Create reciept PDF
    [Arguments]    ${reciept_html}    ${orderNumber}    ${roboPrefix}
    Html To Pdf    ${reciept_html}    ${output_folder}${/}${roboPrefix}${orderNumber}.pdf
    ${recieptPdf}=    Open Pdf    ${output_folder}${/}${roboPrefix}${orderNumber}.pdf
    ${files}=    Create List
    ...    ${output_folder}${/}RoboImage.png
    Add Files To PDF    ${files}    ${output_folder}${/}${roboPrefix}${orderNumber}.pdf    ${True}
    Close Pdf    ${recieptPdf}

Create Zip File
    Archive Folder With ZIP    ${output_folder}    OrderZip.zip    recursive=True    include=*.pdf

Get The Robot Prefix
    Add heading    Order Helper
    Add text input    prefix    label=Please provide a name prefix for your robots.    placeholder=Give some input here
    ${result}=    Run dialog
    [Return]    ${result.prefix}

Close the browser
    Close Browser
