import std/[
  json,
  osproc,
  strformat,
  strutils,
  times
]

import jsony

import termuxApi/types

# TODO: Add check that the package is installed
# TODO: More helpful errors

##[
  Contains wrappers around [termux-api commands](https://wiki.termux.com/wiki/Termux:API). This package will aim to implement them all as time goes on
]##

proc termuxRun(command: string, input = ""): string {.discardable.} =
  ## Runs command, checks it passes, then returns output
  let (output, exit) = execCmdEx(command, input = input)
  if exit != 0:
    raise (ref TermuxFailed)(msg: output, code: exit)
  result = output

proc termuxRun[T](command: string, to: typedesc[T]): T =
  ## Runs command and then converts output from json to a type
  when T isnot JsonNode:
    command.termuxRun().fromJson(to)
  else:
    command.termuxRun().parseJson()

proc batteryStatus*(): BatteryStatus =
  ## Get the status of the device battery
  termuxRun("termux-battery-status", BatteryStatus)

proc setBrightness*(val: range[-1..255]) =
  ## Set the display brightness. Note that this may not work if automatic brightness control is enabled.
  ## Make val be `-1` for auto brightness
  termuxRun("termux-brightness {val}")

proc callLog*(limit = 10, offset = 0): seq[CallLog] =
  ## Gets phone call logs. Doesn't work on android `>= 9`
  termuxRun(fmt"termux-call-log -l {limit} -o {offset}", seq[CallLog])

proc cameraInfo*(): CameraInfo =
  ## Get information about device camera(s)
  termuxRun("termux-camera-info", CameraInfo)

proc takePhoto*(outpath: string, id = 0) =
  ## Take a photo and save it to a file in JPEG format
  termuxRun(fmt"termux-camera-photo -c {id} {outpath.escape()}")

proc getClipboard*(): string =
  ## Get the system clipboard text
  result = termuxRun("termux-clipboard-get")

proc setClipboard*(text: string) =
  ## Set the system clipboard text
  termuxRun("termux-clipboard-set", input = text)

proc contactList*(): seq[Contact] =
  ## Gets all contacts
  termuxRun("termux-contact-list", seq[Contact])

proc showDialog(widget, title, options: string): string =
  ## Show dialog widget for user input
  termuxRun(fmt"termux-dialog {widget} -t {title.escape()} {options}")


proc getTextDialog(widget, title, options: string): string =
  ## Helper around dialogs that return their value in `{"text": theText}` form
  showDialog(widget, title, options).parseJson()["text"].str
  
proc singleChoiceDialog(widget: string, values: openArray[string], title = ""): string =
  ## Abstraction around dialogs that take multiple values and return one
  let joinedValues = values.join(",").escape()
  getTextDialog(widget, title, fmt"-v {joinedValues}")

proc confirmDialog*(hint, title = ""): bool =
  ## Gets yes/no response from user
  getTextDialog("confirm", title, fmt"-i {hint.escape()}").parseBool()

proc checkboxDialog*(values: openArray[string], title = ""): seq[string] =
  ## Provide user with list of options and returns the ones they selected
  let joinedValues = values.join(",").escape()
  let resp = showDialog("checkbox", title, fmt"-v {joinedValues}").parseJson()
  if "values" in resp:
    for value in resp["values"]:
      result &= value["text"].str

proc dateDialog*(title = ""): DateTime =
  ## Gets a date from the user
  const dateFormat = "yyyy-MM-dd"
  getTextDialog("date", title, "-d {dateFormat}").parse(dateFormat)


proc radioDialog*(values: openArray[string], title = ""): string =
  ## Provides user with list of options and returns the one they selected.
  ## See checkboxDialog_ for getting multiple values
  singleChoiceDialog("radio", values, title)

proc sheetDialog*(values: openArray[string], title = ""): string =
  ## A sheet of values pops up from bottom of screen and allows user to select one
  singleChoiceDialog("sheet", values, title)
  
proc spinnerDialog*(values: openArray[string], title = ""): string =
  ## Provides a spinner (dropdown box) of values and returns what the user selects
  singleChoiceDialog("spinner", values, title)

proc speechDialog*(hint, title = ""): string =
  ## Asks for voice input from user and returns speech (in text form)
  getTextDialog("speech", title, fmt"-i {hint}")

proc textDialog*(multiLine, onlyNums, asPassword = false, hint, title = ""): string =
  ## Gets text input from user
  ##
  ## * **multiline**: Allow multiline input
  ## * **onlyNums**: Only allow numbers to be inputted (Cant be used with multiline)
  ## * **asPassword**: Hide input while typing
  assert not (multiline and onlyNums), "Multline and onlyNums cannot be used together"
  var options = fmt"-i {hint} "
  if multiline:
    options &= "-m "
  if onlyNums:
    options &= "-n "
  if asPassword:
    options &= "-p "
  getTextDialog("text", title, options)

proc timeDialog*(title = ""): string =
  ## Gets time (in 24 hour) from user
  getTextDialog("time", title, "")

proc download*(description, title, path, url: string) =
  ## Downloads URL using system download manager
  termuxRun(fmt"termux-download -d {description.escape()} -t {title.escape()} -p {path.escape()} {url.escape()}")

proc fingerprintAuth*(): bool =
  ## Uses fingerprint to check for authentication. Returns true if it passed
  result = termuxRun(fmt"termux-fingerprint", JsonNode)["auth_result"].str == "AUTH_RESULT_SUCCESS"

func newNotification*(title, content: string, id = ""): Notification =
  result.title = title
  result.content = content
  result.id = id
  
proc show*(n: Notification) =
  var options = fmt"-t {n.title.escape()} -c {n.content.escape()} "
  if n.id != "":
    options &= fmt"-i {n.id} "
  termuxRun(fmt"termux-notification {options}")
