//------------------------------------------------------------------------------
//
//  DelphiHeretic: A modified and improved Heretic port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2013 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Sprite animation.
//  Weapon sprite animation, weapon objects.
//  Action functions for weapons.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_pspr;

interface

uses
  doomdef,
  doomdata,
// Basic data types.
// Needs fixed point, and BAM angles.
  m_fixed,
  tables,
  info_h,
  p_pspr_h,
  p_mobj_h,
  d_player;

const
//
// Frame flags:
// handles maximum brightness (torches, muzzle flare, light sources)
//
  FF_FULLBRIGHT = $8000; // flag in thing.frame
  FF_FRAMEMASK = $7fff;

procedure P_DropWeapon(player: Pplayer_t);

procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);

procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);

procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BeakRaise(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BeakAttackPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BeakAttackPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_StaffAttackPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_StaffAttackPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireBlasterPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireBlasterPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireGoldWandPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireGoldWandPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireMacePL1B(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireMacePL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_MaceBallImpact(ball: Pmobj_t);

procedure A_MacePL1Check(ball: Pmobj_t);

procedure A_MaceBallImpact2(ball: Pmobj_t);

procedure A_FireMacePL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_DeathBallImpact(ball: Pmobj_t);

procedure A_SpawnRippers(actor: Pmobj_t);

procedure A_FireCrossbowPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireCrossbowPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BoltSpark(bolt: Pmobj_t);

procedure A_FireSkullRodPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireSkullRodPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_SkullRodPL2Seek(actor: Pmobj_t);

procedure A_AddPlayerRain(actor: Pmobj_t);

procedure A_SkullRodStorm(actor: Pmobj_t);

procedure A_RainImpact(actor: Pmobj_t);

procedure A_HideInCeiling(actor: Pmobj_t);

procedure A_FirePhoenixPL1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_PhoenixPuff(actor: Pmobj_t);

procedure A_InitPhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FirePhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_ShutdownPhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FlameEnd(actor: Pmobj_t);

procedure A_FloatPuff(puff: Pmobj_t);

procedure A_GauntletAttack(player: Pplayer_t; psp: Ppspdef_t);

procedure A_BeakReady(player: Pplayer_t; psp: Ppspdef_t);

procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);

procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);

procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);

procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);

procedure P_SetupPsprites(player: Pplayer_t);

procedure P_MovePsprites(player: Pplayer_t);

procedure P_BulletSlope(mo: Pmobj_t);

procedure P_UpdateBeak(player: Pplayer_t; psp: Ppspdef_t);

procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: statenum_t);

procedure P_PostChickenWeapon(player: Pplayer_t; weapon: weapontype_t);

procedure P_OpenWeapons;

procedure P_CloseWeapons;

procedure P_RepositionMace(mo: Pmobj_t);

procedure P_AddMaceSpot(mthing: Pmapthing_t);

procedure P_ActivateBeak(player: Pplayer_t);

implementation

uses
  d_delphi,
  g_game,
  i_system,
  p_user,
  info,
//
// Needs to include the precompiled
//  sprite animation tables.
// Header generated by multigen utility.
// This includes all the data for thing animation,
// i.e. the Thing Atrributes table
// and the Frame Sequence table.
  d_event,
  m_rnd,
  p_local, p_plats, p_tick, p_mobj, p_enemy, p_map, p_inter, p_maputl,
  r_main, r_draw, r_defs,
  s_sound,
// State.
  doomstat,
// Data.
  sounds;

//
// Adjust weapon bottom and top
//

const
  WEAPONTOP = 32 * FRACUNIT;
  WEAPONBOTTOM = WEAPONTOP + 96 * FRACUNIT;

const
  LOWERSPEED = 6 * FRACUNIT;
  RAISESPEED = 6 * FRACUNIT;

const
  FLAME_THROWER_TICS = 10 * TICRATE;
  MAGIC_JUNK = 1234;

const
  MAX_MACE_SPOTS = 8;

var
  MaceSpotCount: integer;

type
  macespot_t = record
    x, y: fixed_t;
  end;

var
  MaceSpots: array[0..MAX_MACE_SPOTS - 1] of macespot_t;

const
  WeaponAmmoUsePL1: array[0..Ord(NUMWEAPONS) - 1] of integer = (
    0,          // staff
    USE_GWND_AMMO_1,  // gold wand
    USE_CBOW_AMMO_1,  // crossbow
    USE_BLSR_AMMO_1,  // blaster
    USE_SKRD_AMMO_1,  // skull rod
    USE_PHRD_AMMO_1,  // phoenix rod
    USE_MACE_AMMO_1,  // mace
    0,          // gauntlets
    0          // beak
  );

  WeaponAmmoUsePL2: array[0..Ord(NUMWEAPONS) - 1] of integer = (
    0,          // staff
    USE_GWND_AMMO_2,  // gold wand
    USE_CBOW_AMMO_2,  // crossbow
    USE_BLSR_AMMO_2,  // blaster
    USE_SKRD_AMMO_2,  // skull rod
    USE_PHRD_AMMO_2,  // phoenix rod
    USE_MACE_AMMO_2,  // mace
    0,          // gauntlets
    0          // beak
  );

//---------------------------------------------------------------------------
//
// PROC P_OpenWeapons
//
// Called at level load before things are loaded.
//
//---------------------------------------------------------------------------

procedure P_OpenWeapons;
begin
  MaceSpotCount := 0;
end;

//---------------------------------------------------------------------------
//
// PROC P_AddMaceSpot
//
//---------------------------------------------------------------------------

procedure P_AddMaceSpot(mthing: Pmapthing_t);
begin
  if MaceSpotCount = MAX_MACE_SPOTS then
    I_Error('P_AddMaceSpot: Too many mace spots: %d.', [MaceSpotCount]);

  MaceSpots[MaceSpotCount].x := mthing.x * FRACUNIT;
  MaceSpots[MaceSpotCount].y := mthing.y * FRACUNIT;
  inc(MaceSpotCount);
end;

//---------------------------------------------------------------------------
//
// PROC P_RepositionMace
//
// Chooses the next spot to place the mace.
//
//---------------------------------------------------------------------------

procedure P_RepositionMace(mo: Pmobj_t);
var
  spot: integer;
  ss: Psubsector_t;
begin
  P_UnsetThingPosition(mo);
  spot := P_Random mod MaceSpotCount;
  mo.x := MaceSpots[spot].x;
  mo.y := MaceSpots[spot].y;
  ss := R_PointInSubsector(mo.x, mo.y);
  mo.z := ss.sector.floorheight;
  mo.floorz := mo.z;
  mo.ceilingz := ss.sector.ceilingheight;
  P_SetThingPosition(mo);
