script "gooso.ash";
since r27315; //item_drops changing from int[item] to float[item]

monster farm_monster; 
location farm_location;
buffer banish_monsters;

boolean[item] ban_items = {
  $item[Tryptophan dart] : true,
  $item[Human Musk] : true,
  $item[Ice House] : true,
};

boolean[skill] ban_skills = {
  $skill[Asdon Martin: Spring-Loaded Front Bumper] : true,
  $skill[Monkey Slap] : true,
  $skill[Bowl a Curveball] : true,
  $skill[Show Your Boring Familiar Pictures] : true,
  $skill[Talk About Politics] : true,  
  $skill[Snokebomb] : true,          
  $skill[Feel Hatred] : true,
  $skill[Reflex Hammer] : true,
  $skill[Show them your ring] : true,
  $skill[Throw Latte on Opponent] : true,
  $skill[Batter Up!] : true,
};

boolean[skill] olfact_likes = {
  $skill[Get a Good Whiff of This Guy] : true,
  $skill[Transcendent Olfaction] : true,
  $skill[Offer Latte to Opponent] : true,
  $skill[Gallapagosian Mating Call] : true,
};

item[location] content_unlockers = {
  $location[Pirates of the Garbage Barges] : $item[one-day ticket to Dinseylandfill],
  $location[the Ice Hotel] : $item[one-day ticket to The Glaciest],
  $location[The Stately Pleasure Dome] : $item[tiny bottle of absinthe],
  $location[The Maelstrom of Lovers] : $item[devilish folio],
  $location[An Incredibly Strange Place (Bad Trip)] : $item[astral mushroom],
  $location[The Deep Dark Jungle] : $item[one-day ticket to Conspiracy Island],
};

string pluralize(int number, string singular, string plural, boolean include_number){
  return `{include_number ? number + " " : ""} {number == 1 ? singular : plural}`;
}

/// ///

boolean use_combat(item it, string ccs) {
  string page = visit_url("inv_use.php?&pwd&which=3&checked=1&whichitem=" + it.to_int());

  if(page.contains_text("You don't have the item you're trying to use")) {
    return false;
  }

  if(page.contains_text("You're fighting")) {
    run_combat(ccs);
  }

  return true;
}

monster[skill] get_used_skill_banishers(location loc) {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[skill] list;
  for(int i = 1; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i - 1]);
    int[monster] invert;
    foreach id, em in get_monsters(loc) {
      invert[em] = id;
    }

    skill sk;
    // Special case handling
    if(banish_data[i] == "pantsgiving") {
      sk = $skill[Talk About Politics];
    } else {
      sk = to_skill(banish_data[i]);
    }
    if(invert contains m && sk.combat) list[sk] = m;
  }

  return list;
}

monster[item] get_used_item_banishers(location loc) {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  // TODO/BUG: Sometimes this property isn't updated?
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[item] list;
  for(int i = 1; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i - 1]);
    int[monster] invert;
    foreach id, em in get_monsters(loc) {
      invert[em] = id;
    }
    item it = to_item(banish_data[i]);
    if(invert contains m && it.combat) list[it] = m;
  }

  return list;
}

skill get_unused_skill_banisher(location loc) {
monster[skill] used = get_used_skill_banishers(loc);

foreach banisher in ban_skills {
  if(!(used contains banisher) && have_skill(banisher)) {

    switch(banisher){
      // blame have_skill >.<
      default:
        return banisher;

      case $skill[Snokebomb]:
        if(get_property("_snokebombUsed").to_int() < 3){
          return banisher;
        } else { return $skill[none]; } 

      case $skill[Batter Up!]:
        if(my_fury() != 5)
          return $skill[none];
    }
  }
}

return $skill[none];
}

item get_unused_item_banisher(location loc) {
  monster[item] used = get_used_item_banishers(loc);

  foreach banisher in ban_items {
    if(!(used contains banisher)) {
      return banisher;
    }
  }

  return $item[none];
}

