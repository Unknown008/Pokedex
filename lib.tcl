proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
}

proc poke_entry {pokeList} {
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
  if {![winfo exists .listbox]} {
    set text [string range [.sidepane.top.entry get] 0 $cursorIndex-1]
    set miniList [lsearch -all -inline $pokeList $text*]
    #if {[llength $miniList] > 10} {return}
    
    catch {destroy [winfo children .mainpane.note.gen1]}
    pack [label .mainpane.note.gen1.lab -text $miniList]
    
    set lb .listbox
    
    toplevel $lb
    wm withdraw $lb
    update idletasks
    wm overrideredirect $lb 1
    listbox $lb.l -exportselection 0 -selectmode browse -activestyle dotbox \
      -listvariable $miniList
    $lb.l insert 0 {*}$miniList
    
    $lb.l selection clear 0 end
    $lb.l selection set 0
    $lb.l activate 0
    $lb.l see 0
    set height [llength $miniList]
    if {$height > [$lb.l cget -height]} {
      set height [$lb.l cget -height]
    }
    $lb.l configure -height $height
    
    set x [winfo rootx $entry]
    set y [winfo rooty $entry]
    set w [winfo width $entry]
    set h [winfo height $entry]
    set H [winfo reqheight $lb.l]
    if {$y + $h + $H > [winfo screenheight .]} {
      set Y [expr {$y - $H}]
    } else {
      set Y [expr {$y + $h}]
    }
    wm geometry $lb ${w}x${H}+${x}+${Y}
    grid $lb.l -sticky news
    grid columnconfigure $lb 0 -weight 1
    grid rowconfigure $lb 0 -weight 1
    wm attribute $lb -topmost 1
    wm transient $lb .
    update idletasks
    wm deiconify $lb
    wm transient $lb .
    
    raise $lb
    
    bind $lb <KeyPress-Escape> lb_remove
    bind $lb <KeyPress-Return> [list lb_populate_entry %W $miniList]
    bind $lb <FocusOut> lb_remove
    focus $lb.l
    return 1
  } else {
    destroy .listbox
    poke_showlist $entry
  }
}

proc lb_remove {} {
  if {[winfo exists .listbox]} {
    wm withdraw .listbox
  }
}

proc lb_populate_entry {lb mini} {
  set pokemon [lindex $mini [$lb curselection]]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
  
  if {[winfo exists .listbox]} {
    wm withdraw .listbox
  }
  focus .sidepane.top.entry
}