### Credits window
proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  focus $w
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
  # © 1995-2014 The Pokémon Company, Nintendo, Creatures Inc., Game Freak Inc.
}

### Double click from list pane procedure
proc poke_entry {entry pokeList} {
  foreach i {1 2 3 4 5 6} {
    #catch {destroy [winfo children .mainpane.note.gen$i.lab]}
  }
  set pokemon [lindex $pokeList [$entry curselection]]
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
}

### Pressing enter from list
proc list_populate_entry {lb pokeList} {
  if {![catch {set pokemon [lindex $pokeList [$lb curselection]]}]} {
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    poke_populate $pokemon
  }
  focus $lb
}

### Autocomplete of entry box
proc poke_autocomplete {entry action validation value pokeList} {
  if {$action == 1 && $value != {} && [set pop [lsearch -inline -nocase $pokeList $value*]] != {}} {
    set cursorIndex [string length $value]
    $entry delete 0 end
    $entry insert end $pop
    $entry selection range $cursorIndex end
    $entry icursor $cursorIndex
    poke_showlist $entry $pokeList $value
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
    
    bind $lb <KeyPress-Escape> {lb_remove}
    bind $entry <KeyPress-Escape> {lb_remove}
    bind . <ButtonPress-1> {lb_remove}
    bind $lb.l <FocusOut> {lb_remove}
    bind $lb <FocusOut> {lb_remove}
    bind $lb <KeyPress-Return> [list lb_populate_entry %W $miniList]
    bind $lb <ButtonPress-1> [list lb_populate_entry %W $miniList]
    bind $lb <Motion> [list poke_hover %W %x %y]
    
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
  set w .mainpane.note
  
  set idx [lsearch -nocase $pokeList $pokemon]
  if {$idx == -1} {return}
  tab_update $w $idx
  
  .sidepane.top.entry selection clear
  .sidepane.top.entry icursor end
  set w .mainpane.note
  foreach i {1 2 3 4 5 6} {
    catch {destroy [winfo children $w.gen$i.lab]}
  }
  
  if {[winfo exists .sidepane.top.listbox]} {lb_remove}
  #poke_populate_gen1 $w $pokemon $idx
  #poke_populate_gen2 $w $pokemon $idx
  #poke_populate_gen3 $w $pokemon $idx
  #poke_populate_gen4 $w $pokemon $idx
  #poke_populate_gen5 $w $pokemon $idx
  poke_populate_gen6 $w $pokemon $idx
}

### Focus on popup when down arrow pressed
proc poke_focus {pokeList} {
  if {[.sidepane.top.entry get] eq ""} {return}
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
proc poke_populate_gen1 {w pokemon idx} {
  global pokeDir
  
  catch {image create photo gen1Sprite -file "$pokeDir/data/sprites-1/$pokemon.png" \
    -format png} res
  $w.gen1.lab configure -text $pokemon
  $w.gen1.sprite configure -image gen1Sprite  
  
  # Populate details
  #info_populate $w $pokemon $idx
}

proc poke_populate_gen2 {w pokemon idx} {
  global pokeDir
  
  catch {image create photo gen2Sprite -file "$pokeDir/data/sprites-2/$pokemon.png" \
    -format png} res
  $w.gen2.lab configure -text $pokemon
  $w.gen2.sprite configure -image gen2Sprite  
  
  # Populate details
  #info_populate $w $pokemon $idx
}

proc poke_populate_gen3 {w pokemon idx} {
  global pokeDir
  
  catch {image create photo gen3Sprite -file "$pokeDir/data/sprites-3/$pokemon.png" \
    -format png} res
  $w.gen3.lab configure -text $pokemon
  $w.gen3.sprite configure -image gen3Sprite  
  
  # Populate details
  #info_populate $w $pokemon $idx
}

proc poke_populate_gen4 {w pokemon idx} {
  global pokeDir
  
  catch {image create photo gen4Sprite -file "$pokeDir/data/sprites-4/$pokemon.png" \
    -format png} res
  $w.gen4.lab configure -text $pokemon
  $w.gen4.sprite configure -image gen4Sprite  
  
  # Populate details
  #info_populate $w $pokemon $idx
}

proc poke_populate_gen5 {w pokemon idx} {
  global framesGen5 pokeDir
  if {[info exists framesGen5]} {
    foreach n $framesGen5 {rename $n {}}
  }
  set framesGen5 [get_frames "$pokeDir/data/sprites-5/$pokemon.gif"]
  set interval [get_fps "$pokeDir/data/sprites-5/$pokemon.gif"]

  $w.gen5.lab configure -text $pokemon
  $w.gen5.sprite configure -image [lindex $framesGen5 0]
  
  after idle "animate_poke $w.gen5.sprite \"$framesGen5\" $interval"
  # Populate details
  #info_populate $w $pokemon $idx
}

proc poke_populate_gen6 {w pokemon idx} {
  global framesGen6 pokeDir
  if {[info exists framesGen6]} {
    foreach n $framesGen6 {rename $n {}}
  }
  set framesGen6 [get_frames "$pokeDir/data/sprites-6/$pokemon.gif"]
  set interval [get_fps "$pokeDir/data/sprites-6/$pokemon.gif"]

  
  $w.gen6.sprite configure -image [lindex $framesGen6 0]
  
  after idle "animate_poke $w.gen6.sprite \"$framesGen6\" $interval"
  # Populate details. Since lists are zero based, 1 has to be added to $idx
  incr idx
  info_populate $w $pokemon [format "#%03d" $idx] 6
}

### Update tabs
proc tab_update {w idx} {
  foreach {a b} {0 151 1 251 2 386 3 493 4 650} {
    if {$idx > $b && [$w tab $a -state] eq "normal"} {
      $w tab $a -state disabled
    } elseif {$idx <= $b && [$w tab $a -state] eq "disabled"} {
      $w tab $a -state normal
    }
  }
}

### Add informations
proc info_populate {w pokemon idx i} {
  global pokeDir
  #set data [open "$pokeDir/data/info.txt" r]
  #fconfigure $data -encoding utf-8
  #while {[gets $data line] != -1} {
  #  if {[lindex [split $line "|"] 0] eq [format "#%03d" $idx]} {break}
  #}
  #close $data
  #set datagroup [split $line "|"]
  set datagroup [dex eval {SELECT * FROM pokeDetails WHERE id = $idx}]
  lassign $datagroup id - formname type genus ability hability gender egggroup height \
    weight
  $w.gen$i.lab configure -text "$id $pokemon"
  $w.gen$i.info.formvar configure -text $formname
  $w.gen$i.info.typevar configure -text $type
  $w.gen$i.info.genuvar configure -text $genus
  $w.gen$i.info.abilvar configure -text $ability
  $w.gen$i.info.gendvar configure -text $gender
  $w.gen$i.info.egggvar configure -text $egggroup
  $w.gen$i.info.heigvar configure -text "$height m"
  $w.gen$i.info.weigvar configure -text "$weight kg"
}