string combat(int round, monster mon_encountered, string text) {
  
  if(mon_encountered.boss.to_boolean()){
    return "abort \"We encounted a boss!\"";
  }


  if(mon_encountered == farm_monster) {
    print(`We hit a {mon_encountered}!`, "teal");
    // add more copies here kekw
    if(get_property("olfactedMonster").to_monster() != mon_encountered && get_property("_olfactionsUsed") > 0){
      print("Olfacting!", "orange");
      return "skill Transcendent Olfaction; skill Gallapagosian Mating Call; attack";
    }
    
  } else if (banish_monsters.to_string().contains_text(mon_encountered)){

    skill skill_banisher = get_unused_skill_banisher(my_location());
    
    if(skill_banisher != $skill[none]) {
      print(`Banishing with skill {skill_banisher.to_string()}!`, "orange");
      return "skill " + to_string(skill_banisher);
    }

    item item_banisher = get_unused_item_banisher(my_location());

    if(item_amount(item_banisher) > 0) {
      print(`Banishing with item {item_banisher.to_string()}!`, "orange");
      return "item " + to_string(item_banisher);
    }
  
  } else {
    abort("Monster not the farm monster nor monster wanted to banish");
  }

  

  print("We're all set! Laying out drones and attacking!", "orange");
  return "if hasskill emit matter duplicating drones; skill emit matter duplicating drones; endif; skill stuffed mortar shell; use porquoise-handled sixgun;";
}

/// ///

void preadv(){

if(item_amount($item[Autumn-aton]).to_boolean()){
  print("Sending your autumn-aton!", "green");
  cli_execute(`autumnaton send {farm_location}`);
}

if(get_property("lastEncounter") == "Poetic Justice"){
  use_skill(1, $skill[Tongue of the Walrus]);
}


if((have_effect($effect[Everything Looks Yellow]) == 0) && (available_amount($item[Jurassic Parka]).to_boolean())){
  print("Using your free YR!", "green");

  int aa = get_auto_attack();

  cli_execute("parka dilophosaur; equip parka");
  set_auto_attack(0);

  string spit = "skill spit jurassic acid; abort;";   
  adv1(farm_location, -1, spit);
  

  set_auto_attack(aa);
  cli_execute("outfit checkpoint");
} 

if((get_property("sweat") == 100) && (get_property("_sweatOutSomeBoozeUsed") == 3)){
    print("Sweating out some sweat!", "green");
    use_skill($skill[Make Sweat-ade]);
}

// TODO: Wanderer support
}


boolean can_adventure_at_location(location locat){
  foreach loc, ite in content_unlockers{
    if((farm_location == loc) && !can_adventure(loc)){
      print("This location is part of a location you don't have access to! Using a " +ite+ "!", "teal");
      use(1, ite);
    }
  }

  return(can_adventure(locat));
}

void newline(){
  print("");
}

