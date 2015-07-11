{{
┌─────────────────────────────────────────────────┐
│ Parallax Laser Range Finder                     │
│ Global Constants                                │
│                                                 │
│ Author: Joe Grand                               │                     
│ Copyright (c) 2011 Grand Idea Studio, Inc.      │
│ Web: http://www.grandideastudio.com             │
│ Technical Support: support@parallax.com         │ 
│                                                 │
│ Distributed under a Creative Commons            │
│ Attribution 3.0 United States license           │
│ http://creativecommons.org/licenses/by/3.0/us/  │
└─────────────────────────────────────────────────┘

Program Description:

This object provides global constants used for the
OVM7690-based Parallax Laser Range Finder. 
 
}}


CON
  ' Actual OVM7690 resolution (set in OVM7690_obj setRes object)
  ' Must be <= 640 x 480
  ' Greyscale 
  GRY_X         = 176    ' QCIF                          
  GRY_Y         = 144
  
  ' Color
  CLR_X         = 640    ' VGA  
  CLR_Y         = 480
  CLR_X_CENTER  = CLR_X / 2

  FB_SIZE       = 5120          ' Size of frame buffer (in longs)
  
  FB_CLR_SIZE   = 1280          ' Size of frame buffer (in longs)

  ' Frame buffer resolution
  ' 8 bits/pixel greyscale, only using the Y/luma component
  ' Must be <= to GRY_X/GRY_Y
  FB_GRY_X      = 160                              
  FB_GRY_Y      = 128                                   

  ' 16 bits/pixel YUV422 color, used for actual laser range finding operations
  ' Must be <= to CLR_X/CLR_Y                                                          
  FB_CLR_X      = 320                                   
  FB_CLR_Y      = 16

  ' Region of Interest
'  Y_OFFSET      = 216           ' Offset (accounts for vertical difference between OVM7690 camera module and laser diode) 
  ROI_Y         = (((CLR_Y - FB_CLR_Y) / 2) - 6 ) ' Starting location (we want to capture near the center portion of the frame where the laser diode is pointing, not the top of the frame)          
  ROI_X         = FB_CLR_X
      
  ' Blob detection
  ' Tracking parameters, pixel must be above a minimum brightness value in order to be considered as "valid"
  ' OVM7690 returns Y/luma (brightness) as [0 = darkest, 255 = brightest]
  ' in YUV color space, Y must be [0, 1]
  LOWER_BOUND   = 50 '75            ' Minimum brightness value (Y = 0.3)

  SUM_THRESHOLD = 3             ' Threshold that column sum must be above in order to be considered part of the blob
  MAX_BLOBS     = 6             ' Maximum number of blobs to detect within the frame
  BLOB_MASS_THRESHOLD = 16      ' Minimum blob mass to accept

  ' Locations within blob array
  BLOB_LEFT     = 0             ' X coordinate of left side (beginning) of detected blob
  BLOB_RIGHT    = 1             ' X coordinate of right side (end) of detected blob
  BLOB_MASS     = 2             ' Mass of blob (sum of all valid pixels within the blob)
  BLOB_CENTROID = 3             ' Centroid (center of mass) of blob
                                
  ' Range finding
  LRF_H_CM        = 7.8               ' Distance between centerpoints of camera and laser, fixed based on PCB layout (cm)
  ANGLE_MIN       = 0.030699015       ' Minimum allowable angle (radians) = arctan(h/D) (corresponds to D = 254 cm, anything longer will be too unreliable)

  ' Calibration
  CAL_MIN_DISTANCE      = 20        ' Minimum calibration distance (cm)
  CAL_MAX_DISTANCE      = 70        ' Maximum calibration distance (cm)
  CAL_STEP              = 10        ' Step size (cm)
  CAL_NUM_PER_DISTANCE  = 4         ' Number of measurements per distance

  
PUB PinDefsOnlySoIgnoreThis
  return 0