package require Itcl
package require Locking 2.0

# Open any device, send command, read response, close device.
#
# Usage:
#  Device lockin0
#  lockin0 cmd *IDN?
#
# Information about devices read from devices.txt file:
# name model driver parameters
#
# There are two levels of locking implemented using Rota's Locking library.
# - low-level locking is done on every single input/output operation
#   to prevent mixing read and write commands from different clients.
# - high level locking is done by lock/unlock methods to allow user
#    to grab the device completely for a long time.
#
itcl::class Device {
  variable dev;    # device handle
  variable name;   # device name
  variable model;  # device model
  variable drv;    # device driver
  variable pars;   # driver parameters
  variable gpib_addr;  # gpib address (for gpib_prologix driver)

  ####################################################################
  constructor {} {
    # get device name (remove tcl namespace from $this)
    set name $this
    set drv  {}
    set cn [string last ":" $name]
    if {$cn >0} {set name [string range $name [expr $cn+1] end]}

    # get device parameters from devices.txt file
    set fp [open /etc/devices.txt]
    while { [gets $fp line] >= 0 } {

      # remove comments
      set cn [string first "#" $line]
      if {$cn==0} {continue}
      if {$cn>0} {set line [string range $line 0 [expr $cn-1]]}

      # split line
      set data [regexp -all -inline {\S+} $line]
      if { [lindex $data 0] == $name } {
        set model [lindex $data 1]
        set drv   [lindex $data 2]
        set pars  [lrange $data 3 end]
        break
      }
    }
    if { $drv eq "" } { error "Can't find device $name in /etc/devices.txt"}
    set dev [conn_drivers::$drv #auto $pars]
  }


  ####################################################################
  # run command, read response if needed
  method write {args} {
    set dd [after 1000 { error "Device locking timeout"; return }]
    ::lock io_$name
    after cancel $dd
    set e [catch {set ret [$dev write $args]}]
    ::unlock io_$name
    if {$e} {error $::errorInfo}
    return {}
  }

  ####################################################################
  # run command, read response if needed
  method cmd {args} {
    set dd [after 1000 { error "Device locking timeout"; return }]
    ::lock io_$name
    after cancel $dd
    set e [catch {set ret [$dev cmd $args]}]
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return $ret
  }
  # alias
  method cmd_read {args} { cmd $args }

  ####################################################################
  # read response
  method read {} {
    set dd [after 1000 { error "Device locking timeout"; return }]
    ::lock io_$name
    after cancel $dd
    set e [catch {set ret [$dev read]}]
    ::unlock io_$name

    if {$e} {error $::errorInfo}
    return $ret
  }

  ####################################################################
  # High-level lock commands.
  # If you want to grab the device for a long time, use this
  method lock {} {
    set dd [after 1000 { error "Device is locked" }]
    ::lock $name
    after cancel $dd
  }
  method unlock {} {
    ::unlock $name
  }

  method get_model {} {return $model}

}