boolean buff_up_item(int amount_to_buff, int turns_to_buff){

  if(item_amount($item[closed-circuit pay phone]).to_boolean()){
    int shadow_water_buff_turns = ceil((turns_to_buff - have_effect($effect[Shadow Waters])) / 30);

    if(get_property("questRufus") != "unstarted"){
      abort("Finish your rufus quest!");
    }

    if(shadow_water_buff_turns < 0){
      shadow_water_buff_turns = 0;
    }

    print(`INFO: Buffing up shadow waters {shadow_water_buff_turns} times!`, "orange");

    set_property("choiceAdventure1500", "2");

    for shadow_water_effect_procs from 0 to shadow_water_buff_turns{
  
      visit_url("inv_use.php?which=3&whichitem=11169&pwd"); 
      run_choice(3); 
      
      visit_url("inv_use.php?which=3&whichitem=11169&pwd"); 
      run_choice(1); 
      
      if(item_amount($item[Rufus's shadow lodestone]) > 0){ 
        adv1($location[Shadow Rift (The Right Side of the Tracks)], -1, "abort"); 
      } 
    }
  }

  set_location($location[The Sleazy Back Alley]);
  
  while(amount_to_buff > numeric_modifier("Item Drop")){
    cli_execute(`gain {amount_to_buff} item {turns_to_buff} turns`);
  }
  // TODO: Blacklist bubble potion

  return (numeric_modifier("Item Drop") > amount_to_buff);
}

print("Usage: goosefarm {turns}, {item to farm}", "orange");

void main(string settings){

if((settings == "") && (get_property("goosefarm_choice") != "")){
  print(`Using last used value of {get_property("goosefarm_choice")}`);
  settings = get_property("goosefarm_choice");
} else { set_property("goosefarm_choice", settings); }

string[int] options;
options = split_string(settings, ",");

int turns = options[0].to_int();
item farm_drop = options[1].to_item();

if(farm_drop == $item[none]){
  abort("Please provide a valid item!");
}

// God forgive me for what this is
boolean flag; 
float farm_drop_rate;
int amount_of_drops;
int farm_monsters_in_zone;
monster [int] owo;
float [item] drops;

foreach it in $locations[]{
  owo = get_monsters(it);
  foreach owomid, owom in owo{
    float [item] owod = owom.item_drops();
    foreach owodr, owodrp in owod {
      if(owodr == farm_drop){
        farm_location = it;
        farm_monster = owom;
        farm_drop_rate = owodrp;
        amount_of_drops = owod.count();
        farm_monsters_in_zone = owo.count();
        drops = owod;

        flag = true;
        break;
      }

      if(flag)
        break;
    }
    if(flag)
      break;
  }
  if(flag)
    break;
}


if(farm_drop_rate == 0.0){
  farm_drop_rate = user_prompt(`Item '{farm_drop}' is classified as 0% in KoLMafia's internal database. If this is wrong, please enter the correct drop rate!`).to_float();
}

set_location(farm_location);

int price_of_drop = historical_price(farm_drop);
float item_drop_needed = ((100 / farm_drop_rate) * 100 - 100);
int position_in_drop_table;

print(`INFO: You are farming monster '{farm_monster}' for item '{farm_drop}' at a {farm_drop_rate}% drop rate.`, "orange");
print(`INFO: There are {farm_monsters_in_zone} monsters in the zone for this item, {farm_location}.`, "orange");
print(`INFO: The monster you are trying to fight, '{farm_monster}', has {amount_of_drops} different drops, listed below: `, "orange");
newline();

foreach it in drops{
  print(`INFO: {it}`, "orange");
}

if(amount_of_drops > 1){
  position_in_drop_table = user_prompt("There are more then one drop from your monster in question. Please manually YR the monster you're farming, to see what location the drop is in before entering it in!").to_int();

  if((position_in_drop_table == 0) && (get_property("goosefarm_position_in_drop_table") != "")){
    print(`Using last used value of {get_property("goosefarm_position_in_drop_table")}`);
    position_in_drop_table = get_property("goosefarm_position_in_drop_table").to_int();
  } else { 
    set_property("goosefarm_position_in_drop_table", position_in_drop_table); 
  }

} else {
  position_in_drop_table = 1;
}
newline();

if(position_in_drop_table > 2 || position_in_drop_table == 0){
  abort("Sorry! We don't support drops two or higher in the drop table! (or an invalid input position!)");
} 

if(have_familiar($familiar[Grey goose])){
  use_familiar($familiar[Grey goose]);
}

boolean can_goose = farm_drop.discardable.to_boolean();
string bonus_conditionals = "80 bonus carnivorous potted plant, 100 bonus mafia thumb ring, 60 bonus june cleaver, 60 bonus can of mixed everything, 70 bonus cheengs, 90 bonus lucky gold ring";

/* TODO: CCS lmao
set_property('customCombatScript', ccs_goosefarm);

buffer ccs_goosefarm;
ccs.append("consult goosefarmccs.ash");
// write_ccs(ccs_goosefarm, "goosefarm");
*/

if(!have_effect($effect[Curiosity of Br\'er Tarrypin]).to_boolean()){
  chat_private("Flesh Puppet", "Curiosity of Br " + turns);
  waitq(1);
}

// TODO: Filter out gooseable objects

//if(can_goose){
maximize(`333 familiar experience 10 min 10 max, 0.01 meat, combat 25 max, 0.1 sporadic item drop, item {item_drop_needed} max, {bonus_conditionals}, -tie, -equip kramco, -equip crystal ball, -equip I voted, -equip broken champagne bottle`, false);
/* } else {
  maximize(`item max {item_drop_needed}, {bonus_conditionals}, -tie, -equip kramco, -equip I voted`, false);
}
*/
cli_execute("checkpoint");

print(`INFO: After maximizing, we have {(numeric_modifier("Item Drop") - 100).floor()}/{item_drop_needed.floor()}% item, and {(numeric_modifier("Familiar experience") + 1).floor()}/11 familiar experience!`, "orange");

if(item_drop_needed > numeric_modifier("Item Drop") && farm_drop_rate >= .20){
  print(`WARNING: We were only able to acquire {numeric_modifier("Item Drop")}% item out of the needed {item_drop_needed}% item!`, "red");
  print("Trying to now intelligently buff up item...");

  if(!buff_up_item(item_drop_needed, turns)){
    abort("Failed to reach the item threshold.");
  }
}

if(!have_effect($effect[Musk of the Moose]).to_boolean() && have_skill($skill[Musk of the Moose])) {
  use_skill(turns / 10, $skill[Musk of the Moose]);
}

if(!have_effect($effect[Carlweather's Cantata of Confrontation]).to_boolean() && have_skill($skill[Carlweather's Cantata of Confrontation])) {
  use_skill(turns / 10, $skill[Carlweather's Cantata of Confrontation]);
}


  
if(!equipped_amount($item[cursed monkey's paw]).to_boolean()){
  if(get_property("_monkeyPawWishesUsed") == "0" && !get_property("banishedMonsters").contains_text("Monkey Slap")){
    equip($slot[Acc3], $item[Cursed Monkey's paw]);
  } 
}


int farm_drop_amount_prev = item_amount(farm_drop);
int meat_amount_prev = my_meat();

print(`Spending {turns} turns!`, "teal");
newline();

print("INFO: First, banishing the following monsters! (Preferrably for the entire day)", "orange");

foreach num, mon in owo{
  if(mon != farm_monster){
    print(`{mon}`, "teal");
    append(banish_monsters, `{mon} `);
  }
}

foreach it in $items[Human Musk, Ice House, Tryptophan dart]{
  if (!item_amount(it).to_boolean())
    cli_execute(`acquire {it}`);
}

int entire_day_banishes = (3 + available_amount($item[Cosmic Bowling Ball]) + available_amount($item[Asdon Martin Keyfob]));

if(get_property("_monkeyPawWishesUsed") == "0"){
  entire_day_banishes++;
}

if(farm_monsters_in_zone > entire_day_banishes){
  if(user_confirm("WARNING: You don't have enough entire-day banishes to banish every single mob in the zone! Do you wish to stop?")){
    abort("User abort");
  }
  print("Using multiple limited-time banishes instead!", "teal");
}

while(turns > 1){
  preadv();

  if(!can_adventure_at_location(farm_location)){
    abort("We couldn't handle unlocking or adventuring at this location! Please use the day-pass and rerun!");
  }


  if(!have_effect($effect[Curiosity of Br\'er Tarrypin]).to_boolean()){
    chat_private("Flesh Puppet", "Curiosity of Br " + turns);
    waitq(1);
  }

  if(item_drop_needed > numeric_modifier("Item Drop")){
    buff_up_item(item_drop_needed, turns);
  }

  adv1(farm_location, 1, "combat");

  if(have_effect($effect[Beaten Up]).to_boolean()){
    abort("We got beaten up! Try moving some ML?");
  }

  if((my_maxhp() * 0.3) > my_hp()){
    restore_hp(my_maxhp());
  }

  if(equipped_amount($item[cursed monkey's paw]).to_boolean()){
  
  
  if(!equipped_amount($item[cursed monkey's paw]).to_boolean()){
    if(get_property("banishedMonsters").contains_text("Monkey Slap")){
      cli_execute("outfit checkpoint");
    } 
  }

  }


  turns--;
  print(`{turns} turns left! Gained {item_amount(farm_drop) - farm_drop_amount_prev} {farm_drop.to_plural()}!`, "orange");
}

print("Done!", "teal");

}