end;

//---------------------------------------------------------------------------
//
// PROC P_CloseWeapons
//
// Called at level load after things are loaded.
//
//---------------------------------------------------------------------------

procedure P_CloseWeapons;
var
  spot: integer;
begin
  if MaceSpotCount = 0 then // No maces placed
    exit;
    
  if (deathmatch <> 0) and (P_Random < 64) then
  begin // Sometimes doesn't show up if not in deathmatch
    exit;
  end;

  spot := P_Random mod MaceSpotCount;
  P_SpawnMobj(MaceSpots[spot].x, MaceSpots[spot].y, ONFLOORZ, Ord(MT_WMACE));
end;



//
// P_SetPsprite
//
procedure P_SetPsprite(player: Pplayer_t; position: integer; stnum: statenum_t);
var
  psp: Ppspdef_t;
  state: Pstate_t;
begin
  psp := @player.psprites[position];
  repeat
    if Ord(stnum) = 0 then
    begin
      // object removed itself
      psp.state := nil;
      break;
    end;

    state := @states[Ord(stnum)];
    psp.state := state;
    psp.tics := state.tics; // could be 0

    // coordinate set
    if state.misc1 <> 0 then
      psp.sx := state.misc1 * FRACUNIT;

    if state.misc2 <> 0 then
      psp.sy := state.misc2 * FRACUNIT;

    // Call action routine.
    // Modified handling.
    if Assigned(state.action.acp2) then
    begin
      state.action.acp2(player, psp);
      if psp.state = nil then
        break;
    end;

    stnum := psp.state.nextstate;

  until psp.tics <> 0;
  // an initial state of 0 could cycle through
end;

//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//
procedure P_BringUpWeapon(player: Pplayer_t);
var
  newstate: statenum_t;
begin
  if player.pendingweapon = wp_nochange then
    player.pendingweapon := player.readyweapon;

  if player.pendingweapon = wp_gauntlets then
    S_StartSound(player.mo, Ord(sfx_gntact));

  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
    newstate := statenum_t(wpnlev2info[Ord(player.pendingweapon)].upstate)
  else
    newstate := statenum_t(wpnlev1info[Ord(player.pendingweapon)].upstate);

  player.pendingweapon := wp_nochange;
  player.psprites[Ord(ps_weapon)].sy := WEAPONBOTTOM;

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//
function P_CheckAmmo(player: Pplayer_t): boolean;
var
  ammo: ammotype_t;
  count: integer;
  ammouse: PIntegerArray;
begin
  ammo := wpnlev1info[Ord(player.readyweapon)].ammo;

  if (player.powers[Ord(pw_weaponlevel2)] <> 0) and (deathmatch = 0) then
    ammoUse := @WeaponAmmoUsePL2
  else
    ammoUse := @WeaponAmmoUsePL1;

  count := ammoUse[Ord(player.readyweapon)];
  if (ammo = am_noammo) or (player.ammo[Ord(ammo)] >= count) then
  begin
    result := true;
    exit;
  end;

  // out of ammo, pick a weapon to change to
  repeat
    if (player.weaponowned[Ord(wp_skullrod)] <> 0) and
      (player.ammo[Ord(am_skullrod)] > ammoUse[Ord(wp_skullrod)]) then
    begin
      player.pendingweapon := wp_skullrod;
    end
    else if (player.weaponowned[Ord(wp_blaster)] <> 0) and
            (player.ammo[Ord(am_blaster)] > ammoUse[Ord(wp_blaster)]) then
    begin
      player.pendingweapon := wp_blaster;
    end
    else if (player.weaponowned[Ord(wp_crossbow)] <> 0) and
            (player.ammo[Ord(am_crossbow)] > ammoUse[Ord(wp_crossbow)]) then
    begin
      player.pendingweapon := wp_crossbow;
    end
    else if (player.weaponowned[Ord(wp_mace)] <> 0) and
            (player.ammo[Ord(am_mace)] > ammoUse[Ord(wp_mace)]) then
    begin
      player.pendingweapon := wp_mace;
    end
    else if player.ammo[Ord(am_goldwand)] > ammoUse[Ord(wp_goldwand)] then
    begin
      player.pendingweapon := wp_goldwand;
    end
    else if player.weaponowned[Ord(wp_gauntlets)] <> 0 then
    begin
      player.pendingweapon := wp_gauntlets;
    end
    else if (player.weaponowned[Ord(wp_phoenixrod)] <> 0) and
            (player.ammo[Ord(am_phoenixrod)] > ammoUse[Ord(wp_phoenixrod)]) then
    begin
      player.pendingweapon := wp_phoenixrod;
    end
    else
    begin
      player.pendingweapon := wp_staff;
    end;
  until player.pendingweapon <> wp_nochange;

  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
    P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev2info[Ord(player.readyweapon)].downstate))
  else
    P_SetPsprite(player, Ord(ps_weapon),  statenum_t(wpnlev1info[Ord(player.readyweapon)].downstate));

  result := false;
end;

//
// P_FireWeapon.
//
procedure P_FireWeapon(player: Pplayer_t);
var
  newstate: statenum_t;
  weaponinfo: Pweaponinfo_tArray;
begin
  if P_CheckAmmo(player) then
  begin
    P_SetMobjState(player.mo, S_PLAY_ATK2);
    if player.powers[Ord(pw_weaponlevel2)] <> 0 then
      weaponinfo := @wpnlev2info
    else
      weaponinfo := @wpnlev1info;
    if player.refire <> 0 then
      newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].holdatkstate)
    else
      newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].atkstate);
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    P_NoiseAlert(player.mo, player.mo);
    if (player.readyweapon = wp_gauntlets) and (player.refire = 0) then
     // Play the sound for the initial gauntlet attack
      S_StartSound(player.mo, Ord(sfx_gntuse));
  end;
end;

//
// P_DropWeapon
// Player died, so put the weapon away.
//
procedure P_DropWeapon(player: Pplayer_t);
begin
  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
    P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev2info[Ord(player.readyweapon)].downstate))
  else
    P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev1info[Ord(player.readyweapon)].downstate));
end;

