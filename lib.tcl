### Run only when sourced
if {[info exists argv0] && [file tail $argv0] ne "main.tcl"} {
  tk_messageBox -title Error \
    -message "This script should be run from the main.tcl script"
  return
}

### Update config
proc write_config {state param} {
  dex eval {UPDATE config SET value = $state WHERE param = $param}
}

### Position Window
proc sub_position {w args} {
  if {$args == ""} {
    wm geometry $w +50+50
  } else {
    wm geometry $w $args
  }
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
    .sidepane.top.entry icursor end
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
    
    # Default height of listbox is 10
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
    
    bind $lb <KeyPress-Return> [list lb_populate_entry %W $miniList]
    bind $lb <ButtonPress-1> [list lb_populate_entry %W $miniList]
    bind $lb <Motion> [list poke_hover %W %x %y]
    bind $lb <KeyPress-Escape> {lb_remove}
    bind $entry <KeyPress-Escape> {lb_remove}
    bind all <ButtonPress-1> {lb_remove}
    ttk::globalGrab $lb
    return 1
  } else {
    destroy .sidepane.top.listbox
    poke_showlist $entry $pokeList $text
  }
}

### Removing the popup window
proc lb_remove {} {
  set w .sidepane.top
  if {[winfo exists $w.listbox]} {
    wm withdraw $w.listbox
    destroy $w.listbox
    ttk::releaseGrab $w.listbox.l
    grab release $w.listbox.l
    focus -force $w.entry
  }
}

