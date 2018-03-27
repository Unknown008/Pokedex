namespace eval pokelib {
  ### Resize notebook tabs
  proc resize_tabs {} {
    bind .mainpane.note <Configure> {
      set notebookwidth [winfo width .mainpane.note]
      set tabcount [llength [winfo children .mainpane.note]]
      ttk::style configure G.TNotebook.Tab -width [expr {int($notebookwidth/6)/$tabcount}]
      
      foreach i $pokedex::generations {
        set tabcount [llength [winfo children .mainpane.note.gen$i.move.game]]
        ttk::style configure G$i.TNotebook.Tab -width [expr {int($notebookwidth/6)/$tabcount}] \
          -anchor center
      }
    }
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
  proc poke_entry {entry} {
    set pokemon [$entry get [$entry curselection]]
    .sidepane.top.entry delete 0 end
    .sidepane.top.entry insert 0 $pokemon
    poke_populate $pokemon
  }

  ### Pressing enter from list
  proc list_populate_entry {lb pokeList} {
    if {
      ![catch {set pokemon [lindex $pokeList [$lb curselection]]}] &&
      [$lb curselection] ne ""
    } {
      .sidepane.top.entry delete 0 end
      .sidepane.top.entry insert 0 $pokemon
      .sidepane.top.entry icursor end
      poke_populate $pokemon
    }
    focus $lb
  }

  ### Autocomplete of entry box
  proc poke_autocomplete {entry action validation value} {
    if {
      $action == 1 &&
      $value != {} && 
      [set pop [lsearch -inline -nocase $pokedex::pokeList $value*]] != {}
    } {
      set cursorIndex [string length $value]
      $entry delete 0 end
      $entry insert end $pop
      $entry selection range $cursorIndex end
      $entry icursor $cursorIndex
      poke_showlist $entry $pokedex::pokeList $value
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
      
      bind $lb <KeyPress-Return> [list pokelib::lb_populate_entry %W $miniList $entry]
      bind $lb <ButtonPress-1> [list pokelib::lb_populate_entry %W $miniList $entry]
      bind $lb <Motion> [list pokelib::poke_hover %W %x %y]
      bind $lb <KeyPress-Escape> {pokelib::lb_remove}
      bind $entry <KeyPress-Escape> {pokelib::lb_remove}
      bind all <ButtonPress-1> {pokelib::lb_remove}
      ttk::globalGrab $lb
      return 1
    } else {
      lb_remove
      poke_showlist $entry $pokeList $text
    }
  }

  ### Removing the popup window
  proc lb_remove {} {
    set w .sidepane.top
    if {[winfo exists $w.listbox]} {
      wm withdraw $w.listbox
      destroy $w.listbox
      ttk::releaseGrab $w.listbox
      grab release $w.listbox
    }
  }

  ### Put selection from popup into entry box
  proc lb_populate_entry {lb mini entry} {
    if {![catch {set pokemon [lindex $mini [$lb curselection]]}]} {
      $entry delete 0 end
      $entry insert end $pokemon
      $entry delete [string len $pokemon] end
      $entry icursor end
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
    set w .mainpane.note
    
    set idx [lsearch -nocase $pokedex::pokeList $pokemon]
    if {$idx == -1} {return}
    tab_update $w $idx
    
    .sidepane.top.entry selection clear
    .sidepane.top.entry icursor end

    if {[winfo exists .sidepane.top.listbox]} {lb_remove}
    
    # Increment index by 1 since lists are 0 based
    incr idx
    foreach gen $pokedex::generations id $pokedex::lastIDs {
      if {$idx <= $id} {
        poke_populate_gen $w [format %03d $idx] $gen
      }
    }
  }

  ### Focus on popup when down arrow pressed
  proc poke_focus {w pokeList} {
    set current [$w get]
    if {$current eq ""} {return}
    set text [string range $current 0 [$w index insert]-1]
    if {[poke_showlist $w $pokeList $text]} {
      focus .sidepane.top.listbox.l
    }
  }

  ### Get all frames of gif file
  proc get_frames {image} {
    set idx 0
    set results [list]
    while {1} {
      if {
        [catch {image create photo -file $image -format "gif -index $idx"} res]
      } {
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
    after $interval "pokelib::animate_poke $w \"$images\" $interval"
  }

  ### Get frame rate of gif file
  proc get_fps {file} {
    set f [open $file r]
    fconfigure $f -eof {} -translation binary -encoding binary
    set data [read $f]
    close $f
    binary scan $data H* hex
    regexp -nocase -- {0021F904..(..)} $hex - time
    if {$time eq ""} {return}
    scan $time %x dec
    return [expr {$dec*10}]
  }

  ### Fill main pane with details of Pokémon
  proc poke_populate_gen {w idx gen} {
    if {$gen < 6} {
      if {
        [catch {image create photo spriteGen$gen -format png \
        -file [file join $pokedex::pokeDir data gen$gen sprites $idx.png]} err]
      } {
        return
      }
      $w.gen$gen.down.sprite configure -image spriteGen$gen
    } else {
      set file [file join $pokedex::pokeDir data gen$gen sprites $idx.gif]
      if {[file exists $file]} {
        if {[info exists pokedex::framesGen$gen]} {
          foreach n [set ::pokedex::framesGen$gen] {rename $n {}}
        }
        set ::pokedex::framesGen$gen [get_frames $file]
        set interval [get_fps $file]
        
        $w.gen$gen.down.sprite configure -image [lindex [set pokedex::framesGen$gen] 0]
        after idle [list pokelib::animate_poke $w.gen$gen.down.sprite [set pokedex::framesGen$gen] \
          $interval]
      } else {
        if {[winfo exists $w.down.info.formvar.listbox.l]} {
          sel_remove $gen
        }
        tk_messageBox -title Disclaimer-here \
          -message "The sprite of this Pok\u00E9mon has not been obtained yet.\
          If you want to provide one, contact the author of this Pok\u00E9dex."
        image create photo default -format png -file [file join $pokedex::pokeDir data default.png]
        $w.gen$gen.down.sprite configure -image default
      }
    }
    
    set id ""
    regexp {^[^-]+(?=-f)} $idx id
    regexp {^[^-]*} $pokedex::current(idx) cid
    
    set entries [dex eval "
      SELECT id FROM pokeDetails$gen WHERE id IN ('#$id','#$id-f')
    "]
   
    if {
      !(
        ($idx eq $pokedex::current(idx) || $idx eq "$cid-f" || "$id-f" eq $pokedex::current(idx)) &&
        [llength $entries] == 1
      )
    } {
      info_populate $w "#$idx" $gen
    } elseif {[file exists [file join $pokedex::pokeDir data icons $idx.png]]} {
      $w.gen$gen.lab configure -state normal
      $w.gen$gen.lab delete 1.0 1.1
      $w.gen$gen.lab image create 1.0 -image [image create photo -format png \
        -file [file join $pokedex::pokeDir data icons $idx.png]]
      $w.gen$gen.lab configure -state disabled
    }
    
    set pokedex::current(idx) $idx
  }

  ### Update tabs; enable/disable them as necessary
  proc tab_update {w idx} {
    foreach a {0 1 2 3 4 5 6} b $pokedex::lastIDs {
      if {$idx > $b && [$w tab $a -state] eq "normal"} {
        $w tab $a -state disabled
      } elseif {$idx <= $b && [$w tab $a -state] eq "disabled"} {
        $w tab $a -state normal
      }
    }
  }

  ### Add informations
  proc info_populate {w idx i} {
    set datagroup [dex eval "SELECT * FROM pokeDetails$i WHERE id = '$idx'"]
    set megaevos [dex eval "
      SELECT id FROM pokeDetails$i
      WHERE id LIKE '$idx%' AND (formname LIKE 'Mega %' OR formname LIKE 'Primal %')
    "]
    
    lassign $datagroup id pokemon formname type genus ability1 ability2 hability \
      gender egggroup height weight - - - - - - - - - - - - - - - - - - preevos
    regexp {^[^-]+} $idx id
    
    $w.gen$i.lab configure -state normal
    $w.gen$i.lab delete 1.0 end
    $w.gen$i.lab insert end " $id $pokemon"
    if {[file exists [file join $pokedex::pokeDir data icons [string trimleft $idx #].png]]} {
      $w.gen$i.lab image create 1.0 -image [image create photo -format png \
        -file [file join $pokedex::pokeDir data icons [string trimleft $idx #].png]]
    } else {
      regexp {\#\d+} $idx iconidx 
      catch {$w.gen$i.lab image create 1.0 -image [image create photo -format png \
        -file [file join $pokedex::pokeDir data icons [string trimleft $iconidx #].png]]}
    }
    $w.gen$i.lab configure -state disabled
    
    set info $w.gen$i.down.info
    $info.formvar configure -state normal
    $info.formvar delete 1.0 end
    $info.formvar insert end $formname form
    $info.formvar tag bind form <ButtonPress-1> \
      [list pokelib::form_menu $info.formvar $id $i]
    tooltip::tooltip $info.formvar "Click for other forms"
    if {[llength $megaevos] != 0 && $i >= 6} {
      foreach mega $megaevos {
        set midx [string trimleft $mega #]
        $info.formvar insert end " "
        # For earlier gens, there are no megastones; file won't be found
        catch {
          set $mega [image create photo -file \
            [file join $pokedex::pokeDir data gen$i stones $midx.png]]
          if {[regexp {Mega |Primal } $formname]} {
            regexp {\d+} $midx id
            $info.formvar window create end -create [list \
              button %W.$mega -image [set $mega] -relief flat -cursor hand2 \
              -command [list pokelib::poke_populate_gen .mainpane.note $id $i] \
            ]
          } else {
            $info.formvar window create end -create [list \
              button %W.$mega -image [set $mega] -relief flat -cursor hand2 \
              -command [list pokelib::poke_populate_gen .mainpane.note $midx $i] \
            ]
          }
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
      [list pokelib::linkify $info.abilvar main 1]
    $info.abilvar tag bind main <Any-Leave> \
      [list pokelib::linkify $info.abilvar main 0]
    $info.abilvar tag bind secd <Any-Enter> \
      [list pokelib::linkify $info.abilvar secd 1]
    $info.abilvar tag bind secd <Any-Leave> \
      [list pokelib::linkify $info.abilvar secd 0]
    $info.abilvar tag bind hidden <Any-Enter> \
      [list pokelib::linkify $info.abilvar hidden 1]
    $info.abilvar tag bind hidden <Any-Leave> \
      [list pokelib::linkify $info.abilvar hidden 0]
    $info.abilvar insert end $ability1 main
    $info.abilvar tag bind main <ButtonPress-1> \
      [list pokelib::abil_link $ability1]
    if {$ability2 ne ""} {
      $info.abilvar insert end "/"
      $info.abilvar insert end $ability2 secd
      $info.abilvar tag bind secd <ButtonPress-1> \
        [list pokelib::abil_link $ability2]
    }
    if {$hability ne ""} {
      $info.abilvar insert end "/"
      $info.abilvar insert end $hability hidden
      $info.abilvar tag bind hidden <ButtonPress-1> \
        [list pokelib::abil_link $hability]
    }
    tooltip::tooltip $info.abilvar "More detail"
    $info.abilvar configure -state disabled
    
    $info.gendvar configure -state normal
    $info.gendvar delete 1.0 end
    if {$gender ne "N/A"} {
      lassign [split $gender "/"] male female
      $info.gendvar insert end $male male
      $info.gendvar insert end "/"
      $info.gendvar insert end $female female
      $info.gendvar insert end " %"
      regexp {\d+} $idx id
      set sprites [glob -tails -directory \
        [file join $pokedex::pokeDir data gen$i sprites] *]
      if {
        [lsearch $sprites "$id-f.gif"] != -1 &&
        [string first "Mega " $formname] == -1
      } {
        $info.gendvar tag bind male <Any-Enter> \
          [list pokelib::linkify $info.gendvar male 1]
        $info.gendvar tag bind male <Any-Leave> \
          [list pokelib::linkify $info.gendvar male 0]
        $info.gendvar tag bind female <Any-Enter> \
          [list pokelib::linkify $info.gendvar female 1]
        $info.gendvar tag bind female <Any-Leave> \
          [list pokelib::linkify $info.gendvar female 0]
        $info.gendvar tag bind male <ButtonPress-1> \
          [list pokelib::poke_populate_gen .mainpane.note $id $i]
        $info.gendvar tag bind female <ButtonPress-1> \
          [list pokelib::poke_populate_gen .mainpane.note "$id-f" $i]
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
      [list pokelib::linkify $info.egggvar main 1]
    $info.egggvar tag bind main <Any-Leave> \
      [list pokelib::linkify $info.egggvar main 0]
    $info.egggvar tag bind secd <Any-Enter> \
      [list pokelib::linkify $info.egggvar secd 1]
    $info.egggvar tag bind secd <Any-Leave> \
      [list pokelib::linkify $info.egggvar secd 0]
    if {[string first "," $egggroup] == -1} {
      $info.egggvar insert end $egggroup main
      $info.egggvar tag bind main <ButtonPress-1> \
        [list pokelib::egg_link $egggroup]
    } else {
      lassign [split $egggroup ","] m1 m2
      set m2 [string trim $m2]
      $info.egggvar insert end $m1 main
      $info.egggvar insert end ", "
      $info.egggvar insert end $m2 secd
      $info.egggvar tag bind main <ButtonPress-1> \
        [list pokelib::egg_link $m1]
      $info.egggvar tag bind secd <ButtonPress-1> \
        [list pokelib::egg_link $m2]
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
    
    foreach game [lindex $pokedex::games $i-1] {
      # Clear current contents of table
      set f [string tolower $game]
      $w.gen$i.move.game.$f.t delete 0 end
      
      set movetabs [dex eval "
        SELECT name FROM SQLITE_MASTER WHERE type = 'table' AND name LIKE 'ver$game%_moves%'
      "]
      set movetabs [lmap t $movetabs {
        switch -glob $t {
          *Levelup {list $t 1}
          *TMHM    {list $t 2}
          *Tutor   {list $t 3}
          *Egg     {list $t 4}
          *Form    {list $t 5}
        }
      }]
      set movetabs [lsort -index 1 -real $movetabs]
      
      set learnt [list]
      set preevo [list]
      
      set lang [string tolower [lindex [dex eval {
        SELECT value FROM config WHERE param = 'language'
      }] 0]]
      set query "
        SELECT $lang, class, type, pp, basepower, accuracy FROM moveDetails$i
        JOIN moves
        ON moves.id = moveDetails$i.id
        WHERE moveDetails$i.id = :moveid
      "
      foreach tab $movetabs {
        set tab [lindex $tab 0]
        set moveset [split [lindex [dex eval "SELECT moves FROM $tab where id = '$idx'"] 0] { }]
        set preevoset [list]
        foreach pID $preevos {
          lappend preevoset {*}[split [lindex [dex eval "
            SELECT moves FROM $tab where id = '$pID'
          "] 0] { }]
        }
        
        if {$moveset eq "" && [string match {*-*} $idx] && ![string match {*Form*} $tab]} {
          regexp {\#\d+} $idx fidx
          set moveset [split [lindex [dex eval "SELECT moves FROM $tab where id = '$fidx'"] 0] { }]
        }
        if {[string first "Levelup" $tab] > -1} {
          foreach {lvl moveid} $moveset {
            set movedet [dex eval $query]
            if {$lvl eq "0"} {
              set lvl "1"
            }
            $w.gen$i.move.game.$f.t insert end [list {*}$movedet "At level $lvl"]
            lappend learnt $moveid
          }
          foreach {lvl moveid} $preevoset {
            lappend preevo $moveid
          }
        } else {
          foreach moveid $moveset {
            set movedet [dex eval $query]
            switch -glob $tab {
              *TMHM* {set desc "TM/HM"}
              *Tutor* {set desc "Move tutor"}
              *Egg* {set desc "Egg move"}
              *Form* {set desc "Form specific"}
            }
            $w.gen$i.move.game.$f.t insert end [list {*}$movedet $desc]
            lappend learnt $moveid
          }

          foreach moveid $preevoset {
            if {[string first "Egg" $tab] > -1} {
              set movedet [dex eval $query]
              $w.gen$i.move.game.$f.t insert end [list {*}$movedet "Egg move"]
              lappend learnt $moveid
            } else {
              lappend preevo $moveid
            }
          }
        }
      }
      
      foreach moveid $preevo {
        if {$moveid ni $learnt} {
          set movedet [dex eval $query]
          $w.gen$i.move.game.$f.t insert end [list {*}$movedet "Pre-evolution only"]
        }
      }
      
      bind [$w.gen$i.move.game.$f.t bodytag] <Double-ButtonPress-1> {
        lassign [tablelist::convEventFields %W %x %y] w x y
        lassign [split [$w containingcell $x $y] ,] x y
        pokelib::move_link [lindex [$w rowconfigure $x -text] 4 0]
      }
    }
  }

  proc form_menu {w idx gen} {
    if {![winfo exists $w.listbox]} {
      set miniList [dex eval "
        SELECT id, formname FROM pokeDetails$gen
        WHERE 
          (id LIKE '$idx-%' OR id = '$idx')
        AND 
          (
            (formname NOT LIKE 'Mega %' AND formname NOT LIKE 'Primal %')
          OR
            formname = 'Mega Rayquaza'
          )
        "
      ]
      set lb $w.listbox
      
      set miniList [lmap {a b} [lsort -stride 2 -command pokelib::minilist_sort $miniList] {set b}]
      
      toplevel $lb
      wm withdraw $lb
      wm overrideredirect $lb 1
      listbox $lb.l -exportselection 0 -selectmode browse -activestyle dotbox \
        -listvariable $miniList
      $lb.l delete 0 end
      $lb.l insert 0 {*}$miniList
      $lb.l selection clear 0 end
      $lb.l selection set 0
      $lb.l see 0
      set height [llength $miniList]
      
      if {$height == 1} {
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
      
      bind $lb <KeyPress-Return> [list pokelib::sel_populate_entry %W $miniList $gen]
      bind $lb.l <ButtonPress-1> [list pokelib::sel_populate_entry %W $miniList $gen]
      bind $lb <Motion> [list pokelib::poke_hover %W %x %y]
      bind all <KeyPress-Escape> [list pokelib::sel_remove $gen]
      after idle {
        bind all <ButtonPress-1> {
          if {[lindex [split %W .] end] eq "s"} {
            break
          } else {
            pokelib::sel_remove [lindex [regexp -inline {gen(\d+)} %W] 1]
          }
        }
      }
      
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
  proc sel_remove {gen} {
    set w .mainpane.note.gen$gen.down.info.formvar.listbox.l
    if {[winfo exists $w]} {
      set w [winfo parent $w]
      wm withdraw $w
      ttk::releaseGrab $w.l
      grab release $w.l
      destroy $w
      focus .mainpane
    }
    bind all <ButtonPress-1> {}
  }

  ### Update data based on selection
  proc sel_populate_entry {w mini gen} {
    if {![catch {set pokemon [lindex $mini [$w curselection]]}]} {
      set idx [dex eval "
        SELECT id FROM pokeDetails$gen WHERE formname = '$pokemon'
      "]
      set idx [string map {"#" ""} [lindex $idx 0]]
      poke_populate_gen .mainpane.note $idx $gen
    }
    sel_remove $gen
  }

  ### Add a link formatting to the property
  proc linkify {w tag state} {
    set cursor [expr {$state ? "hand2" : "ibeam"}]
    $w tag configure $tag -underline $state
    $w configure -cursor $cursor
  }

  ### Format description & linkify moves & abilities
  proc desc_format {w text} {
    set text [string map {"  " "\n\n"} $text]
    set tags [list]
    foreach chunk [regexp -all -inline {(?:\[[^\]]+\]|[^\[\]]+)} $text] {
      if {[regexp {\[([a-z]+) \"?([^\"]+)\"?\]} $chunk - type res]} {
        regsub -all { } $type[string tolower $res] "" tag
        if {$tag ni $tags} {
          $w tag bind $tag <Any-Enter> [list pokelib::linkify $w $tag 1]
          $w tag bind $tag <Any-Leave> [list pokelib::linkify $w $tag 0]
          switch $type {
            ability {$w tag bind $tag <ButtonPress-1> [list pokelib::abil_link $res]}
            move    {$w tag bind $tag <ButtonPress-1> [list pokelib::move_link $res]}
          }
          $w tag configure $tag -foreground blue
          lappend tags $tag
        }
        $w insert end $res $tag
      } else {
        $w insert end $chunk
      }
    }
  }

  ### Procedure to link to abilities
  proc abil_link {ability} {
    set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
    set lang [string tolower [lindex [dex eval {
      SELECT value FROM config WHERE param = 'language'
    }] 0]]
    set datagroup [dex eval "
      SELECT abilDetails$gen.flavour, abilDetails$gen.description FROM abilDetails$gen
      JOIN abilities
      ON abilDetails$gen.id = abilities.id
      WHERE abilities.$lang = '$ability'
    "]
    lassign $datagroup flavour desc
    catch {destroy .ability [winfo children .ability]}
    set w .ability
    toplevel $w
    wm title $w "[mc {Ability:}] $ability"
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
    proc populate_ability {w ability localTypes gen} {
      upvar sta stage leg legend Grass gra Fire fir Water wat Bug bug Flying \
      fly Electric ele Ground gro Rock roc Fighting fig Poison poi Normal \
      nor Psychic psy Ghost gho Ice ice Dragon dra Dark dar Steel ste Fairy \
      fai
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
      set datagroup [dex eval "SELECT id, pokemon, type FROM pokeDetails$gen 
        WHERE
          (ability1 = '$ability' OR ability2 = '$ability' OR
          hability = '$ability') $query
      "]
      set hidden [dex eval "SELECT id FROM pokeDetails$gen 
        WHERE hability = '$ability' AND
        (ability1 <> '$ability' AND ability2 <> '$ability')"]
      set id 0
      set filelist [glob -directory [file join $pokedex::pokeDir data icons] *]
      
      set types [list]
      foreach {n m o} $datagroup {
        if {[lsearch $hidden $n] == -1} {
          set colour "#F0F0F0"
        } else {
          set colour "#D971DF"
        }
        set num [string trimleft $n "#"]
        if {![catch {image create photo abil$id -format png \
          -file [file join $pokedex::pokeDir data icons $num.png]}]} {
          button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
            -overrelief flat -command "pokelib::poke_populate_sub $w \"$m\"" \
            -cursor hand2 -background $colour
          $w.cont window create end -window $w.cont.$id
        }
        if {[string first "/" $o] > -1} {
          lassign [split $o "/"] a b
          if {$a ni $types} {lappend types $a}
          if {$b ni $types} {lappend types $b}
        } else {
          if {$o ni $types} {lappend types $o}
        }
        incr id
      }
      if {[expr {[::tcl::mathop::+ {*}[lmap x $localTypes {set x [set $x]}]]}] == 0} {
        for {set i 0} {[llength $pokedex::typeList] > $i} {incr i} {
          if {[lindex $pokedex::typeList $i] ni $types} {
            .ability.abilmenu.filter.type entryconfigure $i -state disabled
          }
        }
      }
      
      $w.cont configure -state disabled
    }
    
    set m $menu.filter
    menu $m -tearoff 0
    $menu add cascade -label [mc "Filter"] -menu $m -underline 0
    $m add cascade -label [mc "Type"] -menu $m.type -underline 0
    $m add check -label [mc "Final stage"] -variable sta \
      -command [list pokelib::populate_ability $w.b.note.list $ability $localTypes $gen]
    $m add check -label [mc "No legendaries"] -variable leg \
      -command [list pokelib::populate_ability $w.b.note.list $ability $localTypes $gen]
    $m add command -label [mc "Clear filters"] \
      -command [list pokelib::clear_abil_filters $m $localTypes]
    menu $m.type -tearoff 0 
    
    set tab [dex eval {SELECT value FROM config WHERE param = 'abilitydef'}]
    menu $menu.settings -tearoff 0
    $menu add cascade -label [mc "Settings"] -menu $menu.settings -underline 0
    $menu.settings add radio -label "Default to description tab" -variable tab \
      -value 0 -command {pokelib::write_config 0 "abilitydef"}
    $menu.settings add radio -label "Default to list tab" -variable tab \
      -value 1 -command {pokelib::write_config 1 "abilitydef"}
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
    
    foreach type $pokedex::typeList {
      $m.type add check -label [mc $type] -variable $type \
        -command [list pokelib::populate_ability $w.b.note.list $ability $localTypes $gen]
    }
    if {$tab} {$w.b.note select 1}
    
    label $w.desc.abil -text $ability -padx 10 -pady 10 -anchor w
    label $w.desc.desc -text $flavour -wraplength 800 -padx 10 -pady 10 \
      -justify left -anchor w
    
    text $w.b.note.desc.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.b.note.desc.scroll set" -padx 10 -pady 10 -wrap word -font TkDefaultFont
    scrollbar $w.b.note.desc.scroll -relief sunken -orient vertical \
      -command "$w.b.note.desc.cont yview"
    grid $w.b.note.desc.cont $w.b.note.desc.scroll -sticky nsew
    grid columnconfigure $w.b.note.desc 0 -minsize 800 -weight 1
    grid rowconfigure $w.b.note.desc 0 -weight 1
    
    desc_format $w.b.note.desc.cont $desc
    $w.b.note.desc.cont configure -state disabled
    
    text $w.b.note.list.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.b.note.list.scroll set"
    scrollbar $w.b.note.list.scroll -relief sunken -orient vertical \
      -command "$w.b.note.list.cont yview"
    grid $w.b.note.list.cont $w.b.note.list.scroll -sticky nsew
    grid columnconfigure $w.b.note.list 0 -minsize 800 -weight 1
    grid rowconfigure $w.b.note.list 0 -weight 1
    
    clear_abil_filters $m $localTypes
    populate_ability $w.b.note.list $ability $localTypes $gen
    
    grid $w.desc.abil -row 0 -column 0 -sticky nsew
    grid $w.desc.desc -row 0 -column 1 -sticky nsew
    grid columnconfigure $w.desc 0 -minsize 100 -weight 0
    grid columnconfigure $w.desc 1 -minsize 700 -weight 1
    grid rowconfigure $w.desc 1 -weight 1
    
    update idletasks
    wm minsize $w [winfo width $w] [winfo height $w]
  }

  ### Procedure to link to moves
  proc move_link {move} {
    set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
    set game [dex eval "SELECT value from config WHERE param = 'gen$gen game'"]
    set lang [string tolower [lindex [dex eval {
      SELECT value FROM config WHERE param = 'language'
    }] 0]]
    set datagroup [dex eval "
      SELECT
        moveDetails$gen.id,
        moveDetails$gen.type,
        moveDetails$gen.class,
        moveDetails$gen.pp,
        moveDetails$gen.basepower,
        moveDetails$gen.accuracy,
        moveDetails$gen.priority,
        moveDetails$gen.effect,
        moveDetails$gen.contact,
        moveDetails$gen.charging,
        moveDetails$gen.recharge,
        moveDetails$gen.detectprotect,
        moveDetails$gen.reflectable,
        moveDetails$gen.snatchable,
        moveDetails$gen.mirrormove,
        moveDetails$gen.punchbased,
        moveDetails$gen.sound,
        moveDetails$gen.gravity,
        moveDetails$gen.defrosts,
        moveDetails$gen.range,
        moveDetails$gen.heal,
        moveDetails$gen.infiltrate
      FROM moveDetails$gen
      JOIN moves
      ON moveDetails$gen.id = moves.id
      WHERE moves.$lang = '$move'
    "]
    lassign $datagroup moveid type class pp basepower accuracy priority desc contact charging \
      recharge detectprotect reflectable snatchable mirrormove punchbased sound gravity defrosts \
      range heal infiltrate
    catch {destroy .move {*}[winfo children .move]}
    set w .move
    toplevel $w
    wm title $w "[mc {Move:}] $move"
    sub_position $w
    
    set menu $w.abilmenu
    menu $menu -tearoff 0

    lassign [list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0] sta leg Grass \
      Fire Water Bug Flying Electric Ground Rock Fighting Poison Normal \
      Psychic Ghost Ice Dragon Dark Steel Fairy
    set localTypes [list gra fir wat bug fly ele gro roc fig poi nor psy \
      gho ice dra dar ste fai]
      
    ### Clear move filters
    proc clear_move_filters {m localTypes} {
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
    
    ### Populate the move window
    proc populate_move {w move localTypes gen game} {
      upvar sta stage leg legend Grass gra Fire fir Water wat Bug bug Flying \
      fly Electric ele Ground gro Rock roc Fighting fig Poison poi Normal \
      nor Psychic psy Ghost gho Ice ice Dragon dra Dark dar Steel ste Fairy \
      fai
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
      
      set movetabs [dex eval "
        SELECT name FROM SQLITE_MASTER
        WHERE type = 'table' AND name LIKE 'ver[lindex $pokedex::games $gen-1 $game]_moves%'
      "]
      set lang [string tolower [dex eval {SELECT value FROM config WHERE param = 'language'}]]
      set moveid [dex eval "SELECT id FROM moves WHERE $lang = '$move'"]
      set tables [list]
      set datagroup [list]
      foreach tab $movetabs {
        regexp {moves(.*)} $tab table
        if {$table ne "movesLevelup"} {
          set results [dex eval "SELECT id FROM $tab WHERE ' ' || moves || ' ' LIKE '% $moveid %'"]
          set moveset [lmap line $results {
            lassign $line id moves
            set id
          }]
        } else {
          set results [dex eval "SELECT * FROM $tab WHERE ' ' || moves || ' ' LIKE '% $moveid %'"]
          set moveset
          foreach {id moves} $results {
            foreach {level move} $moves {
              if {$move == $moveid} {
                lappend moveset $id
                break
              }
            }
          }
        }
        set $table $moveset
        lappend tables $table
        lappend datagroup {*}$moveset
      }
      
      set id 0
      set filelist [glob -directory [file join $pokedex::pokeDir data icons] *]
      
      set mapped [list]
      foreach n [lsort -unique $datagroup] {
        set num [string trimleft $n "#"]
        set main [regexp -inline {^[^-]+} $n]
        if {$main ni $mapped} {
          lappend mapped $main
        } else {
          continue
        }
        if {![catch {image create photo move$id -format png \
          -file [file join $pokedex::pokeDir data icons $num.png]}]} {
          set name [dex eval "SELECT pokemon FROM pokeDetails$gen WHERE id = '$n'"]
          button $w.cont.$id -height 40 -width 40 -image move$id -relief flat \
            -overrelief flat -command "pokelib::poke_populate_sub $w \"$name\"" \
            -cursor hand2 ;#-background $colour
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
      -command [list pokelib::populate_move $w.b.note.list $move $localTypes $gen $game]
    $m add check -label [mc "No legendaries"] -variable leg \
      -command [list pokelib::populate_move $w.b.note.list $move $localTypes $gen $game]
    $m add command -label [mc "Clear filters"] \
      -command [list pokelib::clear_move_filters $m $localTypes]
    menu $m.type -tearoff 0 
    
    set tab [dex eval {SELECT value FROM config WHERE param = 'abilitydef'}]
    menu $menu.settings -tearoff 0
    $menu add cascade -label [mc "Settings"] -menu $menu.settings -underline 0
    $menu.settings add radio -label "Default to description tab" -variable tab \
      -value 0 -command {pokelib::write_config 0 "movedef"}
    $menu.settings add radio -label "Default to list tab" -variable tab \
      -value 1 -command {pokelib::write_config 1 "movedef"}
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
    
    foreach type $pokedex::typeList {
      $m.type add check -label [mc $type] -variable $type \
        -command [list pokelib::populate_move $w.b.note.list $move $localTypes $gen $game]
    }
    if {$tab} {$w.b.note select 1}
    
    label $w.desc.move -text $move -padx 10 -pady 10 -anchor w
    #label $w.desc.desc -text $desc -wraplength 800 -padx 10 -pady 10 -justify left -anchor w
    
    text $w.b.note.desc.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.b.note.desc.scroll set" -padx 10 -pady 10 -wrap word -font TkDefaultFont
    scrollbar $w.b.note.desc.scroll -relief sunken -orient vertical \
      -command "$w.b.note.desc.cont yview"
    grid $w.b.note.desc.cont $w.b.note.desc.scroll -sticky nsew
    grid columnconfigure $w.b.note.desc 0 -minsize 800 -weight 1
    grid rowconfigure $w.b.note.desc 0 -weight 1
    
    desc_format $w.b.note.desc.cont $desc
    $w.b.note.desc.cont configure -state disabled
    
    text $w.b.note.list.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.b.note.list.scroll set"
    scrollbar $w.b.note.list.scroll -relief sunken -orient vertical \
      -command "$w.b.note.list.cont yview"
    grid $w.b.note.list.cont $w.b.note.list.scroll -sticky nsew
    grid columnconfigure $w.b.note.list 0 -minsize 800 -weight 1
    grid rowconfigure $w.b.note.list 0 -weight 1
    
    clear_move_filters $m $localTypes
    populate_move $w.b.note.list $move $localTypes $gen $game
    
    grid $w.desc.move -row 0 -column 0 -sticky nsew
    #grid $w.desc.desc -row 0 -column 1 -sticky nsew
    grid columnconfigure $w.desc 0 -minsize 100 -weight 0
    grid columnconfigure $w.desc 1 -minsize 700 -weight 1
    grid rowconfigure $w.desc 1 -weight 1
    
    update idletasks
    wm minsize $w [winfo width $w] [winfo height $w]
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
    
    bind $w <Control-KeyPress-n> {error "just testing"}
    bind $w <Control-Shift-KeyPress-n> {error "just testing"}
    bind $w <Control-KeyPress-d> {error "just testing"}
    $w configure -menu $menu

    ### Populate the egg group window
    proc populate_egggroup {w egg} {
      upvar gen gen
      $w.cont configure -state normal
      set datagroup [dex eval "
        SELECT id, pokemon FROM pokeDetails$gen WHERE egggroup LIKE '%$egg%'
      "]
      set id 0
      set filelist [glob -directory [file join $pokedex::pokeDir data icons] *]
      foreach {n m} $datagroup {
        set num [string trimleft $n "#"]
        if {
          ![catch {image create photo abil$id -format png \
          -file [file join $pokedex::pokeDir data icons $num.png]}]
        } {
          button $w.cont.$id -height 40 -width 40 -image abil$id -relief flat \
            -overrelief flat -command "pokelib::poke_populate_sub $w $m" -cursor hand2
          $w.cont window create end -window $w.cont.$id
        }
        incr id
      }
      $w.cont configure -state disabled
    }

    pack [frame $w.b -height 600 -width 800] -fill both -expand 1
    
    ttk::notebook $w.b.note
    pack $w.b.note -fill both -expand 1
    ttk::notebook::enableTraversal $w.b.note
    
    $w.b.note add [frame $w.b.note.list -height 200 -width 800] -text "Pok\u00E9mon list"
    $w.b.note add [frame $w.b.note.chain -height 200 -width 800] -text "Breed chain"
    
    text $w.b.note.list.cont -relief flat -background "#F0F0F0" \
      -yscrollcommand "$w.b.note.list.scroll set"
    scrollbar $w.b.note.list.scroll -relief sunken -orient vertical \
      -command "$w.b.note.list.cont yview"
    grid $w.b.note.list.cont $w.b.note.list.scroll -sticky nsew
    grid columnconfigure $w.b.note.list 0 -minsize 800 -weight 1
    grid rowconfigure $w.b.note.list 0 -weight 1
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
  
  ### Procedure for mouse scroll
  proc mouse_scroll {a b d} {
    $a yview scroll [expr {-$d/120}] units
    $b yview scroll [expr {-$d/120}] units
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

  ### Procedure for sorting base power column in tablelist
  # Returns -1 if a < b
  # Returns 0 if a == b
  # Returns 1 if a > b
  proc move_sort {a b} {
    if {[string compare $a $b] == 0} {return 0}
    lassign {0 0} inta intb
    if {[regexp {^[0-9]+$} $a]} {set inta 1}
    if {[regexp {^[0-9]+$} $b]} {set intb 2}
    
    # $inta + $intb =
    # 0 => none are numbers
    # 1 => only inta is number; so $b should be smaller
    # 2 => only intb is number; so $a should be smaller
    # 3 => both are numbers  
    switch [expr {$inta+$intb}] {
      0 {return [expr {$a == "-" ? 1 : -1}]}
      1 {return 1}
      2 {return -1}
      3 {return [expr {$a > $b ? 1 : -1}]}
    }
  }

  ### Procedure for sorting move level learning column in tablelist
  # Returns -1 if a < b
  # Returns 0 if a == b
  # Returns 1 if a > b
  proc levelup_sort {a b} {
    if {[string compare $a $b] == 0} {return 0}
    lassign {0 0} inta intb
    if {[regexp {^At level ([0-9]+)$} $a - vala]} {set inta 1}
    if {[regexp {^At level ([0-9]+)$} $b - valb]} {set intb 1}
    
    # $inta and $intb both equal to 1 => level up, thus compare numeric levels
    # else order normally  
    if {$inta && $intb} {
      return [expr {$vala > $valb ? 1 : -1}]
    } else {
      return [string compare $a $b]
    }
  }

  ### Procedure for sorting forms in listbox selection
  # Returns -1 if a < b
  # Returns 1 if a > b
  proc minilist_sort {a b} {
    set re {\#\d+(-\d+)?}
    regexp $re [lindex $a 0] - ida
    regexp $re [lindex $b 0] - idb
    
    if {$ida eq ""} {
      return -1
    } elseif {$idb eq ""} {
      return 1
    } else {
      return [expr {$ida > $idb ? -1 : 1}]
    }
  }

  ### Procedure to flip an image horizontally
  proc flip_image {img} {
    set temp [image create photo]
    $temp copy $image
    $img blank
    $img copy $temp -shrink -subsample -1 1
    image delete $temp
  }

  ### Proc to calculate damage
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Basic damage
  # Added effects of abilities (e.g. Tough Claws & Super Luck) 
  # Added effects of items (e.g. Fire Gem & Assault Vest)
  # Added effects of field specs (e.g. Sunny Day & Hail)
  # Added effects of moves (e.g. Air Slash, Venoshock, Hidden Power, Gyro Ball & 
  #   Weather Ball)
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  proc calculate_damage {attacker defender field move gen status} {
    lassign $attacker alv batk astat sastat atype abil item
    lassign $defender dlv bdef dstat sdstat dtype abil item
    # batk - boost attack
    proc get_move_power {move gen} {
      # To be updated
      lassign [dex eval "
        SELECT basepower, type, class
        FROM moveDetails$gen
        WHERE id = '$move'
      "] pow type acat
      set other ""
      # pow is base power of move
      # type is type of move
      # acat is boolean; 1 physical, 0 special
      # dcat is boolean; 1 physical, 0 special
      # other has to be handled
      return [list $pow $type [expr {$acat eq "Physical" ? 1 : 0}] \
        [expr {$acat eq "Physical" ? 1 : 0}] $other]
    }
    
    proc get_weakness {move type gen} {
      set mType [dex eval "SELECT type FROM moveDetails$gen WHERE id = '$move'"]
      lassign [split $type "/"] type1 type2
      set eff [dex eval "
        SELECT effectiveness FROM matchDetails$gen
        WHERE (type1 = '$type1' AND type2 = '$mType') OR
              (type1 = '$type2' AND type2 = '$mType')
      "]
      if {[llength $eff] == 1} {
        return $eff
      } else {
        return [expr {[lindex $eff 0]*[lindex $eff 1]}]
      }
    }
    
    lassign [get_move_power $move $gen] pow type acat dcat other
    # Other like boosts power of moves/crit rate
    # acat - attack category
    # dcat - defense category
    
    set atk [expr {$acat ? $astat : $sastat}]
    set def [expr {$dcat ? $dstat : $sdstat}]
    
    set stab [expr {$type in [split $atype "/"] ? 1.5 : 1}]
    
    set weak [get_weakness $move $dtype $gen]
    
    set baseDamage [expr {
      ((($alv+5.0)*$pow*$batk*$atk)/(125*$bdef*$def)+2)*$stab*$weak
    }]
    
    set crate [expr {$gen > 5 ? 1.5 : 2}]
    set baseCritDamage [expr {$baseDamage*$crate}]
    
    # TBD
    switch $field {
      sun {}
      rain {}
      sand {}
      hail {}
      gravity {}
      default {}
    }
    
    set netMinDamage [expr {int($baseDamage*0.85)}]
    set netMaxDamage [expr {int($baseDamage)}]
    set netMinCritDamage [expr {int($baseCritDamage*0.85)}]
    set netMaxCritDamage [expr {int($baseCritDamage)}]
    return "$netMinDamage $netMaxDamage $netMinCritDamage $netMaxCritDamage"
  }

  proc hidden_power_calc {hp atk def spd spA spD} {
    set sumT 0
    set sumD 0
    set i 0
    foreach s [list $hp $atk $def $spd $spA $spD] {
      if {$s % 2} {set sumT [expr {$sumT+(2**$i)}]}
      if {$s % 4 > 1} {set sumD [expr {$sumD+(2**$i)}]}
      incr i
    }
    set resT [expr {$sumT*15/63}]
    set types [list Fighting Flying Poison Ground Rock Bug Ghost Steel Fire Water Grass Electric \
      Psychic Ice Dragon Dark]
    set resD [expr {$sumD*40/63+30}]
    
    return [list [lindex $types $resT] $resD]
  }
}
