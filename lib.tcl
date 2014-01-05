proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
}

proc poke_populate {} {
  global pokeList
  for {set i 1} {$i < 7} {incr i} {
    catch {destroy [winfo children .mainpane.note.gen$i]}
  }
  set pokemon [lindex $pokeList [.sidepane.bottom.list curselection]]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
#  for {set i 1} {$i < 7} {incr i} {
#    pack [label .mainpane.note.gen$i.lab -text $pokemon]
#  }
}

proc poke_autocomplete {win action validation value list} {
  if {$action == 1 && $value != {} && [set pop [lsearch -inline -nocase $list $value*]] != {}} {
    $win delete 0 end;  $win insert end $pop
    $win selection range [string length $value] end
    $win icursor [string length $value]
  } else {
    $win selection clear
  }
  after idle [list $win configure -validate $validation]
  return 1
}
