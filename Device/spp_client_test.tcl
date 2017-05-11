#!/usr/bin/tclsh

source chan.tcl
source spp_client.tcl

# test that command returns an error
proc test_err {cmd res} {
  catch $cmd e
  if {$res != $e} {error "ERROR:\n result: <$e>\n expect: <$res>"}
}

# test that command returns some result
proc test_res {cmd res} {
  set r [eval $cmd]
  if {$res != $r} {error "ERROR:\n result: <$r>\n expect: <$res>"}
}

test_err {spp_client cla "date" } "date: unknown protocol"
test_err {spp_client clb "echo" } "echo: unknown protocol"

test_res {spp_client cl1 "./spp_server_test.tcl" } "cl1"
test_err {spp_client clx "./spp_server_test.tcl a"} "argument should be a positive integer"

test_err {cl1 cmd a}            {Unknown command: a}
test_err {cl1 cmd "read 0"}     {can't read "var(0)": no such variable}
test_err {cl1 cmd "write a"}    {wrong # args: should be "testSrv0 write k v"}
test_err {cl1 cmd "write n v"}  {k must be integer between 0 and 9}
test_err {cl1 cmd "write 10 v"} {k must be integer between 0 and 9}

test_res {cl1 cmd "list"}       {{read write echo wait list help}}
test_res {cl1 cmd "write 0 1"}  {}
test_res {cl1 cmd "read 0"}     {1}

# check how the special symbol is protected
test_res {cl1 cmd "write 1 #1"}  {}
test_res {cl1 cmd "read 1"}      {{#1}}
test_res {cl1 cmd "write 1 ##1"} {}
test_res {cl1 cmd "read 1"}      {{##1}}
test_res {cl1 cmd "write 1 #1#"} {}
test_res {cl1 cmd "read 1"}      {{#1#}}

test_res {cl1 cmd "wait 50"}     {}

test_res {cl1 cmd "echo #"}      {{#}}

test_err {cl1 cmd "wait 200"}    {}
test_res {cl1 cmd "echo #"}      {{#}}
