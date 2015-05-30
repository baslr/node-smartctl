###
    s m a r t c t l
###

exec = require('child_process').exec



###
    R A W  C M D
###
module.exports.raw = execSmart = (args, cb) ->
  exec "smartctl #{args}", {maxBuffer:1024*1024*24}, (e, stdout, stderr) ->
    lines = stdout.split('\n').slice 0, -1

    if e?
      cb lines.slice(3), []
    else
      cb null, lines.slice 4



###
    D E V I C E  I N F O S
###
module.exports.info = (devicePath, cb) ->
  execSmart "-i #{devicePath}", (e, lines) ->
    return cb e, lines if e?

    deviceInfos = {}
    for line in lines.slice 0, -1
      deviceInfos[ line.substring(0, line.search ': ').trim().replace(/\ +/g, '_').toLowerCase() ] = line.substring(1+line.search ': ').trim()
    cb null, deviceInfos



###
    S M A R T  A T T R S
###
module.exports.smartAttrs = (devicePath, cb) ->
  execSmart "-A -f brief #{devicePath}", (e, lines) ->
    return cb e, lines if e?

    lines = lines.slice 2, -1
    head  = lines.shift()
    infos = []

    for line in lines
      attr = line.substring(head.indexOf('ATTRIBUTE_NAME'),  head.indexOf('FLAGS')).trim().toLowerCase()
      continue if attr is ''

      infos.push {
        attr   : attr
        id     : Number line.substring(0,                      head.indexOf('ATTRIBUTE_NAME')).trim()
        flags  :        line.substring(head.indexOf('FLAGS'),  head.indexOf('VALUE')).trim()
        value  :        line.substring(head.indexOf('VALUE'),  head.indexOf('WORST')).trim()
        worst  :        line.substring(head.indexOf('WORST'),  head.indexOf('THRESH')).trim()
        thresh :        line.substring(head.indexOf('THRESH'), head.indexOf('FAIL')).trim()
        fail   :        line.substring(head.indexOf('FAIL'),   head.indexOf('RAW_VALUE')).trim()
        raw    : Number line.substring(head.indexOf('RAW_VALUE')).trim().split(' ')[0]
      }
    cb null, infos



###
    S M A R T  H E A L T H
###
module.exports.health = (devicePath, cb) ->
  execSmart "-H #{devicePath}", (e, lines) ->
    return cb e, lines if e?

    lines = lines.slice 0, -1

    if 0 is lines[0].search 'SMART overall-health self-assessment test result: '
      status = lines[0].split(' ').pop().toLowerCase()

      cb null, status
    else
      cb null, lines



module.exports.scan = (cb) ->
  exec 'smartctl --scan-open', {maxBuffer:1024*1024*24}, (e, stdout, stderr) ->
    devices = []

    for n in stdout.split('\n').slice 0, -1
      devices.push n.split(' ')[0]

    cb devices