### Put selection from popup into entry box
proc lb_populate_entry {lb mini} {
  if {![catch {set pokemon [lindex $mini [$lb curselection]]}]} {
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    .sidepane.top.entry icursor end
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
  
  # Increment index by 1 since lists are 0 based
  incr idx
  #poke_populate_gen1 $w $idx
  #poke_populate_gen2 $w $idx
  #poke_populate_gen3 $w $idx
  #poke_populate_gen4 $w $idx
  #poke_populate_gen5 $w $idx
  poke_populate_gen6 $w [format %03d $idx]
}

### Focus on popup when down arrow pressed
proc poke_focus {pokeList} {
  if {[.sidepane.top.entry get] eq ""} {return}
  set text [string range [.sidepane.top.entry get] 0 \
    [.sidepane.top.entry index insert]-1]
  if {[poke_showlist .sidepane.top.entry $pokeList $text]} {
    focus .sidepane.top.listbox.l
  }
}

### Get all frames of gif file
proc get_frames {image} {
  set idx 0
  set results [list]
  while {1} {
    if {[catch {image create photo -file $image -format "gif \
      -index $idx"} res]} {
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
  if {$interval eq ""} {return}
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
  if {$time eq ""} {return}
  scan $time %x dec
  return [expr {$dec*10}]
}

### Fill main pane with details of Pokémon
proc poke_populate_gen1 {w idx} {
  global pokeDir
  
  catch {image create photo gen1Sprite -format png \
    -file [file join $pokeDir data gen1 sprites $idx.png]} res
  $w.gen1.sprite configure -image gen1Sprite  
  
  # Populate details
  #info_populate $w $idx
}

proc poke_populate_gen2 {w idx} {
  global pokeDir
  
  catch {image create photo gen2Sprite -format png \
    -file [file join $pokeDir data gen2 sprites $idx.png]} res
  $w.gen2.sprite configure -image gen2Sprite  
  
  # Populate details
  #info_populate $w $idx
}

proc poke_populate_gen3 {w idx} {
  global pokeDir
  
  catch {image create photo gen3Sprite -format png \
    -file [file join $pokeDir data gen3 sprites $idx.png]} res
  $w.gen3.sprite configure -image gen3Sprite  
  
  # Populate details
  #info_populate $w $idx
}

proc poke_populate_gen4 {w idx} {
  global pokeDir
  
  catch {image create photo gen4Sprite -format png \
    -file [file join $pokeDir data gen4 sprites $idx.png]} res
  $w.gen4.sprite configure -image gen4Sprite  
  
  # Populate details
  #info_populate $w $idx
}

proc poke_populate_gen5 {w idx} {
  global framesGen5 pokeDir
  if {[info exists framesGen5]} {
    foreach n $framesGen5 {rename $n {}}
  }
  set framesGen5 [get_frames [file join $pokeDir data gen5 sprites $idx.gif]]
  set interval [get_fps [file join $pokeDir data gen5 sprites $idx.gif]]

  $w.gen5.sprite configure -image [lindex $framesGen5 0]
  
  after idle "animate_poke $w.gen5.down.sprite \"$framesGen5\" $interval"
  # Populate details
  #info_populate $w $idx
}

proc poke_populate_gen6 {w idx} {
  global framesGen6 pokeDir curIdx
  if {[info exists framesGen6]} {
    foreach n $framesGen6 {rename $n {}}
  }
  set framesGen6 [get_frames [file join $pokeDir data gen6 sprites $idx.gif]]
  set interval [get_fps [file join $pokeDir data gen6 sprites $idx.gif]]
  # Insert first image, then loop through each other images
  $w.gen6.down.sprite configure -image [lindex $framesGen6 0]
  after idle "animate_poke $w.gen6.down.sprite \"$framesGen6\" $interval"
  
  # Check if stats of the female are different. If not, don't change other info
  regexp {^[^-]+} $idx id
  if {!("$idx-f" eq "$curIdx" || "$idx" eq "$curIdx-f") &&
      [llength [dex eval "
        SELECT id FROM pokeDetails6 WHERE id IN ('#$id','#$id-f')
      "]] == 1} {
    info_populate $w "#$idx" 6
  }
  set curIdx $idx
}

### Update tabs
proc tab_update {w idx} {
  foreach {a b} [list 0 151 1 251 2 386 3 493 4 649] {
    if {$idx > $b && [$w tab $a -state] eq "normal"} {
      $w tab $a -state disabled
    } elseif {$idx <= $b && [$w tab $a -state] eq "disabled"} {
      $w tab $a -state normal
    }
  }
}

### Add informations
proc info_populate {w idx i} {
  global pokeDir
  # 2 lines will have to be edited when Gen I-V implemented
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set datagroup [dex eval "SELECT * FROM pokeDetails$gen WHERE id = '$idx'"]
  set megaevos [dex eval "
    SELECT id FROM pokeDetails$gen WHERE id LIKE '$idx%' AND formname LIKE '%Mega%'
  "]
  
  lassign $datagroup id pokemon formname type genus ability1 ability2 hability \
    gender egggroup height weight
  regexp {^[^-]+} $idx id
  
  $w.gen$i.lab configure -text "$id $pokemon"
  
  set info $w.gen$i.down.info
  $info.formvar configure -state normal
  $info.formvar delete 1.0 end
  $info.formvar insert end $formname form
  $info.formvar tag bind form <ButtonPress-1> \
    [list form_menu $info.formvar $id $gen]
  tooltip::tooltip $info.formvar "Click for other forms"
  if {[llength $megaevos] != 0} {
    foreach mega $megaevos {
      set idx [string trimleft $mega #]
      $info.formvar insert end " "
      set $mega [image create photo -file \
        [file join $pokeDir data gen$i stones $idx.png]]
      if {[string first "Mega" $formname] > -1} {
        regexp {\d+} $idx id
        $info.formvar window create end -create [list \
          button %W.$mega -image [set $mega] -relief flat -cursor hand2 \
          -command [list poke_populate_gen$i .mainpane.note $id] \
        ]
      } else {
        $info.formvar window create end -create [list \
          button %W.$mega -image [set $mega] -relief flat -cursor hand2 \
          -command [list poke_populate_gen$i .mainpane.note $idx] \
        ]
      }
    }
  }
  $info.formvar configure -state disabled
  
  $info.typevar configure -state normal
  $info.typevar delete 1.0 end
  $info.typevar insert end $type
  $info.typevar configure -state disabled
  
  $info.genuvar configure -state normal
  $info.genuvar delete 1.0 end
  $info.genuvar insert end $genus
  $info.genuvar configure -state disabled
  
  $info.abilvar configure -state normal
  $info.abilvar delete 1.0 end
  $info.abilvar tag bind main <Any-Enter> \
    [list linkify $info.abilvar main 1]
  $info.abilvar tag bind main <Any-Leave> \
    [list linkify $info.abilvar main 0]
  $info.abilvar tag bind secd <Any-Enter> \
    [list linkify $info.abilvar secd 1]
  $info.abilvar tag bind secd <Any-Leave> \
    [list linkify $info.abilvar secd 0]
  $info.abilvar tag bind hidden <Any-Enter> \
    [list linkify $info.abilvar hidden 1]
  $info.abilvar tag bind hidden <Any-Leave> \
    [list linkify $info.abilvar hidden 0]
  $info.abilvar insert end $ability1 main
  $info.abilvar tag bind main <ButtonPress-1> \
    [list abil_link $ability1]
  if {$ability2 ne ""} {
    $info.abilvar insert end "/"
    $info.abilvar insert end $ability2 secd
    $info.abilvar tag bind secd <ButtonPress-1> \
      [list abil_link $ability2]
  }
  if {$hability ne ""} {
    $info.abilvar insert end "/"
    $info.abilvar insert end $hability hidden
    $info.abilvar tag bind hidden <ButtonPress-1> \
      [list abil_link $hability]
  }
  tooltip::tooltip $info.abilvar "More detail"
  $info.abilvar configure -state disabled
  
  $info.gendvar configure -state normal
  $info.gendvar delete 1.0 end
  if {$gender ne "N/A"} {
    $info.gendvar insert end [lindex [split $gender "/"] 0] male
    $info.gendvar insert end "/"
    $info.gendvar insert end [lindex [split $gender "/"] 1] female
    $info.gendvar insert end " %"
    regexp {\d+} $idx id
    if {[lsearch [glob -tails -directory \
          [file join $pokeDir data gen$i sprites] \
        *] "$id-f.gif"] != -1} {
      $info.gendvar tag bind male <Any-Enter> \
        [list linkify $info.gendvar male 1]
      $info.gendvar tag bind male <Any-Leave> \
        [list linkify $info.gendvar male 0]
      $info.gendvar tag bind female <Any-Enter> \
        [list linkify $info.gendvar female 1]
      $info.gendvar tag bind female <Any-Leave> \
        [list linkify $info.gendvar female 0]
      $info.gendvar tag bind male <ButtonPress-1> \
        [list poke_populate_gen$i .mainpane.note $id]
      $info.gendvar tag bind female <ButtonPress-1> \
        [list poke_populate_gen$i .mainpane.note "$id-f"]
    } else {
      $info.gendvar tag bind male <ButtonPress-1> {}
      $info.gendvar tag bind female <ButtonPress-1> {}
      $info.gendvar tag bind male <Any-Enter> {}
      $info.gendvar tag bind female <Any-Enter> {}
    }
  } else {
    $info.gendvar insert end "N/A"
  }
  $info.gendvar configure -state disabled
  
  $info.egggvar configure -state normal
  $info.egggvar delete 1.0 end
  $info.egggvar tag bind main <Any-Enter> \
    [list linkify $info.egggvar main 1]
  $info.egggvar tag bind main <Any-Leave> \
    [list linkify $info.egggvar main 0]
  $info.egggvar tag bind secd <Any-Enter> \
    [list linkify $info.egggvar secd 1]
  $info.egggvar tag bind secd <Any-Leave> \
    [list linkify $info.egggvar secd 0]
  if {[string first "," $egggroup] == -1} {
    $info.egggvar insert end $egggroup main
    $info.egggvar tag bind main <ButtonPress-1> \
      [list egg_link $egggroup]
  } else {
    lassign [split $egggroup ","] m1 m2
    set m2 [string trim $m2]
    $info.egggvar insert end $m1 main
    $info.egggvar insert end ", "
    $info.egggvar insert end $m2 secd
    $info.egggvar tag bind main <ButtonPress-1> \
      [list egg_link $m1]
    $info.egggvar tag bind secd <ButtonPress-1> \
      [list egg_link $m2]
  }
  tooltip::tooltip $info.egggvar \
    [mc "Pok\u00E9mon in same Egg Group"]
  $info.egggvar configure -state disabled
  
  $info.heigvar configure -state normal
  $info.heigvar delete 1.0 end
  $info.heigvar insert end "$height m"
  $info.heigvar configure -state disabled
  
  $info.weigvar configure -state normal
  $info.weigvar delete 1.0 end
  $info.weigvar insert end "$weight kg"
  $info.weigvar configure -state disabled
  
  # Populate moves here
}

proc form_menu {w idx gen} {
  if {![winfo exists $w.listbox]} {
    set miniList [dex eval "
      SELECT formname FROM pokeDetails$gen
      WHERE (id LIKE '$idx-%' OR id = '$idx')
      AND formname NOT LIKE '%Mega%'"
    ]
    set lb $w.listbox
    
    toplevel $lb
    wm withdraw $lb
    wm overrideredirect $lb 1
    listbox $lb.l -exportselection 0 -selectmode browse -activestyle dotbox \
        -listvariable $miniList
    $lb.l insert 0 {*}$miniList
    $lb.l selection clear 0 end
    $lb.l selection set 0
    $lb.l see 0
    set height [llength $miniList]
    
    if {$height == 1} {
      $lb.l delete 0 end
      $lb.l insert 0 "<None>"
    }
    
    if {$height > [$lb.l cget -height]} {
      scrollbar $lb.s -relief sunken -orient vertical -command "$lb.l yview"
      $lb.l configure -yscrollcommand "$lb.s set"
      grid $lb.s -column 1 -row 0 -sticky nsew
      set height [$lb.l cget -height]
    }
    $lb.l configure -height $height
    
    set x [winfo rootx $w]
    set y [winfo rooty $w]
    set b [winfo width $w]
    set h [winfo height $w]
    set H [winfo reqheight $lb.l]
    if {$y + $h + $H > [winfo screenheight .]} {
      set Y [expr {$y - $H}]
    } else {
      set Y [expr {$y + $h}]
    }
    wm geometry $lb ${b}x${H}+${x}+${Y}
    grid $lb.l -column 0 -row 0 -sticky news
    grid columnconfigure $lb 0 -weight 1
    grid rowconfigure $lb 0 -weight 1
    wm attribute $lb -topmost 1
    wm deiconify $lb
    wm transient $lb .
    raise $lb
    focus -force $lb
    
    bind $lb <KeyPress-Return> [list sel_populate_entry %W $miniList $gen]
    bind $lb <ButtonPress-1> [list sel_populate_entry %W $miniList $gen]
    bind $lb.l <ButtonPress-1> [list sel_populate_entry %W $miniList $gen]
    bind $lb <Motion> [list poke_hover %W %x %y]
    bind $w <KeyPress-Escape> {sel_remove}
    after idle {bind all <ButtonPress-1> {sel_remove}}
    
    $w configure -state normal
    $w tag bind form {} {}
    $w configure -state disabled
    ttk::globalGrab $lb
  } else {
    destroy $w.listbox
    form_menu $w $idx $gen
  }
}

### Removing the selection window
proc sel_remove {} {
  set w .mainpane.note.gen6.down.info.formvar.listbox.l
  if {[winfo exists $w]} {
    set w [winfo parent $w]
    wm withdraw $w
    destroy $w
    ttk::releaseGrab $w.l
    grab release $w.l
    focus .mainpane
  }
  bind all <ButtonPress-1> {}
}

### Update data based on selection
proc sel_populate_entry {w mini gen} {
  if {![catch {set pokemon [lindex $mini [$w curselection]]}]} {
    set idx [dex eval "SELECT id FROM pokeDetails$gen WHERE formname = '$pokemon'"]
    set idx [string map {"#" ""} [lindex $idx 0]]
    poke_populate_gen$gen .mainpane.note $idx
  }
  sel_remove
}

### Add a link formatting to the property
proc linkify {w tag state} {
  set cursor [expr {$state ? "hand2" : "ibeam"}]
  $w tag configure $tag -underline $state
  $w configure -cursor $cursor
}

### Procedure to link to abilities
proc abil_link {ability} {
  global typeList
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set datagroup [dex eval "
    SELECT description FROM abilDetails$gen 
    WHERE id = '$ability'
  "]
  set desc [lindex $datagroup 0]
  catch {destroy .ability [winfo children .ability]}
  set w .ability
  toplevel $w
  wm title $w "[mc "Ability:"] $ability"
  sub_position $w
  
  set menu $w.abilmenu
  menu $menu -tearoff 0

  lassign [list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0] sta leg Grass \
    Fire Water Bug Flying Electric Ground Rock Fighting Poison Normal \
    Psychic Ghost Ice Dragon Dark Steel Fairy
  set localTypes [list gra fir wat bug fly ele gro roc fig poi nor psy \
    gho ice dra dar ste fai]
    
  ### Clear ability filters
  proc clear_abil_filters {m localTypes} {
    upvar sta stage leg legend Grass gra Fire fir Water wat Bug bug Flying \
    fly Electric ele Ground gro Rock roc Fighting fig Poison poi Normal \
    nor Psychic psy Ghost gho Ice ice Dragon dra Dark dar Steel ste Fairy \
    fai
    if {$stage} {$m invoke 1}
    if {$legend} {$m invoke 2}
    
    for {set i 0} {$i < [llength $localTypes]} {incr i} {
      if {[set [lindex $localTypes $i]]} {$m.type invoke $i}
    }
  }
  
  ### Populate the ability window
  proc populate_ability {w ability localTypes} {
    global pokeDir
    upvar sta stage leg legend Grass gra Fire fir Water wat Bug bug Flying \
    fly Electric ele Ground gro Rock roc Fighting fig Poison poi Normal \
    nor Psychic psy Ghost gho Ice ice Dragon dra Dark dar Steel ste Fairy \
    fai gen gene
    $w.cont configure -state normal
    $w.cont delete 1.0 end
    set query ""
    if {$stage} {set query "${query} AND (final = 1)"}
    if {$legend} {set query "${query} AND (legend = 0)"}
    set typeFilter 0
    foreach n $localTypes {
      if {![set $n]} {continue}
      if {!$typeFilter} {
        set query "${query} AND (type LIKE '%$n%'"
        incr typeFilter
      } else {
        set query "${query} OR type LIKE '%$n%'"
      }
    }
    if {$typeFilter} {set query "${query})"}
    set datagroup [dex eval "SELECT id, pokemon FROM pokeDetails$gene 
      WHERE
        (ability1 = '$ability' OR ability2 = '$ability' OR
        hability = '$ability') $query
    "]
    set hidden [dex eval "SELECT id FROM pokeDetails$gene 
      WHERE hability = '$ability' AND
      (ability1 <> '$ability' AND ability2 <> '$ability')"]
    set id 0
    set filelist [glob -directory [file join $pokeDir data icons] *]
    
    foreach {n m} $datagroup {
      if {[lsearch $hidden $n] == -1} {
        set colour "#F0F0F0"
      } else {
        set colour "#D971DF"
      }
      set num [string trimleft $n "#"]
      if {![catch {image create photo abil$id -format png \
        -file [file join $pokeDir data icons $num.png]}]} {
        button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
          -overrelief flat -command "poke_populate_sub $w \"$m\"" \
          -cursor hand2 -background $colour
        $w.cont window create end -window $w.cont.$id
      }
      incr id
    }
    $w.cont configure -state disabled
  }
  
  set m $menu.filter
  menu $m -tearoff 0
  $menu add cascade -label [mc "Filter"] -menu $m -underline 0
  $m add cascade -label [mc "Type"] -menu $m.type -underline 0
  $m add check -label [mc "Final stage"] -variable sta \
    -command [list populate_ability $w.b.note.list $ability $localTypes]
  $m add check -label [mc "No legendaries"] -variable leg \
    -command [list populate_ability $w.b.note.list $ability $localTypes]
  $m add command -label [mc "Clear filters"] \
    -command [list clear_abil_filters $m $localTypes]
  menu $m.type -tearoff 0 
  
  set tab [dex eval {SELECT value FROM config WHERE param = 'abilitydef'}]
  menu $menu.settings -tearoff 0
  $menu add cascade -label [mc "Settings"] -menu $menu.settings -underline 0
  $menu.settings add radio -label "Default to description tab" -variable tab \
    -value 0 -command {write_config 0 "abilitydef"}
  $menu.settings add radio -label "Default to list tab" -variable tab \
    -value 1 -command {write_config 1 "abilitydef"}
  $menu.settings invoke $tab
  
  $w configure -menu $menu
    
  grid [frame $w.desc] -row 0 -column 0 -sticky nsew
  grid [frame $w.b] -row 1 -column 0 -sticky nsew
  grid columnconfigure $w 0 -weight 1
  grid rowconfigure $w 1 -weight 1
  
  ttk::notebook $w.b.note
  pack $w.b.note -fill both -expand 1
  ttk::notebook::enableTraversal $w.b.note
  
  $w.b.note add [frame $w.b.note.desc] -text "In-depth description"
  $w.b.note add [frame $w.b.note.list] -text "Pok\u00E9mon list"
  
  foreach type $typeList {
    $m.type add check -label [mc $type] -variable $type \
      -command [list populate_ability $w.b.note.list $ability $localTypes]
  }
  if {$tab} {$w.b.note select 1}
  
  label $w.desc.abil -text $ability -padx 10 -pady 10 -anchor w
  label $w.desc.desc -text $desc -wraplength 800 -padx 10 -pady 10 \
    -justify left -anchor w
    
  text $w.b.note.list.cont -relief flat -background "#F0F0F0" \
    -yscrollcommand "$w.b.note.list.scroll set"
  scrollbar $w.b.note.list.scroll -relief sunken -orient vertical \
    -command "$w.b.note.list.tcont yview"
  grid $w.b.note.list.cont $w.b.note.list.scroll -sticky nsew
  grid columnconfigure $w.b.note.list 0 -minsize 800 -weight 1
  grid rowconfigure $w.b.note.list 0 -weight 1
  
  clear_abil_filters $m $localTypes
  populate_ability $w.b.note.list $ability $localTypes
  
  grid $w.desc.abil -row 0 -column 0 -sticky nsew
  grid $w.desc.desc -row 0 -column 1 -sticky nsew
  grid columnconfigure $w.desc 0 -minsize 100 -weight 0
  grid columnconfigure $w.desc 1 -minsize 700 -weight 1
  grid rowconfigure $w.desc 1 -weight 1
}

### Procedure to link to pokemon with same egg group
proc egg_link {egg} {
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set datagroup [dex eval "
    SELECT pokemon FROM pokeDetails$gen WHERE egggroup = '$egg'
  "]
  catch {destroy .egggroup [winfo children .egggroup]}
  set w .egggroup
  toplevel $w
  wm title $w "Egg Group: $egg"
  sub_position $w
  
  set menu $w.eggmenu
  menu $menu -tearoff 0
  
  set m $menu.tool
  menu $m -tearoff 0
  $menu add cascade -label [mc "Tools"] -menu $m  -underline 0
  $m add command -label [mc "Add column"] -command {} -accelerator Ctrl+N
  $m add command -label [mc "Remove last column"] -command {} \
    -accelerator Ctrl+Shift+N
  $m add command -label [mc "Remove selected columns"] -command {} \
    -accelerator Ctrl+D
  
  bind $w <Control-KeyPress-N> {error "just testing"}
  bind $w <Control-Shift-KeyPress-N> {error "just testing"}
  bind $w <Control-KeyPress-D> {error "just testing"}
  $w configure -menu $menu

  ### Populate the egg group window
  proc populate_egggroup {w egg} {
    global pokeDir
    upvar gen gene
    text $w.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.scroll set"
    scrollbar $w.scroll -relief sunken -orient vertical \
      -command "$w.cont yview"
    grid $w.cont $w.scroll -sticky nsew
    grid columnconfigure $w 0 -minsize 800 -weight 1
    grid rowconfigure $w 0 -weight 1
    
    set datagroup [dex eval "
      SELECT id, pokemon FROM pokeDetails$gene WHERE egggroup LIKE '%$egg%'
    "]
    set id 0
    set filelist [glob -directory [file join $pokeDir data icons] *]
    foreach {n m} $datagroup {
      set num [string trimleft $n "#"]
      if {![catch {image create photo abil$id -format png \
        -file [file join $pokeDir data icons $num.png]}]} {
        button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
          -overrelief flat -command "poke_populate_sub $w $m" -cursor hand2
        $w.cont window create end -window $w.cont.$id
      }
      incr id
    }
  }

  pack [frame $w.b -height 600 -width 800] -fill both -expand 1
  
  ttk::notebook $w.b.note
  pack $w.b.note -fill both -expand 1
  ttk::notebook::enableTraversal $w.b.note
  
  $w.b.note add [frame $w.b.note.list -height 200 -width 800] \
    -text "Pok\u00E9mon list"
  $w.b.note add [frame $w.b.note.chain -height 200 -width 800] \
    -text "Breed chain"
  populate_egggroup $w.b.note.list "%$egg%"
}

proc poke_populate_sub {w pokemon} {
  .sidepane.top.entry delete 0 end
  .sidepane.top.entry insert 0 $pokemon
  poke_populate $pokemon
  wm withdraw [winfo toplevel $w]
}

### Procedure for synchronous scrolling.
proc sync_scroll {w args} {
  foreach {c dir} $w {$c $dir {*}$args}
}

### Procedure for calculating combinations
proc binom {n k} {
  set up [list $n]
  set down [list 1]
  for {set i 2} {$i <= $k} {incr i} {
    if {[set id [lsearch $up $i]] != -1} {
      set up [lreplace $up $id $id]
    } else {
      lappend down $i
    }
    if {[set id [lsearch $down [expr {$n-$i+1}]]] != -1} {
      set down [lreplace $down $id $id]
    } else {
      lappend up [expr {$n-$i+1}]
    }
  }
  set res 1
  foreach m $up d $down {
    set res [expr {$res*$m/$d}]
  }
  return $res
}
