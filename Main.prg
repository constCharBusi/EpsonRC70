'*****************************************************************************************************************
'*****  Projektname:        Hamilton                                                  					 	 *****
'*****  Dateiname:          Main.prg                                                                         *****
'*****  Beschreibung:       Vorlage  			                                                     		 *****
'*****  Eigentum von:       Zublerhanling AG 						                                         *****
'*****  Stand:              24.03.2023                                                                       *****
'*****  Version: 1.0:		Erstellt, SimBur, 24.03.2023													 *****
'*****************************************************************************************************************
#include "Constants.Inc"
#include "GlobalVars.Inc"

'----------------------------------------------------------------------------------------------------------------
' Function main: Start Ablauf Programm
'----------------------------------------------------------------------------------------------------------------
Function main
  	Print "Start Safety Gate Watcher"
	' Starte Safety Gate Watchter
	Xqt FcSgWatcher, NoPause
	
	Xqt FcReadFieldbusData
	
	Xqt Scheduler
	
	' Stop Roboter when executed on abort
	Trap Abort, Xqt FcStopRobot
Fend

Function Scheduler
	
SCHEDULER_MAIN:

	Integer iActJob
	
	OnErr GoTo ERR_SCHEDULER

	Do While True
		' Ausführung wurde gestoppt
		If Sw(i_xStopJobTasks) Then
			xGndDone = False
			Wait Sw(i_xStopJobTasks) = Off
		EndIf

		' Grundstellung
		If Not xGndDone Then
			Wait Sw(i_xStartInit) = On
			Call Executor(INIT)
			Wait Sw(i_xStartInit) = Off
		EndIf
	
		' Job ausführen
		If InW(i_wJobNr) > WAIT_FOR_JOB Then
			' Status Busy schreiben
			On q_xRoboterBusy
			
			' Vakuum ist noch ein wegen Abbruch von Job
			If Oport(q_VacOn) = On Then
				Call Executor(EMPTY_GR)
			EndIf
				
			' Daten prüfen
			fcCheckJobData()

			'Entscheidung welchen Job gestartet werden soll
			iActJob = InW(i_wJobNr)
			Call Executor(iActJob)
			
			'Abschluss Job
			Wait InW(i_wJobNr) = WAIT_FOR_JOB Or Sw(i_xStartInit) = On
			OutW q_JobHandshake, JOB_IDLE
				OutW q_wActJobNr, WAIT_FOR_JOB
			Off q_xRoboterBusy
		EndIf
	Loop

ERR_SCHEDULER:
	FcErrHandling()
	EResume SCHEDULER_MAIN
Fend

Function Executor(CurrentJob As Integer)
	Print "Aktueller Job ", CurrentJob
	Select CurrentJob
	Case INIT '
       	xGndDone = FcInitRobot
       	
	Case PICK_PLACE_JOB
		OutW q_wActJobNr, CurrentJob
		If FcJob1() Then
			OutW q_wActJobNr, DONE_JOB
		Else
			OutW q_wActJobNr, ERROR_JOB
		EndIf
	       	
	Case EMPTY_GR
		Jump Reject_Position /L LimZ SCA_Z_Limit
		Wait Sw(i_xRejectBoxRdyForPart) = On
		Off q_VacOn
		On q_BlowOn, GRP_BlowTimeOn
	Send
Fend
'----------------------------------------------------------------------------------------------------------------
' Function CheckJobData: Daten
'----------------------------------------------------------------------------------------------------------------
Function fcCheckJobData() As Boolean
	'Überprüfe Job Nummer Gültig
	If InW(i_wJobNr) = 0 Or InW(i_wJobNr) > JOB_MAX_NUMBER Then
		Error ER_INV_JOB_NR
		Exit Function
	EndIf
		
	'Überprüfe Pallet Nummer und Pos Numm auf Gültigkeit
	If InW(i_wPickPal) > PAL_MAX_NUMBER Or InW(i_wPlacePal) > PAL_MAX_NUMBER Then
		Error ER_INV_PAL_NR
		Exit Function
	EndIf
		
	' Position auf Palette
	If InW(i_wPickPos) > POS_MAX_NUMBER Or InW(i_wPlacePos) > POS_MAX_NUMBER Then
		Error ER_INV_POS_NR
		Exit Function
	EndIf
	
	fcCheckJobData = True