//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//
procedure A_WeaponReady(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: statenum_t;
  angle: integer;
begin
  // get out of attack state
  if (player.mo.state = @states[Ord(S_PLAY_ATK1)]) or
     (player.mo.state = @states[Ord(S_PLAY_ATK2)]) then
    P_SetMobjState(player.mo, S_PLAY);

  // Check for staff PL2 active sound  
  if (player.readyweapon = wp_staff) and
     (psp.state = @states[Ord(S_STAFFREADY2_1)]) then
    if P_Random < 128 then
      S_StartSound(player.mo, Ord(sfx_stfcrk));

  // check for change
  //  if player is dead, put the weapon away
  if (player.pendingweapon <> wp_nochange) or (player.health = 0) then
  begin
    // change weapon
    //  (pending weapon should allready be validated)
    if player.powers[Ord(pw_weaponlevel2)] <> 0 then
      newstate := statenum_t(wpnlev2info[Ord(player.readyweapon)].downstate)
    else
      newstate := statenum_t(wpnlev1info[Ord(player.readyweapon)].downstate);
    P_SetPsprite(player, Ord(ps_weapon), newstate);
    exit;
  end;

  // check for fire
  //  the missile launcher and bfg do not auto fire
  if player.cmd.buttons and BT_ATTACK <> 0 then
  begin
    if (not player.attackdown) or
       (player.readyweapon <> wp_phoenixrod) then
    begin
      player.attackdown := true;
      P_FireWeapon(player);
      exit;
    end;
  end
  else
    player.attackdown := false;

  // bob the weapon based on movement speed
  angle := (128 * leveltime) and FINEMASK;
  psp.sx := FRACUNIT + FixedMul(player.bob, finecosine[angle]);
  angle := angle and (FINEANGLES div 2 - 1);
  psp.sy := WEAPONTOP + FixedMul(player.bob, finesine[angle]);
end;

//
// A_ReFire
// The player can re-fire the weapon
// without lowering it entirely.
//
procedure A_ReFire(player: Pplayer_t; psp: Ppspdef_t);
begin
  // check for fire
  //  (if a weaponchange is pending, let it go through instead)
  if (player.cmd.buttons and BT_ATTACK <> 0) and
     (player.pendingweapon = wp_nochange) and
     (player.health > 0) then
  begin
    player.refire := player.refire + 1;
    P_FireWeapon(player);
  end
  else
  begin
    player.refire := 0;
    P_CheckAmmo(player);
  end;
end;

procedure A_CheckReload(player: Pplayer_t; psp: Ppspdef_t);
begin
  P_CheckAmmo(player);
{
#if 0
    if (player.ammo[am_shell]<2)
  P_SetPsprite (player, ps_weapon, S_DSNR1);
#endif
}
end;

//
// A_Lower
// Lowers current weapon,
//  and changes weapon at bottom.
//
procedure A_Lower(player: Pplayer_t; psp: Ppspdef_t);
begin
  if player.chickenTics <> 0 then
    psp.sy := WEAPONBOTTOM
  else
    psp.sy := psp.sy + LOWERSPEED;

  // Is already down.
  if psp.sy < WEAPONBOTTOM then
    exit;

  // Player is dead.
  if player.playerstate = PST_DEAD then
  begin
    psp.sy := WEAPONBOTTOM;
    // don't bring weapon back up
    exit;
  end;

  // The old weapon has been lowered off the screen,
  // so change the weapon and start raising it
  if player.health = 0 then
  begin
    // Player is dead, so keep the weapon off screen.
    P_SetPsprite(player, Ord(ps_weapon), S_NULL);
    exit;
  end;

  player.readyweapon := player.pendingweapon;

  P_BringUpWeapon(player);
end;

//---------------------------------------------------------------------------
//
// PROC A_BeakRaise
//
//---------------------------------------------------------------------------

procedure A_BeakRaise(player: Pplayer_t; psp: Ppspdef_t);
begin
  psp.sy := WEAPONTOP;
  P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev1info[Ord(player.readyweapon)].readystate));
end;

//
// A_Raise
//
procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: statenum_t;
begin
  psp.sy := psp.sy - RAISESPEED;

  if psp.sy > WEAPONTOP then // Not raised all the way yet
    exit;

  psp.sy := WEAPONTOP;

  // The weapon has been raised all the way,
  //  so change to the ready state.
  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
    newstate := statenum_t(wpnlev2info[Ord(player.readyweapon)].readystate)
  else
    newstate := statenum_t(wpnlev1info[Ord(player.readyweapon)].readystate);

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

//
// WEAPON ATTACKS
//


//
// P_BulletSlope
// Sets a slope so a near miss is at aproximately
// the height of the intended target
//
var
  bulletslope: fixed_t;


procedure P_BulletSlope(mo: Pmobj_t);
var
  an: angle_t;
begin
  // see which target is to be aimed at
  an := mo.angle;
  bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    bulletslope := P_AimLineAttack (mo, an, 16 * 64 * FRACUNIT);
    if linetarget = nil then
    begin
      an := an - $8000000;
      bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
      if zaxisshift and (linetarget = nil) then
        bulletslope := (Pplayer_t(mo.player).lookdir * FRACUNIT) div 173;
    end;
  end;
end;

//****************************************************************************
//
// WEAPON ATTACKS
//
//****************************************************************************

//----------------------------------------------------------------------------
//
// PROC A_BeakAttackPL1
//
//----------------------------------------------------------------------------

procedure A_BeakAttackPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  damage := 1 + (P_Random and 3);
  angle := player.mo.angle;
  slope := P_AimLineAttack(player.mo, angle, MELEERANGE);
  PuffType := MT_BEAKPUFF;
  P_LineAttack(player.mo, angle, MELEERANGE, slope, damage);
  if linetarget <> nil then
  begin
    player.mo.angle := R_PointToAngle2(player.mo.x, player.mo.y, linetarget.x, linetarget.y);
  end;
  S_StartSound(player.mo, Ord(sfx_chicpk1) + (P_Random mod 3));
  player.chickenPeck := 12;
  psp.tics := psp.tics - P_Random and 7;
end;

//----------------------------------------------------------------------------
//
// PROC A_BeakAttackPL2
//
//----------------------------------------------------------------------------

procedure A_BeakAttackPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  damage := HITDICE(4);
  angle := player.mo.angle;
  slope := P_AimLineAttack(player.mo, angle, MELEERANGE);
  PuffType := MT_BEAKPUFF;
  P_LineAttack(player.mo, angle, MELEERANGE, slope, damage);
  if linetarget <> nil then
    player.mo.angle := R_PointToAngle2(player.mo.x,  player.mo.y, linetarget.x, linetarget.y);
  S_StartSound(player.mo, Ord(sfx_chicpk1) + (P_Random mod 3));
  player.chickenPeck := 12;
  psp.tics := psp.tics - P_Random and 3;
end;

//----------------------------------------------------------------------------
//
// PROC A_StaffAttackPL1
//
//----------------------------------------------------------------------------

