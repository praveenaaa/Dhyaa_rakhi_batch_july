' - - - - - - - - - - Variable Declaration - - - - - - - - - - 
Dim strFileName, sTestCaseName, iResultSheetRowCounter, sTimeStamp, sRunStatus, sConfigFile
Dim sStartupConfigSheet, sTCFlowSheetPath, sBatchSheetPath, sTestCaseFolder, sBatchRunPath, sErrScreenshotPath, sQTPResultsPath, sQTPResultsPathOrig, sTestSummaryLogPath
Dim sExecute, sDefaultSyncTime, sIntermediateRunRequired, sQTPVisible, sQTPRunMode
Dim sSendEmail, sEmailTo, sEmailCc, sEmailBcc, sEmailSubject, sEmailBody
Dim iTotalTestCasesToBeExecuted, iTestCaseExecuting, iTotalPassed, iTotalFailed, iTotalOthers
Dim sFrameworkFolder

iResultSheetRowCounter = 2 : iTestCaseExecuting = 1 : iTotalPassed = 0 : iTotalFailed = 0 : iTotalOthers = 0

sFrameworkFolder = "C:\QTP-Hybrid-Framework\"
sTestCaseFolder = sFrameworkFolder & "TestCases\"
sQTPResultsPathOrig = sFrameworkFolder & "Results\DetailedQTPResults\"
sBatchRunPath = sFrameworkFolder & "Results\SummarizedResults\"
sBatchSheetPath = sFrameworkFolder & "Batch\Batch.xls"

sEmailTo = "<<provide a valid email id>>"
sEmailCc = "" : sEmailBcc = "" : sEmailBody = ""
'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


'==================== Flow of Driver Script code ====================

'Find DateTime Stamp
fnTimeStamp()

'Create Result Excel Sheet
fnCreateResultExcelSheet()

'Execute the Test Cases
fnExecuteTestCases()

'Send email report after all the TCs have been run
'fnSendEmail()




'==================== Function Definitions ====================

Function fnTimeStamp()

		sDay = Day(Now)
		sMonth = Month(Now)
		sYear = Year(Now)
		sHour = Hour(Now)
		sMin = Minute(Now)
		sSec = Second(Now)
		sTimeStamp = sDay & "." & sMonth & "." & sYear & "_" & sHour & "." & sMin & "." & sSec

End Function
'- - - - - - - - - - - - 

Function fnCreateResultExcelSheet()

        Set objExcel = CreateObject("Excel.Application")
		objExcel.DisplayAlerts = False
		Set objWorkbook = objExcel.Workbooks.Add()
		
		objExcel.Columns("A:A").ColumnWidth = 41
		objExcel.Columns("B:B").ColumnWidth = 10
		objExcel.Columns("C:C").ColumnWidth = 40
		objExcel.Columns("D:D").ColumnWidth = 12
		objExcel.Columns("E:E").ColumnWidth = 12
		objExcel.Columns("F:F").ColumnWidth = 12
		objExcel.Columns("G:G").ColumnWidth = 12
		
		'Set Calibry Font for the excel sheet
		Set objRange = objExcel.Range("A1:L100")
		objRange.Font.Size = 10
		objRange.Font.Name = "Calibri"
		objRange.Font.Bold = FALSE
		Set objRange = Nothing
		
		Set objRange = objExcel.Range("A1:H1")
		objRange.Font.Size = 10
		objRange.Font.Bold = TRUE
		Set objRange = Nothing
		
		'Set Header
		objExcel.Cells(1, 1).Value = "TestCase_Name"
		objExcel.Cells(1, 2).Value = "Status"
		objExcel.Cells(1, 3).Value = "Test Results Path"
		objExcel.Cells(1, 4).Value = "Execution Date"
		objExcel.Cells(1, 5).Value = "Start Time"
		objExcel.Cells(1, 6).Value = "End Time"
		objExcel.Cells(1, 7).Value = "Duration"
		
		'Save and close excel
		objWorkbook.SaveAs(sBatchRunPath & sTimeStamp & ".xls")
		objExcel.Quit
		Set objWorkbook = Nothing
		Set objExcel = Nothing

End Function
'- - - - - - - - - - - - 

