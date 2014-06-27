### Run only when sourced
if {[info exists argv0] && [file tail $argv0] ne "main.tcl"} {
  tk_messageBox -title Error \
    -message "This script should be run from the main.tcl script"
  return
}

### Load database and create it
sqlite3 dex pokedexdb

### Populate database if files were updated
proc create_database {pokeDir gen poke move ability match} {
  set pokeDetails "pokeDetails$gen"
  set moveDetails "moveDetails$gen"
  set abilDetails "abilDetails$gen"
  set matcDetails "matcDetails$gen"
  if {$poke} {
    dex eval "DROP TABLE IF EXISTS $pokeDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${pokeDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        pokemon text,
        formname text,
        type text,
        genus text,
        ability1 text,
        ability2 text,
        hability text,
        gender text,
        egggroup text,
        height float,
        weight float,
        legend bool,
        evolve_cond text,
        hp int,
        atk int,
        def int,
        spatk int,
        spdef int,
        spd int,
        capture int,
        final bool,
        stage int,
        effort int,
        hatch_counter int,
        happiness int,
        exp int,
        forms int,
        colour text,
        base_exp int
      )
    "
    set f [open [file join $pokeDir data gen$gen info] r]
    set code "dex eval {
      INSERT INTO $pokeDetails VALUES(
        \$id,
        \$pokemon,
        \$formname,
        \$type,
        \$genus,
        \$ability1,
        \$ability2,
        \$hability,
        \$gender,
        \$egggroup,
        \$height,
        \$weight,
        \$legend,
        \$evolve_cond,
        \$hp,
        \$atk,
        \$def,
        \$spatk,
        \$spdef,
        \$spd,
        \$capture,
        \$final,
        \$stage,
        \$effort,
        \$hatch_counter,
        \$happiness,
        \$exp,
        \$forms,
        \$colour,
        \$base_exp
      )
    }"
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] id pokemon formname type genus ability1 ability2 \
        hability gender egggroup height weight legend evolve_cond hp atk def spatk \
        spdef spd capture final stage effort hatch_counter happiness exp forms \
        colour base_exp
      eval $code
    }
    close $f
    #dex copy ignore $pokeDetails [file join $pokeDir data gen$gen info] "\t"
  }
  
  if {$move} {
    dex eval "DROP TABLE IF EXISTS $moveDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${moveDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        type text,
        class text,
        pp int,
        basepower int,
        accuracy int,
        priority int,
        effect text,
        contact bool,
        charging bool,
        recharge bool,
        detectprotect bool,
        reflectable bool,
        snatchable bool,
        mirrormove bool,
        punchbased bool,
        sound bool,
        gravity bool,
        defrosts bool,
        range int,
        heal bool,
        infiltrate bool
      )
    "
    set f [open [file join $pokeDir data gen$gen moves] r]
    set code "dex eval {
      INSERT INTO $moveDetails VALUES(
        \$id,
        \$type,
        \$class,
        \$pp,
        \$basepower,
        \$accuracy,
        \$priority,
        \$effect,
        \$contact,
        \$charging,
        \$recharge,
        \$detectprotect,
        \$reflectable,
        \$snatchable,
        \$mirrormove,
        \$punchbased,
        \$sound,
        \$gravity,
        \$defrosts,
        \$range,
        \$heal,
        \$infiltrate
      )
    }"
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] id type class pp basepower accuracy priority \
        effect contact charging recharge detectprotect reflectable snatchable \
        mirrormove punchbased sound gravity defrosts range heal infiltrate
      eval $code
    }
    close $f
    #dex copy ignore $moveDetails [file join $pokeDir data gen$gen moves] "\t"
  }
  
  if {$ability} {
    dex eval "DROP TABLE IF EXISTS $abilDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${abilDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        description text
      )
    "
    set f [open [file join $pokeDir data gen$gen abilities] r]
    set code "dex eval {
      INSERT INTO $abilDetails VALUES(
        \$id,
        \$description
      )
    }"
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] id description
      eval $code
    }
    close $f
    #dex copy ignore $abilDetails [file join $pokeDir data gen$gen abilities] "\t"
  }
  
  if {$match} {
    dex eval "DROP TABLE IF EXISTS $matcDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${matcDetails}(
        type1 text,
        type2 text,
        effectiveness float
      )
    "
    set f [open [file join $pokeDir data gen$gen matchup] r]
    set code "dex eval {
      INSERT INTO $matcDetails VALUES(
        \$type1,
        \$type2,
        \$effectiveness
      )
    }"
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] type1 type2 effectiveness
      eval $code
    }
    close $f
    #dex copy ignore $matcDetails [file join $pokeDir data gen$gen matchup] "\t"
  }
}

dex eval {
  CREATE TABLE IF NOT EXISTS config (
    param text PRIMARY KEY ON CONFLICT ABORT UNIQUE,
    value text
  )
}

if {![dex exists {SELECT 1 FROM config}]} {
  set pokeDate [file mtime [file join $pokeDir data gen6 info]]
  set moveDate [file mtime [file join $pokeDir data gen6 moves]]
  set abilDate [file mtime [file join $pokeDir data gen6 abilities]]
  dex eval {
    INSERT INTO config (param, value) VALUES
      ('poke', $pokeDate),
      ('move', $moveDate),
      ('ability', $abilDate),
      ('abilitydef', 0),
      ('gen', 6),
      ('language', 'English'),
      ('matchup', 0),
      ('matchuphide', 1)
  }
  create_database $pokeDir 6 1 1 1 1
  dex eval {
    CREATE TABLE types(
      type text,
      gen int,
      colour text
    )  
  }
  set f [open [file join $pokeDir data types] r]
  while {[gets $f line] != -1} {
    lassign [split $line "\t"] type gen colour
    dex eval {
      INSERT INTO types VALUES(
        $type,
        $gen,
        $colour
      )
    }
  }
  close $f
  #dex copy ignore types [file join $pokeDir data types] "\t"
  dex eval {
    CREATE TABLE itypes(
      type1 text,
      type2 text,
      gen int
    )
  }
  set f [open [file join $pokeDir data itypes] r]
  while {[gets $f line] != -1} {
    lassign [split $line "\t"] type1 type2 gen
    dex eval {
      INSERT INTO types VALUES(
        $type1,
        $type2,
        $gen
      )
    }
  }
  close $f
  #dex copy ignore itypes [file join $pokeDir data itypes] "\t"
  $note select 5
} else {
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set pokeDate [file mtime [file join $pokeDir data gen$gen info]]
  set moveDate [file mtime [file join $pokeDir data gen$gen moves]]
  set abilDate [file mtime [file join $pokeDir data gen$gen abilities]]
  
  lassign [list 0 0 0] poke move ability
  set timestamp [dex eval {
    SELECT param, value FROM config WHERE param IN ('poke', 'move', 'ability')
  }]
  foreach {p v} $timestamp {
    switch $p {
      poke {
        if {$pokeDate == $v} {continue}
        dex eval {UPDATE config SET value = $pokeDate WHERE param = $p}
        incr poke
      }
      move {
        if {$moveDate == $v} {continue}
        dex eval {UPDATE config SET value = $moveDate WHERE param = $p}
        incr move
      }
      ability {
        if {$abilDate == $v} {continue}
        dex eval {UPDATE config SET value = $abilDate WHERE param = $p}
        incr ability
      }
      default {}
    }
    if {[expr {$poke+$move+$ability}] == 3} {break}
  }
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  $menu.file.gen invoke [expr {$gen-1}]
  $note select [expr {$gen-1}]
  create_database $pokeDir $gen $poke $move $ability 0
}