procedure A_StaffAttackPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  damage := 5 + (P_Random and 15);
  angle := player.mo.angle;
  angle := angle + LongWord((P_Random - P_Random) * $40000);
  slope := P_AimLineAttack(player.mo, angle, MELEERANGE);
  PuffType := MT_STAFFPUFF;
  P_LineAttack(player.mo, angle, MELEERANGE, slope, damage);
  if linetarget <> nil then
  begin
    //S_StartSound(player.mo, sfx_stfhit);
    // turn to face target
    player.mo.angle := R_PointToAngle2(player.mo.x, player.mo.y, linetarget.x, linetarget.y);
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_StaffAttackPL2
//
//----------------------------------------------------------------------------

procedure A_StaffAttackPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
begin
  // P_inter.c:P_DamageMobj handles target momentums
  damage := 18 + (P_Random and 63);
  angle := player.mo.angle;
  angle := angle + LongWord((P_Random - P_Random) * $40000);
  slope := P_AimLineAttack(player.mo, angle, MELEERANGE);
  PuffType := MT_STAFFPUFF2;
  P_LineAttack(player.mo, angle, MELEERANGE, slope, damage);
  if linetarget <> nil then
  begin
    //S_StartSound(player.mo, sfx_stfpow);
    // turn to face target
    player.mo.angle := R_PointToAngle2(player.mo.x, player.mo.y, linetarget.x, linetarget.y);
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_FireBlasterPL1
//
//----------------------------------------------------------------------------

procedure A_FireBlasterPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
  angle: angle_t;
  damage: integer;
begin
  mo := player.mo;
  S_StartSound(mo, Ord(sfx_gldhit));
  player.ammo[Ord(am_blaster)] := player.ammo[Ord(am_blaster)] - USE_BLSR_AMMO_1;
  P_BulletSlope(mo);
  damage := HITDICE(4);
  angle := mo.angle;
  if player.refire <> 0 then
    angle := angle + LongWord((P_Random - P_Random) * $40000);

  PuffType := MT_BLASTERPUFF1;
  P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
  S_StartSound(player.mo, Ord(sfx_blssht));
end;

//----------------------------------------------------------------------------
//
// PROC A_FireBlasterPL2
//
//----------------------------------------------------------------------------

procedure A_FireBlasterPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
begin
  if deathmatch <> 0 then
    player.ammo[Ord(am_blaster)] := player.ammo[Ord(am_blaster)] - USE_BLSR_AMMO_1
  else
    player.ammo[Ord(am_blaster)] := player.ammo[Ord(am_blaster)] - USE_BLSR_AMMO_2;

  mo := P_SpawnPlayerMissile(player.mo, Ord(MT_BLASTERFX1));

  if mo <> nil then
    mo.thinker._function.acp2 := @P_BlasterMobjThinker;

  S_StartSound(player.mo, Ord(sfx_blssht));
end;

//----------------------------------------------------------------------------
//
// PROC A_FireGoldWandPL1
//
//----------------------------------------------------------------------------

procedure A_FireGoldWandPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
  angle: angle_t;
  damage: integer;
begin
  mo := player.mo;
  player.ammo[Ord(am_goldwand)] := player.ammo[Ord(am_goldwand)] - USE_GWND_AMMO_1;
  P_BulletSlope(mo);
  damage := 7 + (P_Random and 7);
  angle := mo.angle;
  if player.refire <> 0 then
    angle := angle + LongWord((P_Random - P_Random) * $40000);
  PuffType := MT_GOLDWANDPUFF1;
  P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
  S_StartSound(player.mo, Ord(sfx_gldhit));
end;

//----------------------------------------------------------------------------
//
// PROC A_FireGoldWandPL2
//
//----------------------------------------------------------------------------

procedure A_FireGoldWandPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  i: integer;
  mo: Pmobj_t;
  angle: angle_t;
  damage: integer;
  momz: fixed_t;
begin
  mo := player.mo;
  if deathmatch <> 0 then
    player.ammo[Ord(am_goldwand)] := player.ammo[Ord(am_goldwand)] - USE_GWND_AMMO_1
  else
    player.ammo[Ord(am_goldwand)] := player.ammo[Ord(am_goldwand)] - USE_GWND_AMMO_2;
  PuffType := MT_GOLDWANDPUFF2;
  P_BulletSlope(mo);
  momz := FixedMul(mobjinfo[Ord(MT_GOLDWANDFX2)].speed, bulletslope);
  P_SpawnMissileAngle(mo, Ord(MT_GOLDWANDFX2), mo.angle - (ANG45 div 8), momz);
  P_SpawnMissileAngle(mo, Ord(MT_GOLDWANDFX2), mo.angle + (ANG45 div 8), momz);
  angle := mo.angle - (ANG45 div 8);
  for i := 0 to 4 do
  begin
    damage := 1 + (P_Random and 7);
    P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
    angle := angle + ((ANG45 div 8) * 2) div 4;
  end;
  S_StartSound(player.mo, Ord(sfx_gldhit));
end;

//----------------------------------------------------------------------------
//
// PROC A_FireMacePL1B
//
//----------------------------------------------------------------------------

procedure A_FireMacePL1B(player: Pplayer_t; psp: Ppspdef_t);
var
  pmo: Pmobj_t;
  ball: Pmobj_t;
  angle: angle_t;
begin
  if player.ammo[Ord(am_mace)] < USE_MACE_AMMO_1 then
    exit;

  player.ammo[Ord(am_mace)] := player.ammo[Ord(am_mace)] - USE_MACE_AMMO_1;
  pmo := player.mo;

  if pmo.flags2 and MF2_FEETARECLIPPED <> 0 then
    ball := P_SpawnMobj(pmo.x, pmo.y, pmo.z + 28 * FRACUNIT - FOOTCLIPSIZE, Ord(MT_MACEFX2))
  else
    ball := P_SpawnMobj(pmo.x, pmo.y, pmo.z + 28 * FRACUNIT, Ord(MT_MACEFX2));

  ball.momz := 2 * FRACUNIT + player.lookdir * 2048;
  angle := pmo.angle;
  ball.target := pmo;
  ball.angle := angle;
  ball.z := ball.z + player.lookdir * 4096;
  angle := angle shr ANGLETOFINESHIFT;
  ball.momx := (pmo.momx div 2) + FixedMul(ball.info.speed, finecosine[angle]);
  ball.momy := (pmo.momy div 2) + FixedMul(ball.info.speed, finesine[angle]);
  S_StartSound(ball, Ord(sfx_lobsht));
  P_CheckMissileSpawn(ball);
end;

//----------------------------------------------------------------------------
//
// PROC A_FireMacePL1
//
//----------------------------------------------------------------------------

procedure A_FireMacePL1(player: Pplayer_t; psp: Ppspdef_t);
var
  ball: Pmobj_t;
