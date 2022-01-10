*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           Collections
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.RobotLogListener
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${zip_file}       ${OUTPUT_DIR}${/}pdf_archive.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set Directory
    Get Programmer name from the vault
    ${username}=    Get the user name
    Open the robot order website
    Download Orders Files
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10 times    2s    Preview the order
        Wait Until Keyword Succeeds    10 times    2s    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take Screenshot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close the Browser
    Log    Hey ${username}, all your orders have been processed. Thanks!

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download Orders Files
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get Orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the order
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit order
    Mute Run On Failure    Page Should Contain Element
    Click Button    order
    Page Should Contain Element    receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_number}=    Get Text    xpath://*[@id="receipt"]/p[1]
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_folder}${/}${order_number}.pdf
    [Return]    ${pdf_folder}${/}${order_number}.pdf

Take Screenshot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview
    Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Screenshot    robot-preview    ${img_folder}${/}${order_number}.png
    [Return]    ${img_folder}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    ${pdf}
    Log    ${screenshot}
    Open Pdf    ${pdf}
    Add Watermark Image To pdf    ${screenshot}    ${pdf}

Go to order another robot
    Click Button    order-another

Set Directory
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Get the user name
    Add heading    I am here to take Robocorp order
    Add text input    username    label=Your name, Please
    ${result}=    Run dialog
    [Return]    ${result.username}

Get Programmer name from the vault
    ${secret}=    Get Secret    mysecrets
    Log    ${secret}[programmer_name] is the developer of this program    console=yes

Close the Browser
    Close Browser