Fend
'----------------------------------------------------------------------------------------------------------------
' Function SgWatcher: Schutzverdeck Funktion
'----------------------------------------------------------------------------------------------------------------
Function FcSgWatcher
OnErr GoTo ERR_SGW
	Do
        ' Waiting for E-Stop or Door open
        Wait EStopOn = On Or SafetyOn = On

        If EStopOn = On Then
            Exit Function
        EndIf

        ' Waiting for door close
        Wait SafetyOn = Off Or EStopOn = On
        If EStopOn = On Then
            Exit Function
        EndIf

		Print RecoverPos
		Print RealPos
		Print "Wait 1.5s until Continue"
		Wait 1.5
       Cont

 	Loop

ERR_SGW:
	Print "sgwatchquit"
    FcErrHandling()
    Quit All
Fend
'----------------------------------------------------------------------------------------------------------------
' Function ErrHandling: Funktion für Fehler Handhabung.
'----------------------------------------------------------------------------------------------------------------
Function FcErrHandling As Boolean
	Off q_xRoboterReadyToMove, Forced
	' Set error bit
	On q_xRoboterError, Forced
	' Set actual Error Code
	OutW q_wErrCode, Err(Ert), Forced
	' Print error
	Print "Error Number", Err(Ert)
	Print "Error-Function", Erf$(Ert)
	Print "Error-Line", Erl(Ert)
	Print "Error-Message", ErrMsg$(Err(Ert))
	Wait 0.5
	' Reset Fault
	Wait Sw(i_xReset) = On
	Wait 0.5
	Off q_xRoboterGndDone, Forced
	Off q_xRoboterError, Forced
	OutW q_wErrCode, 0, Forced
	
	Wait Sw(i_xReset) = Off
	
	'User defined erros inside 8000-9000
	If Err(Ert) >= 8000 And Err(Ert) < 9000 Then
		FcErrHandling = True
 	EndIf
Fend
'----------------------------------------------------------------------------------------------------------------
' Function StopRobot: Roboter Shutdown Routine.
'----------------------------------------------------------------------------------------------------------------
Function FcStopRobot
	' Reset Robo Status
	Off q_xRoboterGndDone, Forced
	Off q_xRoboterBusy, Forced
	Off q_xRoboterError, Forced
	Off q_xRoboterReadyToMove, Forced
	OutW q_wErrCode, 0, Forced

	' Reset Robo Job Status
	OutW q_wActJobNr, WAIT_FOR_JOB, Forced

	Motor Off
	Quit All
Fend
'----------------------------------------------------------------------------------------------------------------
' Function GrpClose: Gripper Close
'----------------------------------------------------------------------------------------------------------------
Function FcGrpClose As Boolean
	On q_VacOn
	Wait Sw(i_VacOk) Or Sw(i_xSimProduct), GRP_VacOnFault
	If TW Then
		FcGrpClose = False
	Else
		FcGrpClose = True
	EndIf
Fend
'----------------------------------------------------------------------------------------------------------------
' Function GrpOpen: Gripper Open
'----------------------------------------------------------------------------------------------------------------
Function FcGrpOpen As Boolean
	Off q_VacOn
	On q_BlowOn, GRP_BlowTimeOn
	Wait Sw(i_VacOk) = Off, GRP_VacOnFault
	If TW Then
		FcGrpOpen = False
	Else
		FcGrpOpen = True
	EndIf
Fend
'----------------------------------------------------------------------------------------------------------------
' Function
'----------------------------------------------------------------------------------------------------------------
Function fcCheckVacOk As Boolean
	fcCheckVacOk = Sw(i_VacOk) Or Sw(i_xSimProduct)
