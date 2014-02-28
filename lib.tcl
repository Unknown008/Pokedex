### Credits window
proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  focus $w
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
  label $w.lab -text \
    "\u00A9 1995-2014 The Pok\u00E9mon Company, Nintendo, Creatures Inc., \
    Game Freak Inc."
  pack $w.lab
}

### Double click from list pane procedure
proc poke_entry {entry pokeList} {
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
  if {$action == 1 && $value != {} && 
     [set pop [lsearch -inline -nocase $pokeList $value*]] != {}} {
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

### Procedure to instruct population of each gen
proc poke_populate {pokemon} {
  global pokeList
  set w .mainpane.note
  
  set idx [lsearch -nocase $pokeList $pokemon]
  if {$idx == -1} {return}
  tab_update $w $idx
  
  .sidepane.top.entry selection clear
  .sidepane.top.entry icursor end

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
  set text [string range [.sidepane.top.entry get] 0 \
    [.sidepane.top.entry index insert]-1]
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
  
  after idle "animate_poke $w.gen5.down.sprite \"$framesGen5\" $interval"
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
  
  $w.gen6.down.sprite configure -image [lindex $framesGen6 0]
  
  after idle "animate_poke $w.gen6.down.sprite \"$framesGen6\" $interval"
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

  set datagroup [dex eval {SELECT * FROM pokeDetails WHERE id = $idx}]
  lassign $datagroup id - formname type genus ability hability gender egggroup \
    height weight
  $w.gen$i.lab configure -text "$idx $pokemon"
  
  $w.gen$i.down.info.formvar configure -state normal
  $w.gen$i.down.info.formvar delete 1.0 end
  $w.gen$i.down.info.formvar insert end $formname
  $w.gen$i.down.info.formvar configure -state disabled
  
  $w.gen$i.down.info.typevar configure -state normal
  $w.gen$i.down.info.typevar delete 1.0 end
  $w.gen$i.down.info.typevar insert end $type
  $w.gen$i.down.info.typevar configure -state disabled
  
  $w.gen$i.down.info.genuvar configure -state normal
  $w.gen$i.down.info.genuvar delete 1.0 end
  $w.gen$i.down.info.genuvar insert end $genus
  $w.gen$i.down.info.genuvar configure -state disabled
  
  $w.gen$i.down.info.abilvar configure -state normal
  $w.gen$i.down.info.abilvar delete 1.0 end
  $w.gen$i.down.info.abilvar tag bind main <Any-Enter> \
    [list linkify $w.gen$i.down.info.abilvar main 1]
  $w.gen$i.down.info.abilvar tag bind main <Any-Leave> \
    [list linkify $w.gen$i.down.info.abilvar main 0]
  $w.gen$i.down.info.abilvar tag bind secd <Any-Enter> \
    [list linkify $w.gen$i.down.info.abilvar secd 1]
  $w.gen$i.down.info.abilvar tag bind secd <Any-Leave> \
    [list linkify $w.gen$i.down.info.abilvar secd 0]
  $w.gen$i.down.info.abilvar tag bind hidden <Any-Enter> \
    [list linkify $w.gen$i.down.info.abilvar hidden 1]
  $w.gen$i.down.info.abilvar tag bind hidden <Any-Leave> \
    [list linkify $w.gen$i.down.info.abilvar hidden 0]
  if {[string first "/" $ability] == -1} {
    $w.gen$i.down.info.abilvar insert end $ability main
    $w.gen$i.down.info.abilvar tag bind main <ButtonPress-1> \
      [list abil_link $ability]
  } else {
    lassign [split $ability "/"] m1 m2
    $w.gen$i.down.info.abilvar insert end $m1 main
    $w.gen$i.down.info.abilvar insert end "/"
    $w.gen$i.down.info.abilvar insert end $m2 secd
    $w.gen$i.down.info.abilvar tag bind main <ButtonPress-1> \
      [list abil_link $m1]
    $w.gen$i.down.info.abilvar tag bind secd <ButtonPress-1> \
      [list abil_link $m2]
  }
  if {$hability ne ""} {
    $w.gen$i.down.info.abilvar insert end "/"
    $w.gen$i.down.info.abilvar insert end $hability hidden
    $w.gen$i.down.info.abilvar tag bind hidden <ButtonPress-1> \
      [list abil_link $hability]
  }
  tooltip::tooltip $w.gen$i.down.info.abilvar "More detail"
  $w.gen$i.down.info.abilvar configure -state disabled
  
  $w.gen$i.down.info.gendvar configure -state normal
  $w.gen$i.down.info.gendvar delete 1.0 end
  if {$gender ne "N/A"} {
    $w.gen$i.down.info.gendvar insert end [lindex [split $gender "/"] 0] male
    $w.gen$i.down.info.gendvar insert end "/" male
    $w.gen$i.down.info.gendvar insert end [lindex [split $gender "/"] 1] female
    $w.gen$i.down.info.gendvar insert end " %"
  } else {
    $w.gen$i.down.info.gendvar insert end "N/A"
  }
  $w.gen$i.down.info.gendvar configure -state disabled
  
  $w.gen$i.down.info.egggvar configure -state normal
  $w.gen$i.down.info.egggvar delete 1.0 end
  $w.gen$i.down.info.egggvar tag bind main <Any-Enter> \
    [list linkify $w.gen$i.down.info.egggvar main 1]
  $w.gen$i.down.info.egggvar tag bind main <Any-Leave> \
    [list linkify $w.gen$i.down.info.egggvar main 0]
  $w.gen$i.down.info.egggvar tag bind secd <Any-Enter> \
    [list linkify $w.gen$i.down.info.egggvar secd 1]
  $w.gen$i.down.info.egggvar tag bind secd <Any-Leave> \
    [list linkify $w.gen$i.down.info.egggvar secd 0]
  if {[string first "," $egggroup] == -1} {
    $w.gen$i.down.info.egggvar insert end $egggroup main
    $w.gen$i.down.info.egggvar tag bind main <ButtonPress-1> \
      [list egg_link $egggroup]
  } else {
    lassign [split $egggroup ","] m1 m2
    set m2 [string trim $m2]
    $w.gen$i.down.info.egggvar insert end $m1 main
    $w.gen$i.down.info.egggvar insert end ", "
    $w.gen$i.down.info.egggvar insert end $m2 secd
    $w.gen$i.down.info.egggvar tag bind main <ButtonPress-1> [list egg_link $m1]
    $w.gen$i.down.info.egggvar tag bind secd <ButtonPress-1> [list egg_link $m2]
  }
  tooltip::tooltip $w.gen$i.down.info.egggvar [mc "Pok\u00E9mon in same Egg Group"]
  $w.gen$i.down.info.egggvar configure -state disabled
  
  $w.gen$i.down.info.heigvar configure -state normal
  $w.gen$i.down.info.heigvar delete 1.0 end
  $w.gen$i.down.info.heigvar insert end "$height m"
  $w.gen$i.down.info.heigvar configure -state disabled
  
  $w.gen$i.down.info.weigvar configure -state normal
  $w.gen$i.down.info.weigvar delete 1.0 end
  $w.gen$i.down.info.weigvar insert end "$weight kg"
  $w.gen$i.down.info.weigvar configure -state disabled
}

proc linkify {w tag state} {
  set cursor [expr {$state ? "hand2" : "ibeam"}]
  $w tag configure $tag -underline $state
  $w configure -cursor $cursor
}

### Procedure to link to abilities
proc abil_link {ability} {
  set datagroup [dex eval {SELECT description FROM abilDetails WHERE id = $ability}]
  set desc [lindex $datagroup 0]
  catch {destroy .ability}
  set w .ability
  toplevel $w
  wm title $w "[mc "Ability:"] $ability"
  
  set menu $w.abilmenu
  menu $menu -tearoff 0

  set types [list Grass Fire Water Bug Flying Electric Ground Rock Fighting Poison \
    Normal Psychic Ghost Ice Dragon Dark Steel Fairy]
  
  set m $menu.filter
  menu $m -tearoff 0
  $menu add cascade -label [mc "Filter"] -menu $m -underline 0
  $m add cascade -label [mc "Type"] -menu $m.type -underline 0
  $m add check -label [mc "Final stage"] -variable sta
  $m add check -label [mc "No legendaries"] -variable leg
  $m add command -label [mc "Clear filters"] \
    -command [list clear_abil_filters $m $types sta leg]
  
  menu $m.type -tearoff 0
  foreach type $types {
    $m.type add check -label [mc $type] -variable $type
  }
  
  $w configure -menu $menu
  
  ### Clear ability filters
  proc clear_abil_filters {m types args} {
    global sta leg Grass Fire Water Bug Flying Electric Ground Rock Fighting Poison Normal Psychic Ghost Ice Dragon Dark Steel Fairy
    foreach n $args {
      if {[set $n] == 1} {
        $m invoke [lsearch $args $n]
      }
    }
    foreach n $types {
      if {[set $n] == 1} {
        $m.type invoke [lsearch $types $n]
      }
    }
  }
  
  grid [ttk::frame $w.desc] -row 0 -column 0 -sticky nw
  grid [ttk::frame $w.lab] -row 1 -column 0 -sticky nw
  grid [ttk::frame $w.list -height 200 -width 800] -row 2 -column 0 -sticky nw
  
  label $w.desc.abil -text $ability -padx 10 -pady 10
  label $w.desc.desc -text $desc -wraplength 800 -padx 10 -pady 10 -justify left
  label $w.lab.lab -text [mc "Pok\u00E9mon that can have this ability:"] -padx 10
  populate_ability $w.list "%$ability%"
  grid $w.desc.abil -row 0 -column 0 -sticky nw
  grid $w.desc.desc -row 0 -column 1 -sticky nw
  grid $w.lab.lab -row 0 -column 0 -sticky nw
  grid columnconfigure $w.desc 0 -minsize 100
  grid columnconfigure $w.desc 1 -minsize 700
  
  focus .ability
}

### Populate the ability window
proc populate_ability {w ability} {
  global pokeDir
  text $w.cont -relief flat -background "#F0F0F0" -yscrollcommand "$w.scroll set"
  scrollbar $w.scroll -relief sunken -orient vertical -command "$w.cont yview"
  grid $w.cont $w.scroll -sticky nsew
  grid columnconfigure $w 0 -minsize 800
  set datagroup [dex eval {SELECT id, pokemon FROM pokeDetails \
    WHERE ability LIKE $ability OR hability LIKE $ability}]
  set id 0
  set filelist [glob -directory "$pokeDir/data/icons" *]
  foreach {n m} $datagroup {
    set num [string trimleft $n "#"]
    if {![catch {image create photo abil$id -file "$pokeDir/data/icons/$num.png"\
      -format png}]} {
      button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
        -overrelief flat -command "poke_populate_sub $w $m" -cursor hand2
      $w.cont window create end -window $w.cont.$id
    }
    incr id
  }
}

### Procedure to link to pokemon with same egg group
proc egg_link {egg} {
  set datagroup [dex eval {SELECT pokemon FROM pokeDetails WHERE egggroup = $egg}]
  catch {destroy .egggroup}
  set w .egggroup
  toplevel $w
  wm title $w "Egg Group: $egg"

  set menu $w.eggmenu
  menu $menu -tearoff 0
  
  set m $menu.tool
  menu $m -tearoff 0
  $menu add cascade -label [mc "Tools"] -menu $m  -underline 0
  $m add command -label [mc "Add column"] -command {} \
    -accelerator Ctrl+N
  $m add command -label [mc "Remove last column"] -command {} \
    -accelerator Ctrl+Shift+N
  $m add command -label [mc "Remove selected columns"] -command {} \
    -accelerator Ctrl+D
  
  bind $w <Control-KeyPress-N> {error "just testing"}
  bind $w <Control-Shift-KeyPress-N> {error "just testing"}
  bind $w <Control-KeyPress-D> {error "just testing"}
  
  $w configure -menu $menu

  grid [ttk::frame $w.lab] -row 0 -column 0 -sticky nw
  grid [ttk::frame $w.list -height 600 -width 800] -row 2 -column 0 -sticky nw
  
  label $w.lab.lab -text [mc "Pok\u00E9mon that are in the same egg group:"] -padx 10
  populate_egggroup $w.list "%$egg%"
  grid $w.lab.lab -row 0 -column 0 -sticky nw
  grid columnconfigure $w.list 0 -minsize 800
  
  focus .egggroup
}

### Populate the egg group window
proc populate_egggroup {w egg} {
  global pokeDir
  text $w.cont -relief flat -background "#F0F0F0" -yscrollcommand "$w.scroll set"
  scrollbar $w.scroll -relief sunken -orient vertical -command "$w.cont yview"
  grid $w.cont $w.scroll -sticky nsew
  grid columnconfigure $w 0 -minsize 800
  set datagroup [dex eval {SELECT id, pokemon FROM pokeDetails WHERE egggroup LIKE $egg}]
  set id 0
  set filelist [glob -directory "$pokeDir/data/icons" *]
  foreach {n m} $datagroup {
    set num [string trimleft $n "#"]
    if {![catch {image create photo abil$id -file "$pokeDir/data/icons/$num.png"\
      -format png}]} {
      button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
        -overrelief flat -command "poke_populate_sub $w $m" -cursor hand2
      $w.cont window create end -window $w.cont.$id
    }
    incr id
  }
}

proc poke_populate_sub {w pokemon} {
  poke_populate $pokemon
  wm withdraw [winfo parent $w]
}
