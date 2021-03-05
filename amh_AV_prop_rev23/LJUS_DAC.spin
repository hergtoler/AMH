CON
  clockMillions = 104_000_000
  clockThousands = 104_000

VAR
  long sampleRate
  long edgeRate

PUB LJUSStart(buffer_address, newRate, whichCog) 

  'sampleRate := (clkfreq / ((newRate <# (clkfreq / constant(clockMillions / clockThousands))) #> 1)) 
  'sampleRate := (clkfreq / newRate) 
  'edgeRate := (sampleRate / 16)
  sampleRate := (clkfreq / 22050) 
  edgeRate := (sampleRate / 64)

  leftSampleAddress := buffer_address
  rightSampleAddress := buffer_address + 4

  coginit(whichCog, @initialI2S, @edgeRate)


DAT

                        org 0

' //////////////////////Initialization for I2S/////////////////////////////////////////////////////////////////////////////////////////
initialI2S
                        mov i2sLrckML, #128
                        mov i2sBckML, #32  'HLT - set the pins
                        mov i2sDataML, #64  'HLT - set the pins

                        rdlong  tempReg4,        par                             ' Wait until next sample output period.
                        'rdlong  timeCounter2,     par                            ' Setup timing.  
                        mov  timeCounter2,     tempReg4                            ' Setup timing.  
                        add     timeCounter2,     cnt  

                        'or dira, i2sDataML                                      'HLT - make this an output
                        'or dira, i2sBckML                                       'HLT - make this an output
                        'or dira, i2sLrckML                                      'HLT - make this an output
                        
                        mov leftChActive, #0

                        or dira, #224

                        mov bshift, #1
                        rol bshift, #31

outerLoopI2S
                        mov bitpos, #32
                        
                        or outa, i2sLrckML
                        rdlong currentSample, leftSampleAddress

innerLoopI2SLeft
                        'set data here
                        test currentSample, bshift wz
                        muxnz outa, i2sDataML                              'Assert serial output bit

                        or outa, i2sBckML  'clock goes high
                        waitcnt timeCounter2,    tempReg4
                        andn outa, i2sBckML

                        ror bshift, #1
                        djnz bitpos, #innerLoopI2SLeft

doRightChannel
                        mov bitpos, #32
                        
                        andn outa, i2sLrckML
                        rdlong currentSample, rightSampleAddress

innerLoopI2SRight
                        'set data here
                        test currentSample, bshift wz
                        muxnz outa, i2sDataML                              'Assert serial output bit

                        or outa, i2sBckML  'clock goes high
                        waitcnt timeCounter2,    tempReg4
                        andn outa, i2sBckML

                        ror bshift, #1
                        djnz bitpos, #innerLoopI2SRight
                        jmp #outerLoopI2S

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Data
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 


' //////////////////////Configuration Settings/////////////////////////////////////////////////////////////////////////////////


' //////////////////////Addresses//////////////////////////////////////////////////////////////////////////////////////////////

leftSampleAddress       long    0
rightSampleAddress      long    0

' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////


timeCounter2             res     1

tempReg4                res     1

'
bitpos        res       1                       'Which bit we are on
bshift        res       1                       'Bit mask
bittemp       res       1                       'Temp for bit test

i2sLrckML     res       1
i2sBckML      res       1
i2sDataML     res       1

leftChActive  res       1
leftSample    res       1
rightSample   res       1
currentSample res       1

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        fit     496

                        