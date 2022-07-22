import std/times

import jsony

{.experimental: "overloadableEnums".}

const dateFormat = "yyyy-MM-dd HH:mm:ss"

type
  TermuxFailed* = object of CatchableError
    ## Thrown when a termux proc fails.
    ## Contains code that it failed with
    code*: int

  BatteryHealth* = enum
    ## Different status for battery health
    Cold               
    Dead               
    Good               
    Overheat           
    OverVoltage        
    Unknown            
    UnspecifiedFailure 


  Plugged* = enum
    ## Different ways the battery can be plugged
    Unplugged
    AC       
    USB         
    Wireless  
    Other     

  BatteryStatus* = object
    ## The status of the battery
    health*: BatteryHealth
    plugged*: Plugged
    percentage*: int
    temperature*: float
    current*: int

  CallType* = enum
    Blocked   
    Incoming  
    Missed    
    Outgoing  
    Rejected 
    Voicemail
    Unknown  
    
  CallLog* = object
    name*: string
    phone_number*: string
    kind*: CallType
    date*: DateTime
    duration*: string
    sim_id*: string

  JpegOutSize* = object
    width*: int
    height*: int

  ExposureMode* = enum
    ModeOff
    ModeOn
    ModeOnAlwaysFlash
    ModeOnAutoFlash
    ModeOnAutoFlashRedeye
    ModeOnExternalFlash
    Other 

  CameraInfo* = object
    id*: string
    facing*: string
    jpeg_output_sizes*: seq[JpegOutSize]
    focal_lengths: seq[float]
    auto_exposure_modes: seq[ExposureMode]
    physical_size: tuple[width, height: float]
    capabilities: seq[string]

  Contact* = object
    name*, number*: string

  Notification* = object
    id*: string
    title*: string
    content*: string
        
proc parseHook*(s: string, i: var int, d: var DateTime) =
  var dateStr: string
  parseHook(s, i, dateStr)
  d = dateStr.parse(dateFormat)

func renameHook*(v: var CallLog, fieldName: var string) =
  if fieldName == "type": fieldName = "kind"

func enumHook*(exposure: string): ExposureMode =
  case exposure
  of "CONTROL_AE_MODE_OFF": ModeOff
  of "CONTROL_AE_MODE_ON": ModeOn
  of "CONTROL_AE_MODE_ON_ALWAYS_FLASH": ModeOnAlwaysFlash
  of "CONTROL_AE_MODE_ON_AUTO_FLASH": ModeOnAutoFlash
  of "CONTROL_AE_MODE_ON_AUTO_FLASH_REDEYE": ModeOnAutoFlashRedeye
  of "CONTROL_AE_MODE_ON_EXTERNAL_FLASH": ModeOnExternalFlash
  else: Other

func enumHook*(health: string): BatteryHealth =
  case health
  of "COLD": Cold
  of "DEAD": Dead
  of "GOOD": Good
  of "OVERHEAT": Overheat
  of "OVER_VOLTAGE": OverVoltage
  of "UNKNOWN": Unknown
  else: UnspecifiedFailure
    
func enumHook*(plug: string): Plugged = 
  case plug
  of "UNPLUGGED": Unplugged
  of "PLUGGED_AC": AC
  of "PLUGGED_USB": USB
  of "PLUGGED_WIRELESS": Wireless
  else: Other
  
func enumHook*(call: string): CallType =
  case call
  of "BLOCKED": Blocked
  of "INCOMING": Incoming
  of "MISSED": Missed
  of "OUTGOING": Outgoing
  of "REJECTED": Rejected
  of "VOICEMAIL": Voicemail
  else: Unknown

