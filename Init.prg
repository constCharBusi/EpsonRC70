#include "GlobalVars.Inc"
#include "Constants.Inc"
'----------------------------------------------------------------------------------------------------------------
' Function MotInit: Initalisieren der Motoren
'----------------------------------------------------------------------------------------------------------------
Function FcMotInit
	OnErr GoTo MOT_INIT_ERR
	
	'Das ist der einzige Ort wo die Motoren angestellt werden!
	If Motor = Off Then
		Motor On
	EndIf
	
	'Schalte auf langsame Geschwindigkeit und Power Low Modus
	FcMotSlow()
	
	' Roboter Busy
	On q_xRoboterBusy
	
	'Fahrbefehl Z-Achse in Sichere Position
	Print "Go Safe Position with Z-Axis"
	Go Here :Z(SCA_Z_Limit)

	'Vakuum eingeschaltet?
	If Oport(q_VacOn) = On Then
		Jump Reject_Position /L LimZ SCA_Z_Limit
		Wait Sw(i_xRejectBoxRdyForPart) = On
		Off q_VacOn
		On q_BlowOn, GRP_BlowTimeOn
	EndIf
	
	'Fahrbefehl zur Homeposition auslösen
    Jump Home_Position /L LimZ SCA_Z_Limit
	
	'Roboter Busy OFF
	Off q_xRoboterBusy
	
	'Motor Initialisierung abgeschlossen
	FcMotInit = True
	Exit Function

MOT_INIT_ERR:
	FcMotSlow()
	FcErrHandling()
	Motor Off
	FcMotInit = False
Fend

'----------------------------------------------------------------------------------------------------------------
' Function InitRobot: Initialisierung Roboter
'----------------------------------------------------------------------------------------------------------------
Function FcInitRobot As Boolean
	
	Print "Initialsiierung gestartet"

	'Grundstellung zurücksetzen
	xGndDone = False

	'Initialisiere alle User spezifische Ausgänge
	Off q_xRoboterBusy
	Off q_xRoboterError
	Off q_xRoboterGndDone
	Off q_xRoboterReadyToMove
	
	OutW q_wActJobNr, 0, Forced
	OutW q_JobHandshake, 0, Forced
	OutW q_wErrCode, 0, Forced
	
	'Berechne Teach Positionen	
	FcCalcTeachPos()
	
	'Berechne Paletten
	FcCalcPalett()
	
	'Berechne Boxen	
	FcCalcBoxes()
	
	'Warte auf Bereich Frei
	Wait Sw(i_xAreaFree)
	
	'Initialisiere Motoren und fahre Home Position an
	If FcMotInit = False Then
		Exit Function
	EndIf
	
	'Initialisierung Abgeschlossen
	On q_xRoboterGndDone
	On q_xRoboterReadyToMove
	FcInitRobot = True
Fend
