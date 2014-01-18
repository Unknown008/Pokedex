### Credits window
proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  focus $w
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
}

### Double click from list pane procedure
proc poke_entry {entry pokeList} {
  foreach i {1 2 3 4 5 6} {
    #catch {destroy [winfo children .mainpane.note.gen$i.lab]}
  }
  set pokemon [lindex $pokeList [$entry curselection]+1]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
}

### Pressing enter from list
proc list_populate_entry {lb list} {
  if {![catch {set pokemon [lindex $list [$lb curselection]+1]}]} {
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    poke_populate $pokemon
  }
  focus $lb
}

### Autocomplete of entry box
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

### Popup listbox when typing for suggestions
proc poke_showlist {entry pokeList text} {
  if {![winfo exists .sidepane.top.listbox]} {
    set miniList [lsearch -all -inline -nocase $pokeList $text*]
    if {[llength $miniList] < 2} {
      lb_remove
      return 0
    }
    
    set lb .sidepane.top.listbox
    
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
    bind $entry <KeyPress-Escape> lb_remove
    bind . <ButtonPress-1> lb_remove
    bind $lb.l <FocusOut> lb_remove
    bind $lb <FocusOut> lb_remove
    bind $lb <KeyPress-Return> [list lb_populate_entry %W $miniList]
    bind $lb <ButtonPress-1> [list lb_populate_entry %W $miniList]
    bind $lb <Motion> "poke_hover %W %x %y"
    
    return 1
  } else {
    destroy .sidepane.top.listbox
    poke_showlist $entry $pokeList $text
  }
}

### Removing the popup window
proc lb_remove {} {
  if {[winfo exists .sidepane.top.listbox]} {
    wm withdraw .sidepane.top.listbox
    destroy .sidepane.top.listbox
    ttk::releaseGrab .sidepane.top.listbox.l
    grab release .sidepane.top.listbox.l
  }
  focus -force .sidepane.top.entry
}

### Put selection from popup into entry box
proc lb_populate_entry {lb mini} {
  if {![catch {set pokemon [lindex $mini [$lb curselection]]}]} {
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    poke_populate $pokemon
  }
  lb_remove
}

### Procedure for mouse hover over popup
proc poke_hover {w x y} {
  if {![catch {$w selection clear 0 end}]} {
    $w activate @$x,$y
    $w selection set @$x,$y
  }
}

###
proc poke_populate {pokemon} {
  global pokeList
  set idx [lsearch $pokeList $pokemon]
  # Disable certain tabs here
  .sidepane.top.entry selection clear
  .sidepane.top.entry icursor end
  set w .mainpane.note
  foreach i {1 2 3 4 5 6} {
    catch {destroy [winfo children $w.gen$i.lab]}
  }
  
  if {[winfo exists .sidepane.top.listbox]} {lb_remove}
  #poke_populate_gen1 $w $pokemon
  #poke_populate_gen2 $w $pokemon
  #poke_populate_gen3 $w $pokemon
  #poke_populate_gen4 $w $pokemon
  #poke_populate_gen5 $w $pokemon
  poke_populate_gen6 $w $pokemon
}

### Focus on popup when down arrow pressed
proc poke_focus {pokeList} {
  if {[.sidepane.top.entry get] == ""} {return}
  set text [string range [.sidepane.top.entry get] 0 [.sidepane.top.entry index insert]-1]
  if {[poke_showlist .sidepane.top.entry $pokeList $text]} {
    focus .sidepane.top.listbox.l
    ttk::globalGrab .sidepane.top.listbox.l
  }
}

### Get all frames of gif file
proc get_frames {image} {
  set idx 0
  set results [list]
  while {1} {
    if {[catch {image create photo -file $image -format "gif -index $idx"} res]} {
      return $results
    }
    lappend results $res
    incr idx
  }
}

### Loop through each frame of gif file for animation
proc animate_poke {w images interval} {
  if {[catch {$w configure -image}]} {
    pack [label $w -bd 0 -image [lindex $images 0]]
  }
  set img [lindex [$w configure -image] end]
  
  set idx [lsearch $images $img]
  incr idx
  if {$idx > [llength $images]-1} {set idx 0}
  if {[catch {$w configure -image [lindex $images $idx]} err]} {return}
  after $interval "animate_poke $w \"$images\" $interval"
}

### Get frame rate of gif file
proc get_fps {file} {
  set f [open $file r]
  fconfigure $f -eof {}
  set data [read $f]
  close $f
  binary scan $data H* hex
  regexp -nocase -- {0021F904..(..)} $hex - time
  scan $time %x dec
  return [expr {$dec*10}]
}

### Fill main pane with details of Pokémon
proc poke_populate_gen6 {w pokemon} {
  global framesGen6 pokeDir
  if {[info exists framesGen6]} {
    foreach n $framesGen6 {rename $n {}}
  }
  set framesGen6 [get_frames "$pokeDir/data/sprites-6/$pokemon.gif"]
  set interval [get_fps "$pokeDir/data/sprites-6/$pokemon.gif"]
  #set framesGen6 [lreplace $framesGen6 end end]
  #pack [label $w.gen1.l -image [lindex $framesGen6 end] -bd 1]
  if {![winfo exists $w.gen6.lab.sprite]} {
    pack [label $w.gen6.lab.sprite -image [lindex $framesGen6 0] -bd 1]
  } else {
    $w.gen6.lab.sprite configure -image [lindex $framesGen6 0]
  }
  after idle "animate_poke $w.gen6.lab.sprite \"$framesGen6\" $interval"
  #set button [tk_messageBox -title Bug -message ""]
}