begin
  if P_Random < 28 then
  begin
    A_FireMacePL1B(player, psp);
    exit;
  end;

  if player.ammo[Ord(am_mace)] < USE_MACE_AMMO_1 then
    exit;

  player.ammo[Ord(am_mace)] := player.ammo[Ord(am_mace)] - USE_MACE_AMMO_1;
  psp.sx := ((P_Random and 3) - 2) * FRACUNIT;
  psp.sy := WEAPONTOP + (P_Random and 3) * FRACUNIT;
  ball := P_SPMAngle(player.mo, Ord(MT_MACEFX1), player.mo.angle + LongWord(((P_Random and 7) - 4) * $1000000));
  if ball <> nil then
    ball.special1 := 16; // tics till dropoff
end;

//----------------------------------------------------------------------------
//
// PROC A_MacePL1Check
//
//----------------------------------------------------------------------------

procedure A_MacePL1Check(ball: Pmobj_t);
var
  angle: angle_t;
begin
  if ball.special1 = 0 then
    exit;

  ball.special1 := ball.special1 - 4;
  if ball.special1 > 0 then
    exit;

  ball.special1 := 0;
  ball.flags2 := ball.flags2 or MF2_LOGRAV;
  angle := ball.angle shr ANGLETOFINESHIFT;
  ball.momx := FixedMul(7 * FRACUNIT, finecosine[angle]);
  ball.momy := FixedMul(7 * FRACUNIT, finesine[angle]);
  ball.momz := ball.momz div 2;
end;

//----------------------------------------------------------------------------
//
// PROC A_MaceBallImpact
//
//----------------------------------------------------------------------------

procedure A_MaceBallImpact(ball: Pmobj_t);
begin
  if (ball.z <= ball.floorz) and (P_HitFloor(ball) <> FLOOR_SOLID) then
  begin // Landed in some sort of liquid
    P_RemoveMobj(ball);
    exit;
  end;

  if (ball.health <> MAGIC_JUNK) and (ball.z <= ball.floorz) and (ball.momz <> 0) then
  begin // Bounce
    ball.health := MAGIC_JUNK;
    ball.momz := (ball.momz * 192) div 256;
    ball.flags2 := ball.flags2 and not MF2_FLOORBOUNCE;
    P_SetMobjState(ball, statenum_t(ball.info.spawnstate));
    S_StartSound(ball, Ord(sfx_bounce));
  end
  else
  begin // Explode
    ball.flags := ball.flags or MF_NOGRAVITY;
    ball.flags2 := ball.flags2 and not MF2_LOGRAV;
    S_StartSound(ball, Ord(sfx_lobhit));
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_MaceBallImpact2
//
//----------------------------------------------------------------------------

procedure A_MaceBallImpact2(ball: Pmobj_t);
var
  tiny: Pmobj_t;
  angle: angle_t;
begin
  if (ball.z <= ball.floorz) and (P_HitFloor(ball) <> FLOOR_SOLID) then
  begin // Landed in some sort of liquid
    P_RemoveMobj(ball);
    exit;
  end;

  if (ball.z <> ball.floorz) or (ball.momz < 2 * FRACUNIT) then
  begin // Explode
    ball.momx := 0;
    ball.momy := 0;
    ball.momz := 0;
    ball.flags := ball.flags or MF_NOGRAVITY;
    ball.flags2 := ball.flags2 and not (MF2_LOGRAV or MF2_FLOORBOUNCE);
  end
  else
  begin // Bounce
    ball.momz := (ball.momz * 192) div 256;
    P_SetMobjState(ball, statenum_t(ball.info.spawnstate));

    tiny := P_SpawnMobj(ball.x, ball.y, ball.z, Ord(MT_MACEFX3));
    angle := ball.angle + ANG90;
    tiny.target := ball.target;
    tiny.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    tiny.momx := (ball.momx div 2) + FixedMul(ball.momz - FRACUNIT, finecosine[angle]);
    tiny.momy := (ball.momy div 2) + FixedMul(ball.momz - FRACUNIT, finesine[angle]);
    tiny.momz := ball.momz;
    P_CheckMissileSpawn(tiny);

    tiny := P_SpawnMobj(ball.x, ball.y, ball.z, Ord(MT_MACEFX3));
    angle := ball.angle - ANG90;
    tiny.target := ball.target;
    tiny.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    tiny.momx := (ball.momx div 2) + FixedMul(ball.momz - FRACUNIT, finecosine[angle]);
    tiny.momy := (ball.momy div 2) + FixedMul(ball.momz - FRACUNIT, finesine[angle]);
    tiny.momz := ball.momz;
    P_CheckMissileSpawn(tiny);
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_FireMacePL2
//
//----------------------------------------------------------------------------

