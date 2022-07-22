import std/[
  unittest,
  times,
  os
]
import termuxApi

## Requires android device to run on 

test "Get contact list":
  check contactList().len > 0

test "Set clipboard then get info back":
  const text = "Hello world, this is a text " & $cpuTime()
  setClipboard(text)
  check getClipboard() == text

test "Take photo":
  let file = "test.jpg"
  takePhoto(file)
  check file.fileExists

test "Get battery status":
  check batteryStatus().percentage > 0