Function fnExecuteTestCases()

		'Open QTP if not already open
		Set qtpApp = CreateObject("QuickTest.Application")

		If qtpApp.launched <> True Then
			qtpApp.Launch
		End If

		qtpApp.Visible = sQTPVisible

		'Set QuickTest run options
		qtpApp.Options.Run.ImageCaptureForTestResults = "OnError"
		qtpApp.Options.Run.RunMode = "Normal"
		qtpApp.Options.Run.ViewResults = true

		'Read Data from Batch Sheet
		Set xl_Batch = CreateObject("Excel.Application")
		Set wb_Batch = xl_Batch.WorkBooks.Open(sBatchSheetPath)

		'...................................................
		'Loop through all the Rows
		For iR = 3 to 1000

			If xl_Batch.Cells(iR, 1).Value = "Yes" Then	
					
				'Run the TC and Update Results
				'+ + + + + + + + + + + + + + + + + + +
				iTestCaseExecuting = iTestCaseExecuting + 1

				'Get TC Name
				sTestCaseName = xl_Batch.Cells(iR, 2).Value
				
				'Get QTP script path
				strScriptPath = sTestCaseFolder & sTestCaseName
				
				'Open the Test Case in Read-Only mode
				qtpApp.Open strScriptPath, True
				WScript.Sleep 2000
		
				'set run settings for the test
				Set qtpTest = qtpApp.Test
		
				'Instruct QuickTest to perform next step when error occurs
				qtpTest.Settings.Run.OnError = "NextStep"
		
				'Create the Run Results Options object
				Set qtpResult = CreateObject("QuickTest.RunResultsOptions")
		
				'Set the results location
				sQTPResultsPath = sQTPResultsPathOrig & sTestCaseName  & "_" & sTimeStamp
				qtpResult.ResultsLocation = sQTPResultsPath
				
				'Find start date time
				exeDate = Date
				exeStartTime = Time()
		
				'Run the test
				WScript.Sleep 2000
				qtpTest.Run qtpResult
				
				'Find end date time
				exeEndTime = Time()
				exeDuration = exeEndTime - exeStartTime
				
				'Find Run Status
				sRunStatus = qtpTest.LastRunResults.Status
				Select Case sRunStatus
					Case "Passed"   		iTotalPassed = iTotalPassed + 1
					Case "Failed"			   iTotalFailed = iTotalFailed + 1
					Case Else				 	iTotalOthers = iTotalOthers + 1
				End Select
		
				'Save the result
				fnSaveTestCaseResult iResultSheetRowCounter, sTestCaseName, sRunStatus, sQTPResultsPath, exeDate, exeStartTime, exeEndTime, exeDuration	
				'+ + + + + + + + + + + + + + + + + + +

			ElseIf xl_Batch.Cells(iR, 1).Value = "No" Then
					'Get TC Name
					sTestCaseName = xl_Batch.Cells(iR, 2).Value
					'Save the result
					fnSaveTestCaseResult iResultSheetRowCounter, sTestCaseName, "NA", "None", "", "", "", ""							
			ElseIf xl_Batch.Cells(iR, 1).Value = "" Then
					Exit For
			End If

		Next
		'...................................................


		'Delete references
		xl_Batch.Quit()
		Set wb_Batch = Nothing
		Set xl_Batch = Nothing

End Function
'- - - - - - - - - - - - 

Function fnSendEmail()

		'Create an object of type Outlook 
		Set objOutlook = CreateObject("Outlook.Application") 
		Set myMail = objOutlook.CreateItem(0)
		
		'Set the email properties 
		myMail.To = sEmailTo
		myMail.CC = sEmailCc
		myMail.BCC = sEmailBcc
		myMail.Subject = sEmailSubject & " - " & Date
		If sEmailBody = "" Then
				sMessage = "Total Test Cases Executed - " & iTestCaseExecuting - 1
				sMessage = sMessage & VbCrLf & "Passed - " & iTotalPassed
				sMessage = sMessage & VbCrLf & "Failed - " & iTotalFailed
				sMessage = sMessage & VbCrLf & "Others  - " & iTotalOthers
				myMail.Body = sMessage
		ElseIf sEmailBody <> "" Then
				myMail.Body = sEmailBody
		End If
		
		'Send the mail 
		myMail.Send 
		WScript.Sleep 2000
		  
		'Clear object reference 
		Set myMail = Nothing
		Set objOutlook = Nothing

End Function
'- - - - - - - - - - - - 

Function fnSaveTestCaseResult(iResultSheetRowCounter, TCName, Status, TestResultPath, ExecutionDate, StartTime, EndTime, Duration)
	
		'Open Result Sheet and update the result
		Set objExcel = CreateObject("Excel.Application")
		Set objWorkbook = objExcel.WorkBooks.Open(sBatchRunPath & sTimeStamp & ".xls")
		objExcel.DisplayAlerts = False
		
		'Set the results
		objExcel.Cells(iResultSheetRowCounter, 1).Value = TCName
		objExcel.Cells(iResultSheetRowCounter, 2).Font.Bold = TRUE
		objExcel.Cells(iResultSheetRowCounter, 2).Value = Status
		'Color status
		Select Case Status
			Case "NA"
				objExcel.Cells(iResultSheetRowCounter, 2).Font.Color = RGB(139, 137, 137)
			Case "Passed"
				objExcel.Cells(iResultSheetRowCounter, 2).Font.Color = RGB(0, 100, 0)
			Case "Failed"
				objExcel.Cells(iResultSheetRowCounter, 2).Font.Color = RGB(245, 0, 0)
			Case Else
				objExcel.Cells(iResultSheetRowCounter, 2).Font.Color = RGB(255, 255, 0)
		End Select
		
		objExcel.Cells(iResultSheetRowCounter, 3).Value = TestResultPath
		objExcel.Cells(iResultSheetRowCounter, 4).Value = ExecutionDate
		objExcel.Cells(iResultSheetRowCounter, 5).Value = StartTime
		objExcel.Cells(iResultSheetRowCounter, 6).Value = EndTime
		objExcel.Cells(iResultSheetRowCounter, 7).Value = Duration
		
		iResultSheetRowCounter = iResultSheetRowCounter + 1
	
		'Save and close excel
		objWorkbook.SaveAs(sBatchRunPath & sTimeStamp & ".xls")
		objExcel.Quit
		Set objWorkbook = Nothing
		Set objExcel = Nothing

End Function
'- - - - - - - - - - - - 
