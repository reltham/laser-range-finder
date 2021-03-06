{{
┌──────────────────────────────────────────────────────────┐
│ OmniVision OVM7690 CameraCube Module                     │
│ Interface Object                                         │
│                                                          │
│ Author: Joe Grand                                        │                     
│ Copyright (c) 2011 Grand Idea Studio, Inc.               │
│ Web: http://www.grandideastudio.com                      │
│ Technical Support: support@parallax.com                  │ 
│                                                          │
│ Distributed under a Creative Commons                     │
│ Attribution 3.0 United States license                    │
│ http://creativecommons.org/licenses/by/3.0/us/           │
│                                                          │
│ Note: Due to confidentiality concerns, OmniVision does   │
│ not allow explicit references or detailed explanations   │
│ of camera configuration registers. Explanations of       │
│ group settings are allowed and provided to give the user │
│ an overview of camera operation. To obtain full OVM7690  │
│ product specifications, a non-disclosure agreement (NDA) │
│ must be executed with OmniVision Technologies, Inc.      │
│ (http://www.ovt.com)                                     │
└──────────────────────────────────────────────────────────┘

Program Description:

This object provides the low-level communication interface
for the Omnivision OVM7690 CMOS CameraCube module.

}}


CON
  OVM7690_Addr  = %0100_0010     ' SCCB/I2C address: corresponds to write address $42 and read address $43

  CamXVCLKFreq  = 24_000_000     ' XVCLK frequency determines SCCB (Serial Camera Control Bus) speed, OVM7690 data sheet section 1.2.9   

  ' I/O pin connections to the Propeller
  ' Others defined in OVM7690_fg
  CamPWDN         = 8  
  CamSDA          = 9
  CamSCL          = 10
  CamXVCLK        = 14

  ' Frame grab type
  FrameFull             = 0     ' single frame, full (160 x 128, 8 bits/pixel grayscale)
  FrameROI              = 1     ' single frame, roi (320 x 16, 8 bits/pixel grayscale) w/ laser enabled 
  FrameROIProcessed     = 2     ' processed frame, roi (320 x 16, 8 bits/pixel grayscale)
                                ' one with laser off, one with laser on, background subtraction for better detection of laser spot
                                ' details of pixel subtraction: http://homepages.inf.ed.ac.uk/rbf/HIPR2/pixsub.htm                          
  ' Results display type
  ResultASCII    = 0
  ResultBinary   = 1
                     
  
VAR
  long captureType              ' 0 = single frame, 1 = two frame processed
  long fb[g#FB_SIZE]            ' Frame buffer (in longs)
  long Done                     ' Non-zero when frame grab is complete (do not move the location of this variable)
  
  long blob_lb                  ' Minimum brightness value for blob detection/thresholding
  long blob_ub                  ' Maximum brightness value for blob detection/thresholding
  
  
OBJ
  g             : "LRF_con"                             ' Laser Range Finder global constants
  fg            : "OVM7690_fg"                          ' OVM7690 CMOS camera, frame grabber cog full 
  fg_roi        : "OVM7690_fg_roi"                      ' OVM7690 CMOS camera, frame grabber cog roi 
  i2c           : "pasm_i2c_driver_Lite"                ' I2C protocol for OVM7690 communication via the SCCS bus (Dave Hein, http://obex.parallax.com/objects/611/)
  freq          : "Synth"                               ' Frequency synthesizer (included w/ Parallax Propeller Tool)

  ' _Lite versions have been modified for specific LRF functionality and/or to remove unused code

  
PUB start : err
  dira[CamPWDN] := 1            ' Output
  dira[CamXVCLK] := 1           ' Output

  sleep                         ' Set OVM7690 to power down/standby mode until we're ready to begin communications

  freq.Synth("A", CamXVCLK, CamXVCLKFreq)   ' Configure Counter A to synthesize input clock (XVCLK) for OVM7690
                                            
  i2c.Initialize(CamSCL)        ' Setup I2C cog

  wakeUp                        ' Wake up camera from sleep mode      
  err := init                   ' Set camera system control registers

  
PUB getFrame(type) : addr       ' Launch the frame grabber cog (and return a pointer to the frame buffer
  Done := 0                     ' Clear Done flag
  
  if (type == FrameFull)
    addr := fg.Start(@fb)       ' Start the OVM7690 CMOS camera frame grabber cog, single frame full
  elseif (type == FrameROI)
    captureType := 0
    addr := fg_roi.Start(@captureType, blob_lb, blob_ub)     ' Start the OVM7690 CMOS camera frame grabber cog, single frame roi
  elseif (type == FrameROIProcessed)
    captureType := 1  
    addr := fg_roi.Start(@captureType, blob_lb, blob_ub)     ' Start the OVM7690 CMOS camera frame grabber cog, processed frame roi
  
  repeat while Done == 0        ' Wait until entire frame is successfully grabbed

  
PUB getID(dataPtr1, dataPtr2) : ackbit      ' Read manufacturer and product IDs
  ackbit := 0
  ackbit += readByte($1c, dataPtr1 + 1)
  ackbit += readByte($1d, dataPtr1)
  ackbit += readByte($0a, dataPtr2 + 1)
  ackbit += readByte($0b, dataPtr2)


PUB setBlobThresholdBounds(lb, ub)  ' Minimum/maximum brightness values for blob detection/thresholding    
  blob_lb := lb
  blob_ub := ub


PUB setRes(resx, resy) : ackbit     ' Set camera resolution
  ' set upper bounds for maximum resolution provided by the OVM7690
  if (resx > 640)
    resx := 640

  if (resy > 480)
    resx := 480  

  ackbit := 0
  ackbit += writeByte($cc, resx.BYTE[1])  
  ackbit += writeByte($cd, resx.BYTE[0])
  ackbit += writeByte($ce, resy.BYTE[1])  
  ackbit += writeByte($cf, resy.BYTE[0])
  

PUB calibrate : ackbit | val       ' Calibrate camera for current environment
  ' Disable AWB (Automatic White Balance), AGC (Auto Gain Control) & Exposure automatic control and reduce exposure/EV level
  ackbit := 0
  ackbit += readByte($13, @val) 
  val |= %0000_0111
  ackbit += writeByte($13, val)

  ' Let camera calibrate to current ambient conditions
  repeat 10                     ' ...for 10 seconds
    waitcnt(clkfreq + cnt)

  ackbit += readByte($13, @val) 
  val &= %1111_1000
  ackbit += writeByte($13, val)

  ackbit += readByte($80, @val) 
  val &= %1111_1101
  ackbit += writeByte($80, val)

  ackbit += writeByte($d3, $20)
  ackbit += writeByte($d2, $04)
  ackbit += writeByte($dc, $09)
  

PUB readByte(addrReg, dataPtr) : ackbit
  ackbit := i2c.ReadPage(CamSCL, OVM7690_Addr, addrReg, dataPtr, 1)

  
PUB writeByte(addrReg, data) : ackbit | startTime 
  if i2c.WritePage(CamSCL, OVM7690_Addr, addrReg, @data, 1)
    return true ' an error occured during the write
    
  startTime := cnt ' prepare to check for a timeout
  repeat while i2c.WriteWait(CamSCL, OVM7690_Addr, addrReg)
     if cnt - startTime > clkfreq / 10
       return true ' waited more than a 1/10 second for the write to finish
    
  return false ' write completed successfully


PUB init : ackbit | ptr         ' Set system control registers per OVTATool2009 OVM7690 Setting V2.2 (C:\Program Files\OVTATool2009\OVWorking\CFG\OV7690R1B_A28_TPilot.set)
  writeByte($12, $80)           ' System soft reset  
  waitcnt(clkfreq / 10 + cnt)   ' Delay 100mS
  ackbit := 0
  
  ptr := @OVM7690_Init_Start    ' Get pointer to start of data table (containing register locations and data)
  repeat constant((OVM7690_Init_End - OVM7690_Init_Start) / 2)  ' Get each register/data pair...
    ackbit += writeByte(BYTE[ptr], BYTE[ptr][1])                ' ...and them write to the OVM7690
    ptr += 2 
 

PRI wakeUp
  outa[CamPWDN] := 0 
  waitcnt(clkfreq / 50 + cnt)   ' Delay 20mS to allow OVM7690 to come out of sleep, per data sheet figure 1-5

    
PRI sleep
  outa[CamPWDN] := 1 


DAT
OVM7690_Init_Start
  ';;===General Control===;;  
  byte $0c, $d6 
  byte $81, $ff 
  byte $13, $f7 
  byte $11, $02
  
  byte $48, $42 
  byte $41, $43 
  byte $4c, $73 
  byte $39, $80 
  byte $1e, $b1 
  byte $2a, $30 
  byte $2b, $0d 
 
  byte $1b, $19 
  byte $29, $50 
  byte $68, $b4 
  byte $27, $80 
  
  ';;===Format: YUV422===;;
  byte $12, $00
  byte $82, $03 
  byte $d0, $48
  byte $80, $7f
  byte $3e, $30 
  byte $22, $00

  ';;====Resolution====;;
  byte $c8, $02
  byte $c9, $80 
  byte $ca, $01 
  byte $cb, $e0
  byte $cc, $02  
  byte $cd, $80 
  byte $ce, $01  
  byte $cf, $e0

  byte $16, $03
  byte $17, $69 
  byte $19, $0c 
  byte $18, $a4 
  byte $1a, $f6 

  ';;====Automatic Gain Control(AGC)/Automatic Exposure Control (AEC)====;; 
  byte $14, $20 
  byte $24, $78
  byte $25, $68 
  byte $26, $b3 

  ' Set from OV7690R1B_A287690_pll_banding_control_2
  ' Values below are for 30fps/24MHz, but seem fine for slower PCLK 
  byte $50, $9b             
  byte $51, $81              
  byte $20, $00  
  byte $21, $23                                  
  byte $0f, $01         
  byte $10, $f9 

  ';;====Automatic White Balance(AWB)====;;    
  byte $8c, $5d
  byte $8d, $11
  byte $8e, $12
  byte $8f, $11
  byte $90, $50
  byte $91, $22
  byte $92, $d1
  byte $93, $a7
  byte $94, $23
  byte $95, $3b
  byte $96, $ff
  byte $97, $00
  byte $98, $4a
  byte $99, $46
  byte $9a, $3d
  byte $9b, $3a
  byte $9c, $f0
  byte $9d, $f0
  byte $9e, $f0
  byte $9f, $ff
  byte $a0, $56
  byte $a1, $55
  byte $a2, $13

  ';;===Lens Correction==;;
  byte $85, $90
  byte $86, $00
  byte $87, $00
  byte $88, $10
  byte $89, $30
  byte $8a, $29
  byte $8b, $26

  ';;====Color Matrix====;;
  byte $bb, $80
  byte $bc, $62
  byte $bd, $1e
  byte $be, $26
  byte $bf, $7b
  byte $c0, $ac
  byte $c1, $1e
  
  ';;===Edge + Denoise====;;
  byte $b7, $05
  byte $b8, $09 
  byte $b9, $00 
  byte $ba, $18 

  ';;===UV Adjust====;;
  byte $5a, $4a
  byte $5b, $9f
  byte $5c, $48
  byte $5d, $32

  ';;====Gamma====;;
  byte $a3, $0b
  byte $a4, $15
  byte $a5, $2a
  byte $a6, $51
  byte $a7, $63
  byte $a8, $74
  byte $a9, $83
  byte $aa, $91
  byte $ab, $9e
  byte $ac, $aa
  byte $ad, $be
  byte $ae, $ce
  byte $af, $e5
  byte $b0, $f3
  byte $b1, $fb
  byte $b2, $06
OVM7690_Init_End