Fend
'----------------------------------------------------------------------------------------------------------------
' Function ExchangeJob: Austausch Schlechtteil auf Rundtisch mit Gutteil aus Puffer
'----------------------------------------------------------------------------------------------------------------
Function FcJob1
	 OnErr GoTo ERR_BEEN
	 OutW q_JobHandshake, JOB_STARTED
	'Schnelle Geschwindigkeit	
	FcMotFast()
	
'----------------------------------------------------------------------------------------------------------------
' Fahre zur Entnahme Position Schlechtteil auf Rundtisch
'----------------------------------------------------------------------------------------------------------------	
	'Schreibe Fahrbefehl Daten der Rundtisch Position
	nPal = InW(i_wPickPal)
	nInd = InW(i_wPickPos)

	Jump Pallet(nPal, nInd) /L LimZ SCA_Z_Limit C(ARCH_GR_EMPTY)

	' Schliesse Greifer
	If FcGrpClose() Then
		OutW q_JobHandshake, PICK_SUCCESS
	Else
		Go Here :Z(SCA_Z_Limit)
		OutW q_JobHandshake, PICK_FAIL
		Exit Function
	EndIf
	
	' Fahrbefehl Z nach oben
    Go Here +Z(Z_TILL_OFFSET)
 	
 	'Vakuum immer noch vorhanden?
 	If fcCheckVacOk() Then
		OutW q_JobHandshake, MOVE_Z_SUCCESS
 	Else
 		Go Here :Z(SCA_Z_Limit)
 		OutW q_JobHandshake, MOVE_Z_PART_STUCK
 		Exit Function
 	EndIf
 	
'----------------------------------------------------------------------------------------------------------------
' Entscheidung Abgabe Produkt in Fehlerbildplatte / Ausschusskiste
'----------------------------------------------------------------------------------------------------------------	
 	If InW(i_wPlacePal) > 0 Then
 		'Schreibe Fahrbefehl Daten für Fehlerbildplatte
		nPal = InW(i_wPlacePal)
		nInd = InW(i_wPlacePos)

		' Fahre zur Fehlerbildplatte Position mit Z-Offset
		If InW(i_wPlacePal) = PAL_ERROR_PATTERN_PLATE Then
			Jump Pallet(nPal, nInd) /R +Z(Z_PLACE_OFFSET + Z_TILL_OFFSET) C(ARCH_GR_FULL) LimZ SCA_Z_Limit
		Else
			Jump Pallet(nPal, nInd) /L +Z(Z_PLACE_OFFSET + Z_TILL_OFFSET) C(ARCH_GR_FULL) LimZ SCA_Z_Limit
		EndIf

	  	If fcCheckVacOk() Then
			OutW q_JobHandshake, MOVE_XY_SUCCESS
 		Else
 			Go Here :Z(SCA_Z_Limit)
 			OutW q_JobHandshake, MOVE_XY_PART_LOSS
 			Exit Function
	 	EndIf
	 	
		' Geschwindigkeit Langsam
		FcMotSlow()
		
		' Fahrbefehl Position auf Fehlerbildplatte
		Go Pallet(nPal, nInd) +Z(Z_PLACE_OFFSET)
 	Else
		' Fahrbefehl Auschusskiste
		Jump Reject_Position /L C(ARCH_GR_FULL)
		
	  	If fcCheckVacOk() Then
			OutW q_JobHandshake, MOVE_XY_SUCCESS
 		Else
 			Go Here :Z(SCA_Z_Limit)
 			OutW q_JobHandshake, MOVE_XY_PART_LOSS
 			Exit Function
	 	EndIf
		
		' Warte Ausschusskiste Bereit für Schlechtteil
		Wait Sw(i_xRejectBoxRdyForPart) = On
 	EndIf
 	
 	' Greifer öffnen
	If FcGrpOpen() Then
		OutW q_JobHandshake, PLACE_SUCCESS
 	Else
 		Go Here :Z(SCA_Z_Limit)
 		OutW q_JobHandshake, PLACE_FAIL
 		Exit Function
	EndIf

	FcMotFast()
	
	Go Here :Z(SCA_Z_Limit)
 	FcJob1 = True
 	Exit Function
 	
ERR_BEEN:
    If FcErrHandling() Then
    	  Exit Function
    EndIf
Fend
