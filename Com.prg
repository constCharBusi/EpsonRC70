'----------------------------------------------------------------------------------------------------------------
' Function ReadFieldbusData: 
'----------------------------------------------------------------------------------------------------------------
Function FcReadFieldbusData
	Boolean xStartInitOld
	Do
		' Adjust Z Position
		' Einlesen des Real Offset
		Offset_Z_Position = InReal(46)
		
		' Überprüfe auf Änderung Offst
		If Offset_Z_Position <> Offset_Z_PositionTemp Then
            Print "Update Positions"
            Offset_Z_PositionTemp = Offset_Z_Position
       		FcCalcTeachPos()
       		FcCalcPalett()
		EndIf
		
		If Sw(i_xStartInit) = On And Not xStartInitOld Then
			xGndDone = False
		EndIf
		xStartInitOld = Sw(i_xStartInit)
	Loop
Fend
