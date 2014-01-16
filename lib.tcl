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
  set pokemon [lindex $pokeList [$entry curselection]+1]
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

proc poke_showlist {entry pokeList text} {
  if {![winfo exists .sidepane.top.listbox]} {
    set miniList [lsearch -all -inline -nocase $pokeList $text*]
    if {[llength $miniList] < 2} {
      lb_remove
      return 0
    }
    catch {destroy [winfo children .mainpane.note.gen1]}
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
    bind $lb <Motion> "poke_hover %W %x %y"
    bind $lb <ButtonPress-1> [list lb_populate_entry %W $miniList]
    
    return 1
  } else {
    destroy .sidepane.top.listbox
    poke_showlist $entry $pokeList $text
  }
}

proc lb_remove {} {
  if {[winfo exists .sidepane.top.listbox]} {
    wm withdraw .sidepane.top.listbox
    destroy .sidepane.top.listbox
    ttk::releaseGrab .sidepane.top.listbox.l
    grab release .sidepane.top.listbox.l
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

proc poke_populate {pokemon} {
  set w .mainpane.note
  catch {destroy [winfo children $w.gen1]}
  catch {destroy [winfo children $w.gen2]}
  catch {destroy [winfo children $w.gen3]}
  catch {destroy [winfo children $w.gen4]}
  catch {destroy [winfo children $w.gen5]}
  catch {destroy [winfo children $w.gen6]}
  
  if {[winfo exists .sidepane.top.listbox]} {lb_remove}
  poke_populate_gen6 $w $pokemon
}

proc poke_focus {pokeList} {
  if {[.sidepane.top.entry get] == ""} {return}
  set text [string range [.sidepane.top.entry get] 0 [.sidepane.top.entry index insert]-1]
  if {[poke_showlist .sidepane.top.entry $pokeList $text]} {
    focus .sidepane.top.listbox.l
    ttk::globalGrab .sidepane.top.listbox.l
  }
}

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

proc animate_poke {w images interval} {
  if {[catch {$w configure -image}]} {
    pack [label $w -bd 0 -image [lindex $images 0]]
  }
  set img [lindex [$w configure -image] end]
  
  set idx [lsearch $images $img]
  incr idx
  if {$idx > [llength $images]-1} {
    set idx 0
  }
  if {[catch {$w configure -image [lindex $images $idx]}]} {return}
  after $interval "animate_poke $w \"$images\" $interval"
}

proc poke_populate_gen6 {w pokemon} {
  global framesGen6 pokeDir
  if {[info exists framesGen6]} {
    foreach n $framesGen6 {rename $n {}}
  }
  set framesGen6 [get_frames "$pokeDir/data/sprites-6/$pokemon.gif"]
  set framesGen6 [lreplace $framesGen6 end end]
  if {![winfo exists $w.gen6.l]} {
    pack [label $w.gen6.l -bd 0 -image [lindex $framesGen6 0]]
  }
  after idle "animate_poke $w.gen6.l \"$framesGen6\" 28"
}