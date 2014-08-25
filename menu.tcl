### Run only when sourced
if {[info exists argv0] && [file tail $argv0] ne "main.tcl"} {
  tk_messageBox -title Error \
    -message "This script should be run from the main.tcl script"
  return
}

### Matchup window
proc type_matchup {} {
  global typeList
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
  set hidden [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
  catch {destroy .matchup [winfo children .matchup]}
  
  set w .matchup
  toplevel $w
  wm title $w [mc "Matchup chart"]
  sub_position $w +50+0
  
  switch $gen {
    1 {set px 375}
    6 {set px 450}
    default {set px 425}
  }
  
  set stat [expr {$mode ? "normal" : "disabled"}]

  proc matchup {type} {
    
  }
  
  proc matchup_mode {mode px whiteList types gen otypes} {
    global typeList
    set hidden [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
    dex eval {UPDATE config SET value = $mode WHERE param = 'matchup'}
    
    set f2 .matchup.frame2
    set f3 .matchup.frame3
    set f4 .matchup.frame4
    set menu .matchup.menu.options
    set f $f4.f
    
    if {!$mode} {
      $menu entryconfigure 3 -state disabled
      $menu entryconfigure 4 -state disabled
      $menu entryconfigure 5 -state disabled
      if {[winfo exists $f4.vscroll]} {
        destroy $f4.vscroll
      }
      $f3.c configure -yscrollcommand "" -scrollregion "0 0 0 0"
      $f.c configure -yscrollcommand "" -scrollregion "0 0 0 0"
      bind $f3.c <MouseWheel> {}
      bind $f.c <MouseWheel> {}
      return
    }
    foreach {col val} $types {
      set myTypes($col) $val
    }
    $menu entryconfigure 3 -state normal
    $menu entryconfigure 4 -state normal
    $menu entryconfigure 5 -state normal
    set height $px
    set max [expr {$px+(25*[binom 18 2])}]
    
    $f.c delete mbg2
    $f.c create rectangle 0 $px $px $max -fill white -outline white -tags "mbg2"
    
    set itypes [dex eval {SELECT type1, type2 FROM itypes WHERE gen > $gen}]
    set ilist [list]
    foreach {a b} $itypes {
      lappend ilist [list $a $b]
    }
    
    $f3.c delete aatk
    catch {destroy $f4.vscroll}
    set add [list]
    for {set i 0} {$i < [llength $otypes]} {incr i} {
      for {set j [expr {$i+1}]} {$j < [llength $otypes]} {incr j} {
        set type1 [lindex $otypes $i]
        set type2 [lindex $otypes $j]
        if {[lsearch [array names myTypes] $type1] == -1 ||
            [lsearch [array names myTypes] $type2] == -1 ||
            ([lsearch $ilist [list $type1 $type2]] != -1 && $hidden == 1)
        } {continue}
        $f3.c create rectangle 0 $height 50 [expr {$height+25}] \
          -fill $myTypes($type1) -outline black -tags "aatk $type1$type2"
        $f3.c create rectangle 50 $height 100 [expr {$height+25}] \
          -fill $myTypes($type2) -outline black -tags "aatk $type1$type2"
        if {[lsearch $whiteList $type1] != -1} {
          set fcolour1 white
        } else {
          set fcolour1 black
        }
        if {[lsearch $whiteList $type2] != -1} {
          set fcolour2 white
        } else {
          set fcolour2 black
        }
        $f3.c create text 25 [expr {$height+12}] -text $type1 \
          -justify center -fill $fcolour1 -tags "aatk $type1$type2"
        $f3.c create text 75 [expr {$height+12}] -text $type2 \
          -justify center -fill $fcolour2 -tags "aatk $type1$type2"
        set d -13
        for {set k 0} {$k < [llength $otypes]} {incr k} {
          set defer [lindex $otypes $k]
          set eff [dex eval "
            SELECT effectiveness FROM matcDetails$gen
            WHERE (type1 = '$type1' AND type2 = '$defer') OR
                  (type1 = '$type2' AND type2 = '$defer')
          "]
          set eff [expr {[lindex $eff 0]*[lindex $eff 1]}]
          incr d 25
          $f.c create text $d [expr {$height+12}] -text $eff \
            -justify center -fill black -tags "aatk"
        }
        incr height 25
      }
    }
    scrollbar $f4.vscroll -orient vertical
    $f4.vscroll configure -command "sync_scroll \"$f.c yview $f3.c yview\""
    grid $f4.vscroll -row 0 -column 1 -sticky nsew
    $f3.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 100 $height"
    $f.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 $px $height"
      
    proc mouse_scroll {a b d} {
      $a yview scroll [expr {-$d/120}] units
      $b yview scroll [expr {-$d/120}] units
    }
      
    bind $f3.c <MouseWheel> [list mouse_scroll $f3.c $f.c %D]
    bind $f.c <MouseWheel> [list mouse_scroll $f3.c $f.c %D]
  }
  
  proc hide {px whiteList types gen otypes} {
    upvar hidden hide
    set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
    if {!$mode} {return}
    set hidden [expr {$hide ? 0 : 1}]
    dex eval {UPDATE config SET value = $hide WHERE param = 'matchuphide'}
    matchup_mode 1 $px $whiteList $types $gen $otypes
  }
  
  set whiteList [list Ground Rock Fighting Poison Ghost Dragon Dark]
  set dbtypeList [dex eval {SELECT type, colour FROM types WHERE gen <= $gen}]
  set otypes [list]
  foreach {type colour} $dbtypeList {
    set types($type) $colour
    lappend otypes $type
  }
  
  set menu $w.menu
  menu $menu -tearoff 0
  set m $menu.options
  menu $m -tearoff 0
  $menu add cascade -label [mc "Options"] -menu $m -underline 0
  $m add radio -label "Basic Mode" -variable mode -value 0 \
    -command [list matchup_mode 0 $px $whiteList [array get types] $gen $otypes]
  $m add radio -label "Extended Mode" -variable mode -value 1 \
    -command [list matchup_mode 1 $px $whiteList [array get types] $gen $otypes] 
  $m add separator
  $m add check -label [mc "Add Trick-Or-Treat"] -variable tot \
    -command {matchup tot}
  $m add check -label [mc "Add Forest's Curse"] -variable fc \
    -command {matchup fc}
  $m add check -label [mc "Hide illegal typing"] -variable hidden \
    -command [list hide $px $whiteList [array get types] $gen $otypes]
  $w configure -menu $menu
  
  set f1 [frame $w.frame1]
  grid $f1 -row 0 -column 0 -sticky nsew
  set f2 [frame $w.frame2]
  grid $f2 -row 0 -column 1 -sticky nsew
  set f3 [frame $w.frame3]
  grid $f3 -row 1 -column 0 -sticky nsew
  set f4 [frame $w.frame4]
  grid $f4 -row 1 -column 1 -sticky nsew
  grid rowconfigure $w 1 -weight 1
  
  canvas $f2.c -width $px -height 70 -highlightthickness 0
  pack $f2.c -fill both -expand 1
  $f2.c create rectangle 0 0 $px 20 -outline white -fill white
  $f2.c create text [expr {$px/2}] 0 -text "ATTACKER" -anchor n -justify center
 
  set i -25
  foreach type $typeList {
    incr i 25
    if {[lsearch $otypes $type] == -1} {continue}
    $f2.c create rectangle $i 20 [expr {$i+25}] 70 -fill $types($type) \
      -outline black -tags "atk $type"
    if {[lsearch $whiteList $type] != -1} {
      set fcolour white
    } else {
      set fcolour black
    }
    $f2.c create text [expr {$i+12}] 45 -text $type -justify center \
      -fill $fcolour -angle 90 -tags "ulabels"
  }
  
  canvas $f3.c -width 100 -height $px -highlightthickness 0
  label $f3.l -text "DEFENDER" -wraplength 1 -justify center -background white
  grid $f3.l -row 0 -column 0 -sticky nsew
  grid $f3.c -row 0 -column 1 -sticky nsew
  grid rowconfigure $f3 0 -weight 1
  
  $f3.c create rectangle 0 0 100 $px -fill white -outline white -tags "sbg"

  set f [frame $f4.f]
  canvas $f.c -width $px -height $px -highlightthickness 0
  pack $f.c -expand 1 -fill both
  grid $f -row 0 -column 0 -sticky nsew
  grid rowconfigure $f4 0 -weight 1

  $f.c create rectangle 0 0 $px $px -fill white -outline white -tags "mbg"
  
  set i -25
  foreach type $typeList {
    incr i 25
    if {[lsearch $otypes $type] == -1} {continue}
    $f3.c create rectangle 50 $i 100 [expr {$i+25}] -fill $types($type) \
      -outline black -tags "batk $type"
    if {[lsearch $whiteList $type] != -1} {
      set fcolour white
    } else {
      set fcolour black
    }
    $f3.c create text 75 [expr {$i+12}] -text $type -justify center \
      -fill $fcolour -tags "batk $type"
    set d -13
    for {set n 0} {$n < [llength $otypes]} {incr n} {
      set atker [lindex $otypes $n]
      set eff [dex eval "
        SELECT effectiveness FROM matcDetails$gen
        WHERE type1 = '$atker' AND type2 = '$type'
      "]
      incr d 25
      $f.c create text [expr {$i+12}] $d -text $eff -justify center \
        -fill black -tags "batk"
    }
  }
  $m invoke 5
  $m invoke $mode  
  $m entryconfigure 5 -state $stat
  
  wm maxsize $w 0 [expr {$px+70}]
  wm minsize $w 0 220
  after idle [wm resizable $w 0 1]
}

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
