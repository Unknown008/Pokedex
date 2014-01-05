proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
}

proc poke_entry {} {
  global pokeList
  for {set i 1} {$i < 7} {incr i} {
    catch {destroy [winfo children .mainpane.note.gen$i]}
  }
  set pokemon [lindex $pokeList [.sidepane.bottom.list curselection]]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
}

proc poke_autocomplete {entry action validation value list} {
  global cursorIndex
  if {$action == 1 && $value != {} && [set pop [lsearch -inline -nocase $list $value*]] != {}} {
    set cursorIndex [string length $value]
    $entry delete 0 end
    $entry insert end $pop
    $entry selection range $cursorIndex end
    $entry icursor $cursorIndex
  } else {
    $entry selection clear
  }
  global cursorIndex
  after idle [list $entry configure -validate $validation]
  return 1
}

proc poke_populate {pokemon} {
  catch {destroy [winfo children .mainpane.note.gen1]}
  pack [label .mainpane.note.gen1.lab -text $pokemon]
  .sidepane.top.entry selection clear
  .sidepane.top.entry icursor end
}

proc poke_showlist {entry} {
  global cursorIndex pokeList
  set text [string range [.sidepane.top.entry get] 0 $cursorIndex-1]
  set miniList [lsearch -all -inline $pokeList $text*]
  if {[llength $miniList] > 10} {return}
  
  set x [winfo rootx $entry]
  set y [winfo rooty $entry]
  set w [winfo width $entry]
  set h [winfo height $entry]
  set coords "$x $y $w $h"
  
  catch {destroy [winfo children .mainpane.note.gen1]}
  pack [label .mainpane.note.gen1.lab -text $coords]
  
  set lb .listbox
  
  toplevel $lb
  wm withdraw $lb
  $lb configure -relief solid -borderwidth 1
  listbox $lb.l -exportselection 0 -selectmode browse -activestyle none \
    -listvariable $miniList
  wm attribute $lb -topmost 1
  wm deiconify $lb
  wm transient $lb .
  wm geometry $lb ${w}x${h}+${x}+${y}
  raise $lb
  
}