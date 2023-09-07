
#include "GlobalVars.Inc"
#include "Constants.Inc"
'----------------------------------------------------------------------------------------------------------------
' Function MotSlow: Geschwindigkeits Parameter Langsam 1 - 100%
'----------------------------------------------------------------------------------------------------------------
Function FcMotSlow
	Power Low
    
	Speed InW(i_wSpeedFactorSlow)
    Accel InW(i_wSpeedFactorSlow), InW(i_wSpeedFactorSlow)
    SpeedS (SCA_MAX_SPEEDS * InW(i_wSpeedFactorSlow)) / 100
    AccelS (SCA_MAX_ACCELS * InW(i_wSpeedFactorSlow)) / 100, (SCA_MAX_DECELS * InW(i_wSpeedFactorSlow)) / 100
Fend
'----------------------------------------------------------------------------------------------------------------
' Function MotFast: Geschwindigkeits Parameter Schnell 1 - 100%
'----------------------------------------------------------------------------------------------------------------
Function FcMotFast
	Power High

	Speed InW(i_wSpeedFactorFast)
	Accel InW(i_wSpeedFactorFast), InW(i_wSpeedFactorFast)
    SpeedS (SCA_MAX_SPEEDS * InW(i_wSpeedFactorFast)) / 100
    AccelS (SCA_MAX_ACCELS * InW(i_wSpeedFactorFast)) / 100, (SCA_MAX_DECELS * InW(i_wSpeedFactorFast)) / 100
Fend
'----------------------------------------------------------------------------------------------------------------
' Function CalcBoxes: Berechnen der User spezifischen Boxen, Boxen sollten immer im Programm definiert werden!!!
'----------------------------------------------------------------------------------------------------------------
Function FcCalcBoxes As Boolean
	'Box 1 Beispiel	
    Print "Calc Box 1"
	' Bereich Runtisch 1
 	Box 1, 64.512, 297.150, 193.607, 337.933, -135.5, 3  ' Xmin, Xmax, Ymin, Ymax, Zmin, Zmax
 	 
    Print "Calc Box 2"
	' Bereich Runtisch 2
 	Box 2, 26.861, 222.258, 125.836, 240.962, -124.5, 3  ' Xmin, Xmax, Ymin, Ymax, Zmin, Zmax
 	 

Fend
'----------------------------------------------------------------------------------------------------------------
' Function CalcPalett: 
'----------------------------------------------------------------------------------------------------------------
Function FcCalcTeachPos
	Arch ARCH_GR_EMPTY, 20, 20
	Arch ARCH_GR_FULL, 40, 40
	
	
	Home_Position = Home_Position :U(FIXED_VALUE_U)
	Reject_Position = Reject_Position :U(FIXED_VALUE_U)

	'Puffer Platte 125ul
	Calc_Buffer_Pos1 = Teach_Buffer_Pos1 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_Buffer_Pos8 = Teach_Buffer_Pos8 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_Buffer_Pos89 = Teach_Buffer_Pos89 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)

	'Rundtisch
	Calc_RoundTable_Pos1 = Teach_RoundTable_Pos1 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_RoundTable_Pos8 = Teach_RoundTable_Pos8 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_RoundTable_Pos89 = Teach_RoundTable_Pos89 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)

	'Fehlerbildplatte
	Calc_ErrorPatternPlate_Pos1 = Teach_ErrorPatternPlate_Pos1 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_ErrorPatternPlate_Pos8 = Teach_ErrorPatternPlate_Pos8 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)
	Calc_ErrorPatternPlate_Pos89 = Teach_ErrorPatternPlate_Pos89 -Z(Offset_Z_Position) :U(FIXED_VALUE_U)

	SavePoints "robot1.PTS"
Fend
'----------------------------------------------------------------------------------------------------------------
' Function CalcPalett: 
'----------------------------------------------------------------------------------------------------------------
Function FcCalcPalett As Boolean
	Pallet 1, Calc_Buffer_Pos1, Calc_Buffer_Pos8, Calc_Buffer_Pos89, 8, 12
	Pallet 2, Calc_RoundTable_Pos1, Calc_RoundTable_Pos8, Calc_RoundTable_Pos89, 8, 12
	Pallet 3, Calc_ErrorPatternPlate_Pos1, Calc_ErrorPatternPlate_Pos8, Calc_ErrorPatternPlate_Pos89, 8, 12
Fend