procedure A_FireMacePL2(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
begin
  if deathmatch <> 0 then
    player.ammo[Ord(am_mace)] := player.ammo[Ord(am_mace)] - USE_MACE_AMMO_1
  else
    player.ammo[Ord(am_mace)] := player.ammo[Ord(am_mace)] - USE_MACE_AMMO_2;

  mo := P_SpawnPlayerMissile(player.mo, Ord(MT_MACEFX4));
  if mo <> nil then
  begin
    mo.momx := mo.momx + player.mo.momx;
    mo.momy := mo.momy + player.mo.momy;
    mo.momz := 2 * FRACUNIT + (player.lookdir * 2048);
    if linetarget <> nil then
      mo.special1 := integer(linetarget);
  end;
  S_StartSound(player.mo, Ord(sfx_lobsht));
end;

//----------------------------------------------------------------------------
//
// PROC A_DeathBallImpact
//
//----------------------------------------------------------------------------

procedure A_DeathBallImpact(ball: Pmobj_t);
var
  i: integer;
  target: Pmobj_t;
  angle: angle_t;
  newAngle: boolean;
begin
  if (ball.z <= ball.floorz) and (P_HitFloor(ball) <> FLOOR_SOLID) then
  begin // Landed in some sort of liquid
    P_RemoveMobj(ball);
    exit;
  end;
  
  if (ball.z <= ball.floorz) and (ball.momz <> 0) then
  begin // Bounce
    newAngle := false;
    angle := 0;
    target := Pmobj_t(ball.special1);
    if target <> nil then
    begin
      if target.flags and MF_SHOOTABLE = 0 then
      begin // Target died
        ball.special1 := 0;
      end
      else
      begin // Seek
        angle := R_PointToAngle2(ball.x, ball.y, target.x, target.y);
        newAngle := true;
      end;
    end
    else
    begin // Find new target
      for i := 0 to 15 do
      begin
        P_AimLineAttack(ball, angle, 10 * 64 * FRACUNIT);
        if (linetarget <> nil) and (ball.target <> linetarget) then
        begin
          ball.special1 := integer(linetarget);
          angle := R_PointToAngle2(ball.x, ball.y, linetarget.x, linetarget.y);
          newAngle := true;
          break;
        end;
        angle := angle + ANG45 div 2;
      end
    end;
    if newAngle then
    begin
      ball.angle := angle;
      angle := angle shr ANGLETOFINESHIFT;
      ball.momx := FixedMul(ball.info.speed, finecosine[angle]);
      ball.momy := FixedMul(ball.info.speed, finesine[angle]);
    end;
    P_SetMobjState(ball, statenum_t(ball.info.spawnstate));
    S_StartSound(ball, Ord(sfx_pstop));
  end
  else
  begin // Explode
    ball.flags := ball.flags or MF_NOGRAVITY;
    ball.flags2 := ball.flags2 and not MF2_LOGRAV;
    S_StartSound(ball, Ord(sfx_phohit));
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_SpawnRippers
//
//----------------------------------------------------------------------------

procedure A_SpawnRippers(actor: Pmobj_t);
var
  i: integer;
  angle: angle_t;
  ripper: Pmobj_t;
begin
  for i := 0 to 7 do
  begin
    ripper := P_SpawnMobj(actor.x, actor.y, actor.z, Ord(MT_RIPPER));
    angle := i * ANG45;
    ripper.target := actor.target;
    ripper.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    ripper.momx := FixedMul(ripper.info.speed, finecosine[angle]);
    ripper.momy := FixedMul(ripper.info.speed, finesine[angle]);
    P_CheckMissileSpawn(ripper);
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_FireCrossbowPL1
//
//----------------------------------------------------------------------------

procedure A_FireCrossbowPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  pmo: Pmobj_t;
begin
  pmo := player.mo;
  player.ammo[Ord(am_crossbow)] := player.ammo[Ord(am_crossbow)] - USE_CBOW_AMMO_1;
  P_SpawnPlayerMissile(pmo, Ord(MT_CRBOWFX1));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX3), pmo.angle - (ANG45 div 10));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX3), pmo.angle + (ANG45 div 10));
end;

//----------------------------------------------------------------------------
//
// PROC A_FireCrossbowPL2
//
//----------------------------------------------------------------------------

procedure A_FireCrossbowPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  pmo: Pmobj_t;
begin
  pmo := player.mo;
  if deathmatch <> 0 then
    player.ammo[Ord(am_crossbow)] := player.ammo[Ord(am_crossbow)] - USE_CBOW_AMMO_1
  else
    player.ammo[Ord(am_crossbow)] := player.ammo[Ord(am_crossbow)] - USE_CBOW_AMMO_2;

  P_SpawnPlayerMissile(pmo, Ord(MT_CRBOWFX2));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX2), pmo.angle - (ANG45 div 10));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX2), pmo.angle + (ANG45 div 10));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX3), pmo.angle - (ANG45 div 5));
  P_SPMAngle(pmo, Ord(MT_CRBOWFX3), pmo.angle + (ANG45 div 5));
end;

//----------------------------------------------------------------------------
//
// PROC A_BoltSpark
//
//----------------------------------------------------------------------------

procedure A_BoltSpark(bolt: Pmobj_t);
var
  spark: Pmobj_t;
begin
  if P_Random > 50 then
  begin
    spark := P_SpawnMobj(bolt.x, bolt.y, bolt.z, Ord(MT_CRBOWFX4));
    spark.x := spark.x + (P_Random - P_Random) * 1024;
    spark.y := spark.y + (P_Random - P_Random) * 1024;
  end;
end;

//----------------------------------------------------------------------------
//
// PROC A_FireSkullRodPL1
//
//----------------------------------------------------------------------------

procedure A_FireSkullRodPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
begin
  if player.ammo[Ord(am_skullrod)] < USE_SKRD_AMMO_1 then
    exit;

  player.ammo[Ord(am_skullrod)] := player.ammo[Ord(am_skullrod)] - USE_SKRD_AMMO_1;
  mo := P_SpawnPlayerMissile(player.mo, Ord(MT_HORNRODFX1));
  // Randomize the first frame
  if (mo <> nil) and (P_Random > 128) then
    P_SetMobjState(mo, S_HRODFX1_2);
end;

//----------------------------------------------------------------------------
//
// PROC A_FireSkullRodPL2
//
// The special2 field holds the player number that shot the rain missile.
// The special1 field is used for the seeking routines, then as a counter
// for the sound looping.
//
//----------------------------------------------------------------------------

procedure A_FireSkullRodPL2(player: Pplayer_t; psp: Ppspdef_t);
begin
  if deathmatch <> 0 then
    player.ammo[Ord(am_skullrod)] := player.ammo[Ord(am_skullrod)] - USE_SKRD_AMMO_1
  else
    player.ammo[Ord(am_skullrod)] := player.ammo[Ord(am_skullrod)] - USE_SKRD_AMMO_2;

  P_SpawnPlayerMissile(player.mo, Ord(MT_HORNRODFX2));

  // Use MissileMobj instead of the return value from
  // P_SpawnPlayerMissile because we need to give info to the mobj
  // even if it exploded immediately.

  if netgame then // Multi-player game
    MissileMobj.special2 := P_GetPlayerNum(player)
  else // Always use red missiles in single player games
    MissileMobj.special2 := 2;

  if linetarget <> nil then
    MissileMobj.special1 := integer(linetarget);

  S_StartSound(MissileMobj, Ord(sfx_hrnpow));
end;

//----------------------------------------------------------------------------
//
// PROC A_SkullRodPL2Seek
//
//----------------------------------------------------------------------------

procedure A_SkullRodPL2Seek(actor: Pmobj_t);
begin
  P_SeekerMissile(actor, ANG1 * 10, ANG1 * 30);
end;

//----------------------------------------------------------------------------
//
// PROC A_AddPlayerRain
//
//----------------------------------------------------------------------------

procedure A_AddPlayerRain(actor: Pmobj_t);
var
  playerNum: integer;
  player: Pplayer_t;
begin
  if netgame then
    playerNum := actor.special2
  else
    playerNum := 0;

  if not playeringame[playerNum] then // Player left the game
    exit;

  player := @players[playerNum];
  if player.health <= 0 then  // Player is dead
    exit;

  if (player.rain1 <> nil) and (player.rain2 <> nil) then
  begin // Terminate an active rain
    if (player.rain1.health < player.rain2.health) then
    begin
      if player.rain1.health > 16 then
        player.rain1.health := 16;
      player.rain1 := nil;
    end
    else
    begin
      if player.rain2.health > 16 then
        player.rain2.health := 16;
      player.rain2 := nil;
    end;
  end;
  // Add rain mobj to list
  if player.rain1 <> nil then
    player.rain2 := actor
  else
    player.rain1 := actor;
