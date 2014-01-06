proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  focus $w
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
}

proc poke_entry {entry pokeList} {
  for {set i 1} {$i < 7} {incr i} {
    catch {destroy [winfo children .mainpane.note.gen$i]}
  }
  set pokemon [lindex $pokeList [$entry curselection]]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
}

proc poke_autocomplete {entry action validation value list} {
  if {$action == 1 && $value != {} && [set pop [lsearch -inline -nocase $list $value*]] != {}} {
    set cursorIndex [string length $value]
    $entry delete 0 end
    $entry insert end $pop
    $entry selection range $cursorIndex end
    $entry icursor $cursorIndex
    poke_showlist $entry $list $value
  } else {
    $entry selection clear
  }
  after idle [list $entry configure -validate $validation]
  return 1
}

proc poke_populate {pokemon} {
  catch {destroy [winfo children .mainpane.note.gen1]}
  pack [label .mainpane.note.gen1.lab -text $pokemon]
  if {[winfo exists .listbox]} {lb_remove}
}

proc poke_showlist {entry pokeList text} {
  if {![winfo exists .listbox]} {
    set miniList [lsearch -all -inline $pokeList $text*]
    if {[llength $miniList] < 2} {
      lb_remove
      return
    }
    catch {destroy [winfo children .mainpane.note.gen1]}

    set lb .listbox
    
    toplevel $lb
    wm withdraw $lb
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
    wm deiconify $lb
    wm transient $lb .
    
    raise $lb
    
    bind $lb <KeyPress-Escape> lb_remove
    bind $lb <KeyPress-Return> [list lb_populate_entry %W $miniList]
    bind $lb.l <FocusOut> lb_remove
    bind $lb <FocusOut> lb_remove
    bind $lb <Motion> "poke_hover %W %x %y"
    bind $lb <ButtonPress-1> [list lb_populate_entry %W $miniList]
 
    return 1
  } else {
    destroy .listbox
    poke_showlist $entry $pokeList $text
  }
}

proc lb_remove {} {
  if {[winfo exists .listbox]} {
    wm withdraw .listbox
    destroy .listbox
  }
  focus -force .sidepane.top.entry
}

proc lb_populate_entry {lb mini} {
  if {![catch {set pokemon [lindex $mini [$lb curselection]]}]} {
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    poke_populate $pokemon
  }
  lb_remove
}

proc poke_hover {w x y} {
  if {![catch {$w selection clear 0 end}]} {
    $w activate @$x,$y
    $w selection set @$x,$y
  }
}