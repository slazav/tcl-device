## Server part of the command line interface.
## Usage:
##   spp_client conn $prog_name
##   conn cmd <command>
## Server errors are converted into tcl errors
## Server answers are returned as a list of lines

package require Itcl

itcl::class spp_client {
  variable conn
  variable ch
  variable ver
  variable open_timeout 5000
  variable read_timeout -1

  constructor {prog_name} {
    set conn [::open "| $prog_name" RDWR]
    if [eof $conn] {
      error "$prog_name: unknown protocol"}
    set l [gets_timeout $conn $open_timeout]
    if {![regexp {^(.)SPP([0-9]+)$} $l l ch ver]} {
      error "$prog_name: unknown protocol"}
    if {$ver < 002} {
      error "$prog_name: too old protocol version"}
    if {$ver != 002} {
      error "$prog_name: unknown protocol version"}
    read
  }

  destructor {
    ::close $conn
  }

  # write command, read response until #OK or #Error line
  method cmd {c} {
    ::puts $conn $c
    read
  }

  # separate commands for reading and writing
  method write {c} {
    ::puts $conn $c
  }

  method read {} {
    set ret {}
    while {![eof $conn]} {
      set l [gets_timeout $conn $read_timeout]
      if { [regexp "^${ch}${ch}" $l] } { set l [string range $l 1 end] }\
      else {
        if { [regexp -nocase "^${ch}Error: (.*)\$" $l e1 e2] } { error $e2 }
        if { [regexp -nocase "^${ch}Fatal: (.*)\$" $l e1 e2] } { error $e2 }
        if { [regexp -nocase "^${ch}OK\$" $l]} { return $ret }
        if { [regexp {^${ch}} $l] } {
          error "symbol ${ch} in the beginning of a line is not protected"
        }
      }
      lappend ret $l
    }
    return $ret
  }

}