end;

//----------------------------------------------------------------------------
//
// PROC A_SkullRodStorm
//
//----------------------------------------------------------------------------

procedure A_SkullRodStorm(actor: Pmobj_t);
var
  x: fixed_t;
  y: fixed_t;
  mo: Pmobj_t;
  playerNum: integer;
  player: Pplayer_t;
begin
  dec(actor.health);
  if actor.health >= 0 then // JVAL: check!
  begin
    P_SetMobjState(actor, S_NULL);
    if netgame then
      playerNum := actor.special2
    else
      playerNum := 0;

    if not playeringame[playerNum] then // Player left the game
      exit;

    player := @players[playerNum];
    if player.health <= 0 then  // Player is dead
      exit;

    if player.rain1 = actor then
      player.rain1 := nil
    else if player.rain2 = actor then
      player.rain2 := nil;
    exit;
  end;
  if P_Random < 25 then // Fudge rain frequency
    exit;

  x := actor.x + ((P_Random and 127) - 64) * FRACUNIT;
  y := actor.y + ((P_Random and 127) - 64) * FRACUNIT;
  mo := P_SpawnMobj(x, y, ONCEILINGZ, Ord(MT_RAINPLR1) + actor.special2);
  mo.target := actor.target;
  mo.momx := 1; // Force collision detection
  mo.momz := -mo.info.speed;
  mo.special2 := actor.special2; // Transfer player number
  P_CheckMissileSpawn(mo);
  if actor.special1 and 31 = 0 then
    S_StartSound(actor, Ord(sfx_ramrain));

  inc(actor.special1);
end;

//----------------------------------------------------------------------------
//
// PROC A_RainImpact
//
//----------------------------------------------------------------------------

procedure A_RainImpact(actor: Pmobj_t);
begin
  if actor.z > actor.floorz then
    P_SetMobjState(actor, statenum_t(Ord(S_RAINAIRXPLR1_1) + actor.special2))
  else if P_Random < 40 then
    P_HitFloor(actor);
end;

//----------------------------------------------------------------------------
//
// PROC A_HideInCeiling
//
//----------------------------------------------------------------------------

procedure A_HideInCeiling(actor: Pmobj_t);
begin
  actor.z := actor.ceilingz + 4 * FRACUNIT;
end;

//----------------------------------------------------------------------------
//
// PROC A_FirePhoenixPL1
//
//----------------------------------------------------------------------------

procedure A_FirePhoenixPL1(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
begin
  player.ammo[Ord(am_phoenixrod)] := player.ammo[Ord(am_phoenixrod)] - USE_PHRD_AMMO_1;
  P_SpawnPlayerMissile(player.mo, Ord(MT_PHOENIXFX1));
  //P_SpawnPlayerMissile(player.mo, MT_MNTRFX2);
  angle := player.mo.angle+ANG180;
  angle := angle shr ANGLETOFINESHIFT;
  player.mo.momx := player.mo.momx + FixedMul(4 * FRACUNIT, finecosine[angle]);
  player.mo.momy := player.mo.momy + FixedMul(4 * FRACUNIT, finesine[angle]);
end;

//----------------------------------------------------------------------------
//
// PROC A_PhoenixPuff
//
//----------------------------------------------------------------------------

procedure A_PhoenixPuff(actor: Pmobj_t);
var
  puff: Pmobj_t;
  angle: angle_t;
begin
  P_SeekerMissile(actor, ANG1 * 5, ANG1 * 10);
  puff := P_SpawnMobj(actor.x, actor.y, actor.z, Ord(MT_PHOENIXPUFF));
  angle := actor.angle + ANG90;
  angle := angle shr ANGLETOFINESHIFT;
  puff.momx := FixedMul(85196, finecosine[angle]);
  puff.momy := FixedMul(85196, finesine[angle]);
  puff.momz := 0;
  puff := P_SpawnMobj(actor.x, actor.y, actor.z, Ord(MT_PHOENIXPUFF));
  angle := actor.angle - ANG90;
  angle := angle shr ANGLETOFINESHIFT;
  puff.momx := FixedMul(85196, finecosine[angle]);
  puff.momy := FixedMul(85196, finesine[angle]);
  puff.momz := 0;
end;

//----------------------------------------------------------------------------
//
// PROC A_InitPhoenixPL2
//
//----------------------------------------------------------------------------

procedure A_InitPhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.flamecount := FLAME_THROWER_TICS;
end;

//----------------------------------------------------------------------------
//
// PROC A_FirePhoenixPL2
//
// Flame thrower effect.
//
//----------------------------------------------------------------------------

procedure A_FirePhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);
var
  mo: Pmobj_t;
  pmo: Pmobj_t;
  angle: angle_t;
  x, y, z: fixed_t;
  slope: fixed_t;
begin
  dec(player.flamecount);
  if player.flamecount = 0 then
  begin // Out of flame
    P_SetPsprite(player, Ord(ps_weapon), S_PHOENIXATK2_4);
    player.refire := 0;
    exit;
  end;

  pmo := player.mo;
  angle := pmo.angle;
  x := pmo.x + ((P_Random - P_Random) * 512);
  y := pmo.y + ((P_Random - P_Random) * 512);
  z := pmo.z + 26 * FRACUNIT + (player.lookdir * FRACUNIT) div 173;
  if pmo.flags2 and MF2_FEETARECLIPPED <> 0 then
    z := z - FOOTCLIPSIZE;

  slope := (player.lookdir * FRACUNIT) div 173 + FRACUNIT div 10;
  mo := P_SpawnMobj(x, y, z, Ord(MT_PHOENIXFX2));
  mo.target := pmo;
  mo.angle := angle;
  mo.momx := pmo.momx + FixedMul(mo.info.speed, finecosine[angle shr ANGLETOFINESHIFT]);
  mo.momy := pmo.momy + FixedMul(mo.info.speed, finesine[angle shr ANGLETOFINESHIFT]);
  mo.momz := FixedMul(mo.info.speed, slope);
  if(player.refire = 0) or (leveltime mod 38 = 0) then
    S_StartSound(player.mo, Ord(sfx_phopow));

  P_CheckMissileSpawn(mo);
end;

//----------------------------------------------------------------------------
//
// PROC A_ShutdownPhoenixPL2
//
//----------------------------------------------------------------------------

procedure A_ShutdownPhoenixPL2(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.ammo[Ord(am_phoenixrod)] := player.ammo[Ord(am_phoenixrod)] - USE_PHRD_AMMO_2;
end;

//----------------------------------------------------------------------------
//
// PROC A_FlameEnd
//
//----------------------------------------------------------------------------

procedure A_FlameEnd(actor: Pmobj_t);
begin
  actor.momz := actor.momz + $18000;
end;

//----------------------------------------------------------------------------
//
// PROC A_FloatPuff
//
//----------------------------------------------------------------------------

procedure A_FloatPuff(puff: Pmobj_t);
begin
  puff.momz := puff.momz + 117964;
end;

//---------------------------------------------------------------------------
//
// PROC A_GauntletAttack
//
//---------------------------------------------------------------------------

procedure A_GauntletAttack(player: Pplayer_t; psp: Ppspdef_t);
var
  angle: angle_t;
  damage: integer;
  slope: integer;
  randVal: integer;
  dist: fixed_t;
begin
  psp.sx := ((P_Random and 3) - 2) * FRACUNIT;
  psp.sy := WEAPONTOP + (P_Random and 3) * FRACUNIT;
  angle := player.mo.angle;
  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
  begin
    damage := HITDICE(2);
    dist := 4 * MELEERANGE;
    angle := angle + LongWord((P_Random - P_Random) * $20000);
    PuffType := MT_GAUNTLETPUFF2;
  end
  else
  begin
    damage := HITDICE(2);
    dist := MELEERANGE + 1;
    angle := angle + LongWord((P_Random - P_Random) * $40000);
    PuffType := MT_GAUNTLETPUFF1;
  end;
  slope := P_AimLineAttack(player.mo, angle, dist);
  P_LineAttack(player.mo, angle, dist, slope, damage);
  if linetarget = nil then
  begin
    if P_Random > 64 then
    begin
      if player.extralight > 0 then
        player.extralight := 0
      else
        player.extralight := 1;
    end;
    S_StartSound(player.mo, Ord(sfx_gntful));
    exit;
  end;
  randVal := P_Random;
  if randVal < 64 then
    player.extralight := 0
  else if randVal < 160 then
    player.extralight := 1
  else
    player.extralight := 2;

  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
  begin
    P_GiveBody(player, damage div 2);
    S_StartSound(player.mo, Ord(sfx_gntpow));
  end
  else
    S_StartSound(player.mo, Ord(sfx_gnthit));

  // turn to face target
  angle := R_PointToAngle2(player.mo.x, player.mo.y,  linetarget.x, linetarget.y);
  if angle - player.mo.angle > ANG180 then
  begin
    if angle - player.mo.angle < $FFFFFFFF - ANG90 div 20 then
      player.mo.angle := angle + ANG90 div 21
    else
      player.mo.angle := player.mo.angle - ANG90 div 20;
  end
  else
  begin
    if angle - player.mo.angle > ANG90 div 20 then
      player.mo.angle := angle - ANG90 div 21
    else
      player.mo.angle := player.mo.angle + ANG90 div 20;
  end;
  player.mo.flags := player.mo.flags or MF_JUSTATTACKED;
end;

//
// ?
//
procedure A_Light0(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 0;
end;

procedure A_Light1(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 1;
end;

procedure A_Light2(player: Pplayer_t; psp: Ppspdef_t);
begin
  player.extralight := 2;
end;

//
// P_SetupPsprites
// Called at start of level for each player.
//
procedure P_SetupPsprites(player: Pplayer_t);
var
  i: integer;
begin
  // remove all psprites
  for i := 0 to Ord(NUMPSPRITES) - 1 do
    player.psprites[i].state := nil;

  // spawn the gun
  player.pendingweapon := player.readyweapon;
  P_BringUpWeapon(player);
end;

//
// P_MovePsprites
// Called every tic by player thinking routine.
//
procedure P_MovePsprites(player: Pplayer_t);
var
  i: integer;
  psp: Ppspdef_t;
  state: Pstate_t;
begin
  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    psp := @player.psprites[i];
    // a null state means not active
    state := psp.state;
    if state <> nil then
    begin
      // drop tic count and possibly change state
      // a -1 tic count never changes
      if psp.tics <> -1 then
      begin
        psp.tics := psp.tics - 1;
        if psp.tics = 0 then
          P_SetPsprite(player, i, psp.state.nextstate);
      end;
    end;
  end;

  player.psprites[Ord(ps_flash)].sx := player.psprites[Ord(ps_weapon)].sx;
  player.psprites[Ord(ps_flash)].sy := player.psprites[Ord(ps_weapon)].sy;
end;

procedure P_UpdateBeak(player: Pplayer_t; psp: Ppspdef_t);
begin
  psp.sy := WEAPONTOP + _SHL(player.chickenPeck, FRACBITS - 1);
end;

//---------------------------------------------------------------------------
//
// PROC A_BeakReady
//
//---------------------------------------------------------------------------

procedure A_BeakReady(player: Pplayer_t; psp: Ppspdef_t);
begin
  if player.cmd.buttons and BT_ATTACK <> 0 then
  begin // Chicken beak attack
    player.attackdown := true;
    P_SetMobjState(player.mo, S_CHICPLAY_ATK1);
    if player.powers[Ord(pw_weaponlevel2)] <> 0 then
      P_SetPsprite(player, Ord(ps_weapon), S_BEAKATK2_1)
    else
      P_SetPsprite(player, Ord(ps_weapon), S_BEAKATK1_1);

    P_NoiseAlert(player.mo, player.mo);
  end
  else
  begin
    if player.mo.state = @states[Ord(S_CHICPLAY_ATK1)] then  // Take out of attack state
      P_SetMobjState(player.mo, S_CHICPLAY);
    player.attackdown := false;
  end;
end;

//---------------------------------------------------------------------------
//
// PROC P_ActivateBeak
//
//---------------------------------------------------------------------------

procedure P_ActivateBeak(player: Pplayer_t);
begin
  player.pendingweapon := wp_nochange;
  player.readyweapon := wp_beak;
  player.psprites[Ord(ps_weapon)].sy := WEAPONTOP;
  P_SetPsprite(player, Ord(ps_weapon), S_BEAKREADY);
end;

//---------------------------------------------------------------------------
//
// PROC P_PostChickenWeapon
//
//---------------------------------------------------------------------------

procedure P_PostChickenWeapon(player: Pplayer_t; weapon: weapontype_t);
begin
  if weapon = wp_beak then // Should never happen
    weapon := wp_staff;

  player.pendingweapon := wp_nochange;
  player.readyweapon := weapon;
  player.psprites[Ord(ps_weapon)].sy := WEAPONBOTTOM;
  P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev1info[Ord(weapon)].upstate));
end;

end.
