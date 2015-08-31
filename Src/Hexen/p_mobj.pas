//------------------------------------------------------------------------------
//
//  DelphiHexen: A modified and improved Hexen port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
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
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_mobj;

interface

//-----------------------------------------------------------------------------
//
// DESCRIPTION:
//  Map Objects, MObj, definition and handling.
//  Moving object handling. Spawn functions.
//
//-----------------------------------------------------------------------------

uses
  d_delphi,
  p_mobj_h,
  tables,
// We need the WAD data structure for Map things,
// from the THINGS lump.
  doomdata,
// States are tied to finite states are
//  tied to animation frames.
// Needs precompiled tables/data structures.
  info_h,
  m_fixed;

function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;

function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;

procedure P_ExplodeMissile(mo: Pmobj_t);

procedure P_ThrustMobj(mo: Pmobj_t; angle: angle_t; const move: fixed_t);

function P_FaceMobj(source: Pmobj_t; target: Pmobj_t; delta: Pangle_t): integer;

function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;

procedure P_XYMovement(mo: Pmobj_t);

procedure P_FloorBounceMissile(mo: Pmobj_t);

procedure P_MonsterFallingDamage(mo: Pmobj_t);

procedure P_ZMovement(mo: Pmobj_t);

procedure P_BlasterMobjThinker(mobj: Pmobj_t);

procedure P_PlayerLandedOnThing(mo: Pmobj_t; onmobj: Pmobj_t);

procedure P_MobjThinker(mobj: Pmobj_t);

function P_SpawnMobj(x: fixed_t; y: fixed_t; z: fixed_t; _type: integer): Pmobj_t;

procedure P_RemoveMobj(mobj: Pmobj_t);

procedure P_SpawnPlayer(mthing: Pmapthing_t);

procedure P_SpawnMapThing(mthing: Pmapthing_t);

procedure P_CreateTIDList;

procedure P_InsertMobjIntoTIDList(mobj: Pmobj_t; tid: integer);

procedure P_RemoveMobjFromTIDList(mobj: Pmobj_t);

function P_FindMobjFromTID(tid: integer; searchPosition: PInteger): Pmobj_t; overload;

function P_FindMobjFromTID(tid: integer; searchPosition: PInteger; var mo: Pmobj_t): Pmobj_t; overload;

procedure P_SpawnPuff(x, y, z: fixed_t);

procedure P_BloodSplatter(x, y, z: fixed_t; originator: Pmobj_t);

procedure P_BloodSplatter2(x, y, z: fixed_t; originator: Pmobj_t);

procedure P_RipperBlood(mo: Pmobj_t);

function P_HitFloor(thing: Pmobj_t): integer;

function P_CheckMissileSpawn(missile: Pmobj_t): boolean;

function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;

function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;

function P_SpawnMissileAngle(source: Pmobj_t; _type: integer; angle: angle_t;
  momz: fixed_t): Pmobj_t;

function P_SpawnMissileAngleSpeed(source: Pmobj_t; _type: integer;
  angle: angle_t; momz: fixed_t; speed: fixed_t): Pmobj_t;

function P_SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;

function P_SPMAngle(source: Pmobj_t; _type: integer; angle: angle_t): Pmobj_t;

function P_SPMAngleXYZ(source: Pmobj_t; x, y, z: fixed_t; _type: integer;
  angle: angle_t): Pmobj_t;

function P_SpawnKoraxMissile(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t;
  _type: integer): Pmobj_t;

function P_GetThingFloorType(thing: Pmobj_t): integer;

var
  iquehead: integer; // Initialized at p_setup
  iquetail: integer; // Initialized at p_setup

var
  PuffType: mobjtype_t;
  MissileMobj: Pmobj_t;

implementation

uses
  d_player,
  d_think,
  d_main,
  m_vectors,
  g_game,
  i_system,
  z_zone,
  m_rnd,
  doomdef,
  p_local,
  p_map,
  p_maputl,
  p_tick,
  p_pspr,
  p_setup,
  p_extra,
  p_user,
  p_inter,
  p_enemy,
  p_sounds,
  po_man,
  p_spec,
  r_defs,
  r_sky,
  r_main,
  r_data,
  hu_stuff,
  s_sound,
  sounds,
  s_sndseq,
  sb_bar,
  info,
  info_rnd,
  doomstat;

//
// P_SetMobjState
// Returns true if the mobj is still present.
//
function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
begin
  repeat
    if state = S_NULL then
    begin
      if mobj.flags_ex and MF_EX_DONOTREMOVE = 0 then // JVAL Do not remove missile
      begin
        mobj.state := nil;
        P_RemoveMobj(mobj);
      end;
      result := false;
      exit;
    end;

    st := @states[Ord(state)];
    mobj.state := st;
    mobj.tics := st.tics;
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;

    // Modified handling.
    // Call action functions when the state is set
    if Assigned(st.action.acp1) then
      st.action.acp1(mobj);

    state := st.nextstate;
  until mobj.tics <> 0;

  result := true;
end;

//----------------------------------------------------------------------------
//
// FUNC P_SetMobjStateNF
//
// Same as P_SetMobjState, but does not call the state function.
//
//----------------------------------------------------------------------------

function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
begin
  if state = S_NULL then
  begin // Remove mobj
    mobj.state := nil;
    P_RemoveMobj(mobj);
    result := false;
  end
  else
  begin
    st := @states[Ord(state)];
    mobj.state := st;
    mobj.tics := st.tics;
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;
    result := true;
  end;
end;

//
// P_ExplodeMissile
//
procedure P_ExplodeMissile(mo: Pmobj_t);
begin
  mo.momx := 0;
  mo.momy := 0;
  mo.momz := 0;

  P_SetMobjState(mo, statenum_t(mobjinfo[Ord(mo._type)].deathstate));

  mo.flags := mo.flags and (not MF_MISSILE);

  case mo._type of
    Ord(MT_SORCBALL1),
    Ord(MT_SORCBALL2),
    Ord(MT_SORCBALL3):
      S_StartSound(nil, Ord(SFX_SORCERER_BIGBALLEXPLODE));
    Ord(MT_SORCFX1):
      S_StartSound(nil, Ord(SFX_SORCERER_HEADSCREAM));
  else
    A_DeathSound(mo, mo);
  end;
end;


//----------------------------------------------------------------------------
//
// PROC P_ThrustMobj
//
//----------------------------------------------------------------------------
procedure P_ThrustMobj(mo: Pmobj_t; angle: angle_t; const move: fixed_t);
begin
  angle := angle shr ANGLETOFINESHIFT;
  mo.momx := mo.momx + FixedMul(move, finecosine[angle]);
  mo.momy := mo.momy + FixedMul(move, finesine[angle]);
end;


//----------------------------------------------------------------------------
//
// FUNC P_FaceMobj
//
// Returns 1 if 'source' needs to turn clockwise, or 0 if 'source' needs
// to turn counter clockwise.  'delta' is set to the amount 'source'
// needs to turn.
//
//----------------------------------------------------------------------------
function P_FaceMobj(source: Pmobj_t; target: Pmobj_t; delta: Pangle_t): integer;
var
  diff: angle_t;
  angle1: angle_t;
  angle2: angle_t;
begin
  angle1 := source.angle;
  angle2 := R_PointToAngle2(source.x, source.y, target.x, target.y);
  if angle2 > angle1 then
  begin
    diff := angle2 - angle1;
    if diff > ANG180 then
    begin
      delta^ := ANGLE_MAX - diff;
      result := 0;
    end
    else
    begin
      delta^ := diff;
      result := 1;
    end;
  end
  else
  begin
    diff := angle1 - angle2;
    if diff > ANG180 then
    begin
      delta^ := ANGLE_MAX - diff;
      result := 1;
    end
    else
    begin
      delta^ := diff;
      result := 0;
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// FUNC P_SeekerMissile
//
// The missile's tracer field must be the target.  Returns true if
// target was tracked, false if not.
//
//----------------------------------------------------------------------------
function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;
var
  dir: integer;
  dist: integer;
  delta: angle_t;
  angle: angle_t;
  target: Pmobj_t;
begin
  target := Pmobj_t(actor.special1);

  if target = nil then
  begin
    result := false;
    exit;
  end;

  if target.flags and MF_SHOOTABLE = 0 then
  begin // Target died
    actor.tracer := nil;
    result := false;
    exit;
  end;

  dir := P_FaceMobj(actor, target, @delta);
  if delta > thresh then
  begin
    delta := delta shr 1;
    if delta > turnMax then
      delta := turnMax;
  end;

  if dir <> 0 then // Turn clockwise
    actor.angle := actor.angle + delta
  else  // Turn counter clockwise
    actor.angle := actor.angle - delta;
  angle := actor.angle shr ANGLETOFINESHIFT;
  actor.momx := FixedMul(actor.info.speed, finecosine[angle]);
  actor.momy := FixedMul(actor.info.speed, finesine[angle]);

  if (actor.z + actor.height < target.z) or
     (target.z + target.height < actor.z) then
  begin // Need to seek vertically
    dist := P_AproxDistance(target.x - actor.x, target.y - actor.y);
    if actor.info.speed = 0 then
      dist := 1
    else
    begin
      dist := dist div actor.info.speed;
      if dist < 1 then
        dist := 1;
    end;
    actor.momz := ((target.z + target.height div 2) - (actor.z + actor.height div 2)) div dist;
  end;
  result := true;
end;

//
// P_XYMovement
//
const
  STOPSPEED = $1000;
  FRICTION_NORMAL = $e800;
  FRICTION_LOW = $f900;
  FRICTION_FLY = $eb00;
  windTab: array[0..2] of integer = (2048 * 5, 2048 * 10, 2048 * 25);

procedure P_XYMovement(mo: Pmobj_t);
var
  ptryx: fixed_t;
  ptryy: fixed_t;
  player: Pplayer_t;
  xmove: fixed_t;
  ymove: fixed_t;
  special: integer;
  angle: angle_t;
  speed: fixed_t;
  skip: boolean;
  rnd: longword;

  function SkyExplode: boolean;
  begin
    // Explode a missile
    if (ceilingline <> nil) and
       (ceilingline.backsector <> nil) and
       (ceilingline.backsector.ceilingpic = skyflatnum) then
    begin // Hack to prevent missiles exploding against the sky
      if mo._type = Ord(MT_BLOODYSKULL) then
      begin
        mo.momx := 0;
        mo.momy := 0;
        mo.momz := -FRACUNIT;
      end
      else if mo._type = Ord(MT_HOLY_FX) then
      begin
        P_ExplodeMissile(mo);
      end
      else
      begin
        P_RemoveMobj(mo);
      end;
      result := true;
      exit;
    end;
    P_ExplodeMissile(mo);
    result := false;
  end;

begin
  if (mo.momx = 0) and (mo.momy = 0) then
  begin
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.flags := mo.flags and (not MF_SKULLFLY);
      mo.momx := 0;
      mo.momy := 0;
      mo.momz := 0;

      P_SetMobjState(mo, statenum_t(mo.info.seestate));
    end;
    exit;
  end;

  special := Psubsector_t(mo.subsector).sector.special;
  if mo.flags2 and MF2_WINDTHRUST <> 0 then
  begin
    case special of
      40, 41, 42: // Wind_East
        P_ThrustMobj(mo, 0, windTab[special - 40]);
      43, 44, 45: // Wind_North
        P_ThrustMobj(mo, ANG90, windTab[special - 43]);
      46, 47, 48: // Wind_South
        P_ThrustMobj(mo, ANG270, windTab[special - 46]);
      49, 50, 51: // Wind_West
        P_ThrustMobj(mo, ANG180, windTab[special - 49]);
    end;
  end;

  player := mo.player;
  if mo.momx > MAXMOVE then
    mo.momx := MAXMOVE
  else if mo.momx < -MAXMOVE then
    mo.momx := -MAXMOVE;

  if mo.momy > MAXMOVE then
    mo.momy := MAXMOVE
  else if mo.momy < -MAXMOVE then
    mo.momy := -MAXMOVE;

  xmove := mo.momx;
  ymove := mo.momy;

  repeat
    if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) then
    begin
      ptryx := mo.x + xmove div 2;
      ptryy := mo.y + ymove div 2;
      xmove := _SHR1(xmove);
      ymove := _SHR1(ymove);
    end
    else
    begin
      ptryx := mo.x + xmove;
      ptryy := mo.y + ymove;
      xmove := 0;
      ymove := 0;
    end;

    if not P_TryMove(mo, ptryx, ptryy) then
    begin // Blocked move
      if mo.flags2 and MF2_SLIDE <> 0 then
      begin // Try to slide along it
        if BlockingMobj = nil then
        begin // Slide against wall
          P_SlideMove(mo);
        end
        else
        begin // Slide against mobj
          //if(P_TryMove(mo, mo.x, mo.y+mo.momy))
          if P_TryMove(mo, mo.x, ptryy) then
          begin
            mo.momx := 0;
          end
          //else if P_TryMove(mo, mo.x+mo.momx, mo.y))
          else if P_TryMove(mo, ptryx, mo.y) then
          begin
            mo.momy := 0;
          end
          else
          begin
            mo.momx := 0;
            mo.momy := 0;
          end;
        end;
      end
      else if mo.flags and MF_MISSILE <> 0 then
      begin
        if mo.flags2 and MF2_FLOORBOUNCE <> 0 then
        begin
          if BlockingMobj <> nil then
          begin
            if (BlockingMobj.flags2_ex and MF2_EX_REFLECTIVE <> 0) or
              ((BlockingMobj.player = nil) and
               (BlockingMobj.flags and MF_COUNTKILL = 0)) then
            begin
              rnd := P_Random;
              angle := R_PointToAngle2(BlockingMobj.x, BlockingMobj.y, mo.x, mo.y) +
                           ANG1 * ((rnd mod 16) - 8);
              speed := P_AproxDistance(mo.momx, mo.momy);
              speed := FixedMul(speed, 3 * FRACUNIT div 4);
              mo.angle := angle;
              angle := angle shr ANGLETOFINESHIFT;
              mo.momx := FixedMul(speed, finecosine[angle]);
              mo.momy := FixedMul(speed, finesine[angle]);
              A_SeeSound(mo, mo);
              exit;
            end
            else
            begin // Struck a player/creature
               P_ExplodeMissile(mo);
            end;
          end
          else
          begin // Struck a wall
            P_BounceWall(mo);
            case mo._type of
              Ord(MT_SORCBALL1),
              Ord(MT_SORCBALL2),
              Ord(MT_SORCBALL3),
              Ord(MT_SORCFX1):
                begin
                end;
            else
              A_SeeSound(mo, mo);
            end;
            exit;
          end;
        end;

        skip := false;
        if (BlockingMobj <> nil) and
           (BlockingMobj.flags2_ex and MF2_EX_REFLECTIVE <> 0) then
        begin
          angle := R_PointToAngle2(BlockingMobj.x, BlockingMobj.y, mo.x, mo.y);

          // Change angle for delflection/reflection
          case BlockingMobj._type of
            Ord(MT_CENTAUR),
            Ord(MT_CENTAURLEADER):
              begin
                if (angle - BlockingMobj.angle > ANG45) and (angle - BlockingMobj.angle < ANG315) then
                begin
                  if SkyExplode then
                    exit;
                  skip := true;
                end
                else if mo._type = Ord(MT_HOLY_FX) then
                begin
                  if SkyExplode then
                    exit;
                  skip := true;
                end;
                // Drop through to sorcerer full reflection
              end;
            Ord(MT_SORCBOSS):
              begin
                // Deflection
                if P_Random < 128 then
                  angle := angle + ANG45
                else
                  angle := angle - ANG45;
              end;
          else
            begin
              // Reflection
              rnd := P_Random;
              angle := angle + ANG1 * ((rnd mod 16) - 8);
            end; 
          end;

          if not skip then
          begin
            // Reflect the missile along angle
            mo.angle := angle;
            angle := angle shr ANGLETOFINESHIFT;
            mo.momx := FixedMul(_SHR1(mo.info.speed), finecosine[angle]);
            mo.momy := FixedMul(_SHR1(mo.info.speed), finesine[angle]);
            if mo.flags2 and MF2_SEEKERMISSILE <> 0 then
            begin
              mo.special1 := integer(mo.target);
            end;
            mo.target := BlockingMobj;
            exit;
          end;
        end;

        if SkyExplode then
          exit;
      end
      //else if mo.info.crashstate)
      //begin
      //  mo.momx := mo.momy := 0;
      //  P_SetMobjState(mo, mo.info.crashstate);
      //  return;
      //end;
      else
      begin
        mo.momx := 0;
        mo.momy := 0;
      end;
    end;
  until (xmove = 0) and (ymove = 0);

  // Friction

  if (player <> nil) and (player.cheats and CF_NOMOMENTUM <> 0) then
  begin // Debug option for no sliding at all
    mo.momx := 0;
    mo.momy := 0;
    exit;
  end;

  if mo.flags and (MF_MISSILE or MF_SKULLFLY) <> 0 then
  begin // No friction for missiles
    exit;
  end;

  if (mo.z > mo.floorz) and (mo.flags2 and MF2_FLY = 0) and (mo.flags2 and MF2_ONMOBJ = 0) then
  begin // No friction when falling
    if mo._type <> Ord(MT_BLASTEFFECT) then
      exit;
  end;
  if mo.flags and MF_CORPSE <> 0 then
  begin // Don't stop sliding if halfway off a step with some momentum
    if (mo.momx > FRACUNIT div 4) or (mo.momx < -FRACUNIT div 4) or
       (mo.momy > FRACUNIT div 4) or (mo.momy < -FRACUNIT div 4) then
    begin
      if mo.floorz <> Psubsector_t(mo.subsector).sector.floorheight then
        exit;
    end;
  end;

  if (mo.momx > -STOPSPEED) and (mo.momx < STOPSPEED) and
     (mo.momy > -STOPSPEED) and (mo.momy < STOPSPEED) and
     ((player = nil) or ((player.cmd.forwardmove = 0) and (player.cmd.sidemove = 0))) then
  begin // If in a walking frame, stop moving
    if player <> nil then
    begin
      if (integer(player.mo.state) - integer(@states[0])) div SizeOf(state_t) - Ord(PStateRun[Ord(player._class)]) < 4 then // JVAL SOS
        P_SetMobjState(player.mo, statenum_t(PStateNormal[Ord(player._class)]));
    end;
    mo.momx := 0;
    mo.momy := 0;
  end
  else
  begin
    if (mo.flags2 and MF2_FLY <> 0) and (mo.z >= mo.floorz) and
       (mo.flags2 and MF2_ONMOBJ = 0) then
    begin
      mo.momx := FixedMul(mo.momx, FRICTION_FLY);
      mo.momy := FixedMul(mo.momy, FRICTION_FLY);
    end
    else if P_GetThingFloorType(mo) = FLOOR_ICE then
    begin
      mo.momx := FixedMul(mo.momx, FRICTION_LOW);
      mo.momy := FixedMul(mo.momy, FRICTION_LOW);
    end
    else
    begin
      mo.momx := FixedMul(mo.momx, FRICTION_NORMAL);
      mo.momy := FixedMul(mo.momy, FRICTION_NORMAL);
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// PROC P_FloorBounceMissile
//
//----------------------------------------------------------------------------

procedure P_FloorBounceMissile(mo: Pmobj_t);
begin

  if P_HitFloor(mo) >= FLOOR_LIQUID then
  begin

    case mo._type of

      Ord(MT_SORCFX1),
      Ord(MT_SORCBALL1),
      Ord(MT_SORCBALL2),
      Ord(MT_SORCBALL3):
        begin
        end;

    else
      begin
        P_RemoveMobj(mo);
        exit;
      end;
    end;

  end;

  case mo._type of

    Ord(MT_SORCFX1):
      begin
        mo.momz := -mo.momz;    // no energy absorbed
      end;

    Ord(MT_SGSHARD1),
    Ord(MT_SGSHARD2),
    Ord(MT_SGSHARD3),
    Ord(MT_SGSHARD4),
    Ord(MT_SGSHARD5),
    Ord(MT_SGSHARD6),
    Ord(MT_SGSHARD7),
    Ord(MT_SGSHARD8),
    Ord(MT_SGSHARD9),
    Ord(MT_SGSHARD0):
      begin
        mo.momz := FixedMul(mo.momz, -19661);
        if (mo.momz < FRACUNIT div 2) and (mo.momz > -FRACUNIT div 2) then
        begin
          P_SetMobjState(mo, S_NULL);
          exit;
        end;
      end;

  else
    mo.momz := FixedMul(mo.momz, -45875);
  end;

  mo.momx := 2 * mo.momx div 3;
  mo.momy := 2 * mo.momy div 3;
  if mo.info.seesound <> 0 then
  begin
    case mo._type of
      Ord(MT_SORCBALL1),
      Ord(MT_SORCBALL2),
      Ord(MT_SORCBALL3):
        begin
          if mo.args[0] = 0 then
            A_SeeSound(mo, mo);
        end;
    else
      A_SeeSound(mo, mo);
    end;
    //S_StartSound(mo, mo.info.seesound);
  end;
//  P_SetMobjState(mo, mobjinfo[mo.type].deathstate);
end;


// Move this to p_inter ***
procedure P_MonsterFallingDamage(mo: Pmobj_t);
var
  damage: integer;
  mom: integer;
begin
  mom := abs(mo.momz);
  if mom > 35 * FRACUNIT then
  begin // automatic death
    damage := 10000;
  end
  else
  begin
    damage := FixedInt((mom - (23 * FRACUNIT)) * 6);
  end;
//  damage=10000;  // always kill 'em // JVAL SOS ????
  P_DamageMobj(mo, nil, nil, damage);
end;



//
//===============
//
// P_ZMovement
//
//===============
//

procedure P_ZMovement(mo: Pmobj_t);
var
  dist: integer;
  delta: integer;
  pl: Pplayer_t;
begin
//
// check for smooth step up
//
  pl := mo.player;
  if (pl <> nil) and (mo.z < mo.floorz) then
  begin
    pl.viewheight := pl.viewheight - mo.floorz - mo.z;
    pl.deltaviewheight := _SHR3(PVIEWHEIGHT - pl.viewheight);
  end;
//
// adjust height
//
  mo.z := mo.z + mo.momz;
  if (mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin  // float down towards target if too close
    if (mo.flags and MF_SKULLFLY = 0) and (mo.flags and MF_INFLOAT = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);
      delta := mo.target.z + _SHR1(mo.height) - mo.z;
      if (delta < 0) and (dist < -(delta * 3)) then
        mo.z := mo.z - FLOATSPEED
      else if (delta > 0) and (dist < (delta * 3)) then
        mo.z := mo.z + FLOATSPEED;
    end;
  end;
  if (mo.player <> nil) and
     (mo.flags2 and MF2_FLY <> 0) and
     (mo.z > mo.floorz) and
     (leveltime and 2 <> 0) then
  begin
    mo.z := mo.z + finesine[(FINEANGLES div 20 * _SHR2(leveltime)) and FINEMASK];
  end;

//
// clip movement
//
  if mo.z <= mo.floorz then
  begin  // Hit the floor
    if mo.flags and MF_MISSILE <> 0 then
    begin
      mo.z := mo.floorz;
      if mo.flags2 and MF2_FLOORBOUNCE <> 0 then
      begin
        P_FloorBounceMissile(mo);
        exit;
      end
      else if mo._type = Ord(MT_HOLY_FX) then
      begin // The spirit struck the ground
        mo.momz := 0;
        P_HitFloor(mo);
        exit;
      end
      else if (mo._type = Ord(MT_MNTRFX2)) or (mo._type = Ord(MT_LIGHTNING_FLOOR)) then
      begin // Minotaur floor fire can go up steps
        exit;
      end
      else
      begin
        P_HitFloor(mo);
        P_ExplodeMissile(mo);
        exit;
      end;
    end;

    if (mo.flags and MF_COUNTKILL <> 0) then  // Blasted mobj falling
    begin
      if mo.momz < -(23 * FRACUNIT) then
      begin
        P_MonsterFallingDamage(mo);
      end;
    end;

    if mo.z - mo.momz > mo.floorz then
    begin // Spawn splashes, etc.
      P_HitFloor(mo);
    end;

    mo.z := mo.floorz;
    if mo.momz < 0 then
    begin
      if (mo.flags2 and MF2_ICEDAMAGE <> 0) and (mo.momz < -GRAVITY * 8) then
      begin
        mo.tics := 1;
        mo.momx := 0;
        mo.momy := 0;
        mo.momz := 0;
        exit;
      end;
      if pl <> nil then
      begin
        pl.jumpTics := 7;// delay any jumping for a short time
        if (mo.momz < -GRAVITY * 8) and (mo.flags2 and MF2_FLY = 0) then
        begin // squat down
          pl.deltaviewheight := _SHR3(mo.momz);
          if mo.momz < -23 * FRACUNIT then
          begin
            P_FallingDamage(mo.player);
            P_NoiseAlert(mo, mo);
          end
          else if (mo.momz < -GRAVITY * 12) and (pl.morphTics = 0) then
          begin
            S_StartSound(mo, Ord(SFX_PLAYER_LAND));

            case pl._class of

              PCLASS_FIGHTER:
                begin
                  S_StartSound(mo, Ord(SFX_PLAYER_FIGHTER_GRUNT));
                end;

              PCLASS_CLERIC:
                begin
                  S_StartSound(mo, Ord(SFX_PLAYER_CLERIC_GRUNT));
                end;

              PCLASS_MAGE:

                begin
                  S_StartSound(mo, Ord(SFX_PLAYER_MAGE_GRUNT));
                end;

            end;
          end
          else if (P_GetThingFloorType(mo) < FLOOR_LIQUID) and
                  (pl.morphTics = 0) then
          begin
            S_StartSound(mo, Ord(SFX_PLAYER_LAND));
          end;
          pl.centering := true;
        end;
      end
      else if (mo._type >= Ord(MT_POTTERY1)) and
              (mo._type <= Ord(MT_POTTERY3)) then
      begin
        P_DamageMobj(mo, nil, nil, 25);
      end
      else if mo.flags and MF_COUNTKILL <> 0 then
      begin
        if mo.momz < -23 * FRACUNIT then
        begin
          // Doesn't get here
        end;
      end;
      mo.momz := 0;
    end;

    if mo.flags and MF_SKULLFLY <> 0 then
    begin // The skull slammed into something
      mo.momz := -mo.momz;
    end;

    if (mo.info.crashstate <> 0) and
       (mo.flags and MF_CORPSE <> 0) and
       (mo.flags2 and MF2_ICEDAMAGE = 0) then
    begin
      P_SetMobjState(mo, statenum_t(mo.info.crashstate));
      exit;
    end;
  end
  else if (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0) then
  begin
    if mo.momz = 0 then
      mo.momz := -(GRAVITY div 4)
    else
      mo.momz := mo.momz - GRAVITY div 8;
  end
  else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -(GRAVITY div 2)
    else
      mo.momz := mo.momz - GRAVITY div 4;
  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -GRAVITY * 2
    else
      mo.momz := mo.momz - GRAVITY;
  end;

  if mo.z + mo.height > mo.ceilingz then
  begin  // hit the ceiling
    if mo.momz > 0 then
      mo.momz := 0;
    mo.z := mo.ceilingz - mo.height;
    if mo.flags2 and MF2_FLOORBOUNCE <> 0 then
    begin
      // Maybe reverse momentum here for ceiling bounce
      // Currently won't happen

      A_SeeSound(mo, mo);
      exit;
    end;

    if mo.flags and MF_SKULLFLY <> 0 then
    begin  // the skull slammed into something
      mo.momz := -mo.momz;
    end;

    if mo.flags and MF_MISSILE <> 0 then
    begin
      if mo._type = Ord(MT_LIGHTNING_CEILING) then
      begin
        exit;
      end;

      if Psubsector_t(mo.subsector).sector.ceilingpic = skyflatnum then
      begin
        if mo._type = Ord(MT_BLOODYSKULL) then
        begin
          mo.momx := 0;
          mo.momy := 0;
          mo.momz := -FRACUNIT;
        end
        else if mo._type = Ord(MT_HOLY_FX) then
        begin
          P_ExplodeMissile(mo);
        end
        else
        begin
          P_RemoveMobj(mo);
        end;
        exit;
      end;
      P_ExplodeMissile(mo);
      exit;
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// PROC P_BlasterMobjThinker
//
//
//----------------------------------------------------------------------------

procedure P_BlasterMobjThinker(mobj: Pmobj_t);
var
  i: integer;
  xfrac: fixed_t;
  yfrac: fixed_t;
  zfrac: fixed_t;
  z: fixed_t;
  changexy: boolean;
  mo: Pmobj_t;
begin

  // Handle movement
  if (mobj.momx <> 0) or (mobj.momy <> 0) or
     (mobj.z <> mobj.floorz) or (mobj.momz <> 0) then
  begin
    xfrac := _SHR3(mobj.momx);
    yfrac := _SHR3(mobj.momy);
    zfrac := _SHR3(mobj.momz);
    changexy := (xfrac <> 0) or (yfrac <> 0);

    for i := 0 to 7 do
    begin
      if changexy then
      begin
        if not P_TryMove(mobj, mobj.x + xfrac, mobj.y + yfrac) then
        begin // Blocked move
          P_ExplodeMissile(mobj);
          exit;
        end;
      end;

      mobj.z := mobj.z + zfrac;
      if mobj.z <= mobj.floorz then
      begin // Hit the floor
        mobj.z := mobj.floorz;
        P_HitFloor(mobj);
        P_ExplodeMissile(mobj);
        exit;
      end;

      if mobj.z + mobj.height > mobj.ceilingz then
      begin // Hit the ceiling
        mobj.z := mobj.ceilingz - mobj.height;
        P_ExplodeMissile(mobj);
        exit;
      end;

      if changexy then
      begin
        if (mobj._type = Ord(MT_MWAND_MISSILE)) and (P_Random < 128) then
        begin
          z := mobj.z - 8 * FRACUNIT;
          if z < mobj.floorz then
          begin
            z := mobj.floorz;
          end;
          P_SpawnMobj(mobj.x, mobj.y, z, Ord(MT_MWANDSMOKE));
        end
        else
        begin
          if mobj.special1 = 0 then // JVAL SOS
          begin
            mobj.special1 := 4;
            z := mobj.z - 12 * FRACUNIT;
            if z < mobj.floorz then
            begin
              z := mobj.floorz;
            end;
            mo := P_SpawnMobj(mobj.x, mobj.y, z, Ord(MT_CFLAMEFLOOR));
            if mo <> nil then
            begin
              mo.angle := mobj.angle;
            end;
          end;
          dec(mobj.special1);
        end;
      end;
    end;
  end;
  // Advance the state
  if mobj.tics <> -1 then
  begin
    dec(mobj.tics);
    while mobj.tics = 0 do
    begin
      if not P_SetMobjState(mobj, mobj.state.nextstate) then
      begin // mobj was removed
        exit;
      end;
    end;
  end;
end;

//===========================================================================
//
// P_PlayerLandedOnThing
//
//===========================================================================

procedure P_PlayerLandedOnThing(mo: Pmobj_t; onmobj: Pmobj_t);
var
  pl: Pplayer_t;
begin
  pl := mo.player;
  if pl = nil then
    exit;

  pl.deltaviewheight := _SHR3(mo.momz);
  if mo.momz < -23 * FRACUNIT then
  begin
    P_FallingDamage(mo.player);
    P_NoiseAlert(mo, mo);
  end
  else if (mo.momz < -GRAVITY * 12) and
          (pl.morphTics = 0) then
  begin
    S_StartSound(mo, Ord(SFX_PLAYER_LAND));

    case pl._class of

      PCLASS_FIGHTER:
         begin
          S_StartSound(mo, Ord(SFX_PLAYER_FIGHTER_GRUNT));
        end;

      PCLASS_CLERIC:
        begin
          S_StartSound(mo, Ord(SFX_PLAYER_CLERIC_GRUNT));
        end;

      PCLASS_MAGE:
        begin
          S_StartSound(mo, Ord(SFX_PLAYER_MAGE_GRUNT));
        end;

    end;
  end
  else if pl.morphTics = 0 then
  begin
    S_StartSound(mo, Ord(SFX_PLAYER_LAND));
  end;

  pl.centering := true;
end;

//----------------------------------------------------------------------------
//
// PROC P_MobjThinker
//
//----------------------------------------------------------------------------

procedure P_MobjThinker(mobj: Pmobj_t);
var
  onmo: Pmobj_t;
  pl: Pplayer_t;
begin
  // JVAL: Clear just spawned flag
  mobj.flags := mobj.flags and (not MF_JUSTAPPEARED);

  // Handle X and Y momentums
  BlockingMobj := nil;
  if (mobj.momx <> 0) or (mobj.momy <> 0) or (mobj.flags and MF_SKULLFLY <> 0) then
  begin
    P_XYMovement(mobj);
    if not Assigned(mobj.thinker._function.acp1) then
    begin // mobj was removed
      exit;
    end;
  end
  else if mobj.flags2 and MF2_BLASTED <> 0 then
  begin // Reset to not blasted when momentums are gone
    P_ResetBlasted(mobj);
  end;
  if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then
  begin // Floating item bobbing motion (special1 is height)
    mobj.z := mobj.floorz +
              mobj.special1 +
              FloatBobOffsets[(mobj.health) and 63];
    inc(mobj.health);
  end
  else if (mobj.z <> mobj.floorz) or (mobj.momz <> 0) or (BlockingMobj <> nil) then
  begin  // Handle Z momentum and gravity
    if mobj.flags2 and MF2_PASSMOBJ <> 0 then
    begin
      onmo := P_CheckOnmobj(mobj);
      if onmo = nil then
      begin
        P_ZMovement(mobj);
        if (mobj.player <> nil) and (mobj.flags and MF2_ONMOBJ <> 0) then
        begin
          mobj.flags2 := mobj.flags2 and not MF2_ONMOBJ;
        end;
      end
      else
      begin
        pl := mobj.player;
        if pl <> nil then
        begin
          if (mobj.momz < -GRAVITY * 8) and (mobj.flags2 and MF2_FLY = 0) then
          begin
            P_PlayerLandedOnThing(mobj, onmo);
          end;
          if onmo.z + onmo.height - mobj.z <= 24 * FRACUNIT then
          begin
            pl.viewheight := pl.viewheight - onmo.z + onmo.height - mobj.z;
            pl.deltaviewheight := _SHR3(PVIEWHEIGHT - pl.viewheight);
            mobj.z := onmo.z + onmo.height;
            mobj.flags2 := mobj.flags2 or MF2_ONMOBJ;
            mobj.momz := 0;
          end
          else
          begin // hit the bottom of the blocking mobj
            mobj.momz := 0;
          end;
        end;
      end;
    end
    else
    begin
      P_ZMovement(mobj);
    end;

    if not Assigned(mobj.thinker._function.acp1) then
    begin // mobj was removed
      exit;
    end;
  end;

  // Cycle through states, calling action functions at transitions
  if mobj.tics <> -1 then
  begin
    dec(mobj.tics);
    // you can cycle through multiple states in a tic
    while mobj.tics = 0 do
    begin
      if not P_SetMobjState(mobj, mobj.state.nextstate) then
      begin // mobj was removed
        exit;
      end;
    end;
  end;
end;

//==========================================================================
//
// P_SpawnMobj
//
//==========================================================================

function P_SpawnMobj(x: fixed_t; y: fixed_t; z: fixed_t; _type: integer): Pmobj_t;
var
  mobj: Pmobj_t;
  st: Pstate_t;
  info: Pmobjinfo_t;
  space: fixed_t;
  sec: Psector_t;
begin
  mobj := Z_Malloc(SizeOf(mobj_t), PU_LEVEL, nil);
  memset(mobj, 0, SizeOf(mobj_t));
  info := @mobjinfo[_type];
  mobj._type := _type;
  mobj.info := info;
  mobj.x := x;
  mobj.y := y;
  mobj.radius := info.radius;
  mobj.height := info.height;
  mobj.flags := info.flags;
  mobj.flags2 := info.flags2;
  mobj.damage := info.damage;
  mobj.health := info.spawnhealth;
  if gameskill <> sk_nightmare then
  begin
    mobj.reactiontime := info.reactiontime;
  end;
  mobj.lastlook := P_Random mod MAXPLAYERS;

  // Set the state, but do not use P_SetMobjState, because action
  // routines can't be called yet.  If the spawnstate has an action
  // routine, it will not be called.
  st := @states[info.spawnstate];
  mobj.state := st;
  mobj.tics := st.tics;
  mobj.sprite := st.sprite;
  mobj.frame := st.frame;

  // Set subsector and/or block links.
  P_SetThingPosition(mobj);
  sec := Psubsector_t(mobj.subsector).sector;
  mobj.floorz := sec.floorheight;
  mobj.ceilingz := sec.ceilingheight;
  if z = ONFLOORZ then
  begin
    mobj.z := mobj.floorz;
  end
  else if z = ONCEILINGZ then
  begin
    mobj.z := mobj.ceilingz - mobj.info.height;
  end
  else if z = FLOATRANDZ then
  begin
    space := mobj.ceilingz - mobj.info.height - mobj.floorz;
    if space > 48 * FRACUNIT then
    begin
      space := space - 40 * FRACUNIT;
      mobj.z := _SHR8(space * P_Random) + mobj.floorz + 40 * FRACUNIT;
    end
    else
    begin
      mobj.z := mobj.floorz;
    end;
  end
  else if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then
  begin
    mobj.z := mobj.floorz + z;    // artifact z passed in as height
  end
  else
  begin
    mobj.z := z;
  end;
  if (mobj.flags2 and MF2_FLOORCLIP <> 0) and
     (P_GetThingFloorType(mobj) >= FLOOR_LIQUID) and
     (mobj.z = sec.floorheight) then
  begin
    mobj.floorclip := 10 * FRACUNIT;
  end
  else
  begin
    mobj.floorclip := 0;
  end;

  mobj.thinker._function.acp1 := @P_MobjThinker;
  P_AddThinker(@mobj.thinker);
  result := mobj;
end;

//==========================================================================
//
// P_RemoveMobj
//
//==========================================================================

procedure P_RemoveMobj(mobj: Pmobj_t);
begin
  // Remove from creature queue
  if (mobj.flags and MF_COUNTKILL <> 0) and
     (mobj.flags and MF_CORPSE <> 0) then
  begin
    A_DeQueueCorpse(mobj);
  end;

  if mobj.tid <> 0 then
  begin // Remove from TID list
    P_RemoveMobjFromTIDList(mobj);
  end;

  // Unlink from sector and block lists
  P_UnsetThingPosition(mobj);

  // Stop any playing sound
  S_StopSound(mobj);

  // Free block
  P_RemoveThinker(Pthinker_t(mobj));
end;

//==========================================================================
//
// P_SpawnPlayer
//
// Called when a player is spawned on the level.  Most of the player
// structure stays unchanged between levels.
//
//==========================================================================

procedure P_SpawnPlayer(mthing: Pmapthing_t);
var
  p: Pplayer_t;
  x, y, z: fixed_t;
  mobj: Pmobj_t;
begin
  if not playeringame[mthing._type - 1] then
  begin // Not playing
    exit;
  end;

  p := @players[mthing._type - 1];
  if p.playerstate = PST_REBORN then
    G_PlayerReborn(mthing._type - 1);

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;
  z := ONFLOORZ;
  if randomclass and (deathmatch <> 0) then
  begin
    p._class := Pclass_t(P_Random mod 3);
    if p._class = PlayerClass[mthing._type - 1] then
    begin
      p._class := Pclass_t((Ord(p._class) + 1) mod 3);
    end;
    PlayerClass[mthing._type - 1] := p._class;
    SB_SetClassData;
  end
  else
  begin
    p._class := PlayerClass[mthing._type - 1];
  end;

  case p._class of
    PCLASS_FIGHTER:
      mobj := P_SpawnMobj(x, y, z, Ord(MT_PLAYER_FIGHTER));
    PCLASS_CLERIC:
      mobj := P_SpawnMobj(x, y, z, Ord(MT_PLAYER_CLERIC));
    PCLASS_MAGE:
      mobj := P_SpawnMobj(x, y, z, Ord(MT_PLAYER_MAGE));
  else
    begin
      I_Error('P_SpawnPlayer(): Unknown class type');
      mobj := nil;
    end;
  end;

  // Set translation table data
  if (p._class = PCLASS_FIGHTER) and ((mthing._type = 1) or (mthing._type = 3)) then
  begin
    // The first type should be blue, and the third should be the
    // Fighter's original gold color
    if mthing._type = 1 then
    begin
      mobj.flags := mobj.flags or (2 shl MF_TRANSSHIFT);
    end;
  end
  else if mthing._type > 1 then
  begin // Set color translation bits for player sprites
    mobj.flags := mobj.flags or _SHL(mthing._type - 1, MF_TRANSSHIFT);
  end;

  mobj.angle := ANG45 * (mthing.angle div 45);
  mobj.player := p;
  mobj.health := p.health;
  p.mo := mobj;
  p.playerstate := PST_LIVE;
  p.refire := 0;
  P_ClearMessage(p);
  p.damagecount := 0;
  p.bonuscount := 0;
  p.poisoncount := 0;
  p.morphTics := 0;
  p.extralight := 0;
  p.fixedcolormap := 0;
  p.viewheight := PVIEWHEIGHT;
  P_SetupPsprites(p);
  if deathmatch <> 0 then
  begin // Give all keys in death match mode
    p.keys := 2047;
  end;

  if mthing._type = 1 then
  begin
    // wake up the heads up text
    HU_Start;

    p_justspawned := true;
  end;

end;

//==========================================================================
//
// P_SpawnMapThing
//
// The fields of the mapthing should already be in host byte order.
//
//==========================================================================
const
  classFlags: array[0..2] of integer = (
    MTF_FIGHTER,
    MTF_CLERIC,
    MTF_MAGE
  );

procedure P_SpawnMapThing(mthing: Pmapthing_t);
var
  i: integer;
  spawnMask: integer;
  mobj: Pmobj_t;
  x, y, z: fixed_t;
begin
  // Count deathmatch start positions
  if mthing._type = 11 then
  begin
    if deathmatch_p < MAX_DEATHMATCH_STARTS then
    begin
      memcpy(@deathmatchstarts[deathmatch_p], mthing, SizeOf(mthing^));
      inc(deathmatch_p);
    end;
    exit;
  end;

  if mthing._type = PO_ANCHOR_TYPE then
  begin // Polyobj Anchor Pt.
    exit;
  end
  else if (mthing._type = PO_SPAWN_TYPE) or
          (mthing._type = PO_SPAWNCRUSH_TYPE) then
  begin // Polyobj Anchor Pt.
    inc(po_NumPolyobjs);
    exit;
  end;

  // check for players specially
  if mthing._type <= 4 then
  begin
    // save spots for respawning in network games
    playerstarts[mthing.arg1, mthing._type - 1] := mthing^;
    if (deathmatch = 0) and (mthing.arg1 = 0) then
      P_SpawnPlayer(mthing);
    exit;
  end;

  // Check for player starts 5 to 8
  if (mthing._type >= 9100) and (mthing._type <= 9103) then
  begin
    mthing._type := 5 + mthing._type - 9100;  // Translate to 5 - 8
    playerstarts[mthing.arg1, mthing._type - 1] := mthing^;
    if (deathmatch = 0) and (mthing.arg1 = 0) then
      P_SpawnPlayer(mthing);
    exit;
  end;

  if (mthing._type >= 1400) and (mthing._type < 1410) then
  begin
    R_PointInSubsector(mthing.x * FRACUNIT, mthing.y * FRACUNIT).sector.seqType := seqtype_t(mthing._type - 1400);
    exit;
  end;

  // Check current game type with spawn flags
  if not netgame then
  begin
    spawnMask := MTF_GSINGLE;
  end
  else if deathmatch <> 0 then
  begin
    spawnMask := MTF_GDEATHMATCH;
  end
  else
  begin
    spawnMask := MTF_GCOOP;
  end;

  if mthing.options and spawnMask = 0 then
    exit;

  // Check current skill with spawn flags
  if (gameskill = sk_baby) or (gameskill = sk_easy) then
    spawnMask := MTF_EASY
  else if (gameskill = sk_hard) or (gameskill = sk_nightmare) then
    spawnMask := MTF_HARD
  else
    spawnMask := MTF_NORMAL;
  if mthing.options and spawnMask = 0 then
    exit;

  // Check current character classes with spawn flags
  if not netgame then
  begin // Single player
    if mthing.options and classFlags[Ord(PlayerClass[0])] = 0 then
    begin // Not for current class
      exit;
    end;
  end
  else if deathmatch = 0 then
  begin // Cooperative
    spawnMask := 0;
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if playeringame[i] then
      begin
        spawnMask := spawnMask or classFlags[Ord(PlayerClass[i])];
      end;
    end;
    if mthing.options and spawnMask = 0 then
      exit;
  end;

  // find which type to spawn
  i := 0;
  while i < nummobjtypes do
  begin
    if mthing._type = mobjinfo[i].doomednum then
      break;
    inc(i);
  end;

  if i = nummobjtypes then
    I_Error('P_SpawnMapThing(): Unknown type %d at (%d, %d)',
      [mthing._type, mthing.x, mthing.y]);

  // don't spawn keycards and players in deathmatch
  if (deathmatch <> 0) and ((mobjinfo[i].flags and MF_NOTDMATCH) <> 0) then
    exit;

  // don't spawn any monsters if -nomonsters
  if nomonsters and (mobjinfo[i].flags and MF_COUNTKILL <> 0) then
    exit;

  // spawn it
  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  // JVAL
  // Random map enemies
  if spawnrandommonsters and Info_IsMonster(i) then
    i := Info_SelectRandomMonster(i);

  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else if (mobjinfo[i].flags2 and MF2_SPAWNFLOAT <> 0) or (mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0) then
    z := FLOATRANDZ
  else if (mobjinfo[i].flags2 and MF2_FLOATBOB <> 0) or (mobjinfo[i].flags_ex and MF_EX_FLOATBOB <> 0) then
    z := mthing.height * FRACUNIT
  else
  begin
    z := ONFLOORZ;
  end;


  // Special stuff
  if i = Ord(MT_ZLYNCHED_NOHEART) then
    P_SpawnMobj(x, y, ONFLOORZ, Ord(MT_BLOODPOOL));

  mobj := P_SpawnMobj(x, y, z, i);
  if z = ONFLOORZ then
    mobj.z := mobj.z + mthing.height * FRACUNIT
  else if z = ONCEILINGZ then
    mobj.z := mobj.z - mthing.height *FRACUNIT;

  mobj.tid := mthing.tid;
  mobj.special := mthing.special;
  mobj.args[0] := mthing.arg1;
  mobj.args[1] := mthing.arg2;
  mobj.args[2] := mthing.arg3;
  mobj.args[3] := mthing.arg4;
  mobj.args[4] := mthing.arg5;
  if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then
  begin // Seed random starting index for bobbing motion
    mobj.health := P_Random;
    mobj.special1 := mthing.height * FRACUNIT;
  end;

  if mobj.tics > 0 then
    mobj.tics := 1 + (P_Random mod mobj.tics);

  if mobj.flags and MF_COUNTKILL <> 0 then
  begin
    // Quantize angle to 45 degree increments
    mobj.angle := ANG45 * (mthing.angle div 45);
  end
  else
  begin
    // Scale angle correctly (source is 0..359)
    mobj.angle := _SHL((mthing.angle * 256) div 360, 24);
  end;

  if mthing.options and MTF_AMBUSH <> 0 then
    mobj.flags := mobj.flags or MF_AMBUSH;

  if mthing.options and MTF_DORMANT <> 0 then
  begin
    mobj.flags2 := mobj.flags2 or MF2_DORMANT;
    if mobj._type = Ord(MT_ICEGUY) then
      P_SetMobjState(mobj, S_ICEGUY_DORMANT);
    mobj.tics := -1;
  end;
end;

//==========================================================================
//
// P_CreateTIDList
//
//==========================================================================

const
  MAX_TID_COUNT = 200;

var
  TIDList: array[0..MAX_TID_COUNT] of integer; // +1 for termination marker
  TIDMobj: array[0..MAX_TID_COUNT] of Pmobj_t;

procedure P_CreateTIDList;
var
  i: integer;
  mobj: Pmobj_t;
  t: Pthinker_t;
begin
  i := 0;
  t := thinkercap.next;
  while t <> @thinkercap do
  begin // Search all current thinkers
    if @t._function.acp1 <> @P_MobjThinker then
    begin // Not a mobj thinker
      t := t.next;
      continue;
    end;

    mobj := Pmobj_t(t);
    if mobj.tid <> 0 then
    begin // Add to list
      if i = MAX_TID_COUNT then
        I_Error('P_CreateTIDList(): MAX_TID_COUNT (%d) exceeded.', [MAX_TID_COUNT]);
      TIDList[i] := mobj.tid;
      TIDMobj[i] := mobj;
      inc(i);
    end;
    t := t.next;
  end;
  // Add termination marker
  TIDList[i] := 0;
end;

//==========================================================================
//
// P_InsertMobjIntoTIDList
//
//==========================================================================

procedure P_InsertMobjIntoTIDList(mobj: Pmobj_t; tid: integer);
var
  i: integer;
  index: integer;
begin
  index := -1;
  i := 0;
  while TIDList[i] <> 0 do
  begin
    if TIDList[i] = -1 then
    begin // Found empty slot
      index := i;
      break;
    end;
    inc(i);
  end;

  if index = -1 then
  begin // Append required
    if i = MAX_TID_COUNT then
      I_Error('P_InsertMobjIntoTIDList(): MAX_TID_COUNT (%d) exceeded.', [MAX_TID_COUNT]);
    index := i;
    TIDList[index + 1] := 0;
  end;
  mobj.tid := tid;
  TIDList[index] := tid;
  TIDMobj[index] := mobj;
end;

//==========================================================================
//
// P_RemoveMobjFromTIDList
//
//==========================================================================

procedure P_RemoveMobjFromTIDList(mobj: Pmobj_t);
var
  i: integer;
begin
  i := 0;
  while TIDList[i] <> 0 do
  begin
    if TIDMobj[i] = mobj then
    begin
      TIDList[i] := -1;
      TIDMobj[i] := nil;
      mobj.tid := 0;
      exit;
    end;
    inc(i);
  end;
  mobj.tid := 0;
end;

//==========================================================================
//
// P_FindMobjFromTID
//
//==========================================================================

function P_FindMobjFromTID(tid: integer; searchPosition: PInteger): Pmobj_t;
var
  i: integer;
begin
  i := searchPosition^ + 1;
  while TIDList[i] <> 0 do
  begin
    if TIDList[i] = tid then
    begin
      searchPosition^ := i;
      result := TIDMobj[i];
      exit;
    end;
    inc(i);
  end;
  searchPosition^ := -1;
  result := nil;
end;

function P_FindMobjFromTID(tid: integer; searchPosition: PInteger; var mo: Pmobj_t): Pmobj_t;
begin
  result := P_FindMobjFromTID(tid, searchPosition);
  mo := result;
end;

//
//===============================================================================
//
//            GAME SPAWN FUNCTIONS
//
//===============================================================================
//

//---------------------------------------------------------------------------
//
// PROC P_SpawnPuff
//
//---------------------------------------------------------------------------

procedure P_SpawnPuff(x, y, z: fixed_t);
var
  puff: Pmobj_t;
begin
  z := z + (P_Random - P_Random) * 1024;
  puff := P_SpawnMobj(x, y, z, Ord(PuffType));
  if (linetarget <> nil) and (puff.info.seesound <> 0) then
  begin // Hit thing sound
    A_SeeSound(puff, puff);
  end
  else
    A_AttackSound(puff, puff);

  case PuffType of
    MT_PUNCHPUFF:
      puff.momz := FRACUNIT;
    MT_HAMMERPUFF:
      puff.momz := 52429;
  end;

  PuffSpawned := puff;
end;

//---------------------------------------------------------------------------
//
// PROC P_BloodSplatter
//
//---------------------------------------------------------------------------

procedure P_BloodSplatter(x, y, z: fixed_t; originator: Pmobj_t);
var
  mo: Pmobj_t;
begin
  mo := P_SpawnMobj(x, y, z, Ord(MT_BLOODSPLATTER));
  mo.target := originator;
  mo.momx := (P_Random - P_Random) * 1024;
  mo.momy := (P_Random - P_Random) * 1024;
  mo.momz := 3 * FRACUNIT;
end;

//===========================================================================
//
//  P_BloodSplatter2
//
//===========================================================================

procedure P_BloodSplatter2(x, y, z: fixed_t; originator: Pmobj_t);
var
  mo: Pmobj_t;
begin
  mo := P_SpawnMobj(x + _SHL(P_Random - 128, 11), y + _SHL(P_Random - 128, 11), z, Ord(MT_AXEBLOOD));
  mo.target := originator;
end;

//---------------------------------------------------------------------------
//
// PROC P_RipperBlood
//
//---------------------------------------------------------------------------

procedure P_RipperBlood(mo: Pmobj_t);
var
  th: Pmobj_t;
  x, y, z: fixed_t;
begin
  x := mo.x + (P_Random - P_Random) * 4096;
  y := mo.y + (P_Random - P_Random) * 4096;
  z := mo.z + (P_Random - P_Random) * 4096;
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD));
  th.momx := _SHR1(mo.momx);
  th.momy := _SHR1(mo.momy);
  th.tics := th.tics + P_Random mod 3;
end;

//---------------------------------------------------------------------------
//
// FUNC P_HitFloor
//
//---------------------------------------------------------------------------
const
  SMALLSPLASHCLIP = 12 * FRACUNIT;

function P_HitFloor(thing: Pmobj_t): integer;
var
  mo: Pmobj_t;
  smallsplash: boolean;
begin
  if thing.floorz <> Psubsector_t(thing.subsector).sector.floorheight then
  begin // don't splash if landing on the edge above water/lava/etc....
    result := FLOOR_SOLID;
    exit;
  end;

  // Things that don't splash go here
  case thing._type of
    Ord(MT_LEAF1),
    Ord(MT_LEAF2),
    Ord(MT_SPLASH),
    Ord(MT_SLUDGECHUNK):
      begin
        result := FLOOR_SOLID;
        exit;
      end;
  end;

  smallsplash := false;
  // Small splash for small masses
  if thing.info.mass < 10 then
    smallsplash := true;

  case P_GetThingFloorType(thing) of
    FLOOR_WATER:
      begin
        if smallsplash then
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SPLASHBASE));
          if mo <> nil then
            mo.floorclip := mo.floorclip + SMALLSPLASHCLIP;
          S_StartSound(mo, Ord(SFX_AMBIENT10));  // small drip
        end
        else
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SPLASH));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := 2 * FRACUNIT + P_Random * 256;
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SPLASHBASE));
          if thing.player <> nil then
            P_NoiseAlert(thing, thing);
          S_StartSound(mo, Ord(SFX_WATER_SPLASH));
        end;
        result := FLOOR_WATER;
        exit;
      end;
    FLOOR_LAVA:
      begin
        if smallsplash then
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_LAVASPLASH));
          if mo <> nil then
            mo.floorclip := mo.floorclip + SMALLSPLASHCLIP;
        end
        else
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_LAVASMOKE));
          mo.momz := FRACUNIT + P_Random * 128;
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_LAVASPLASH));
          if thing.player <> nil then
            P_NoiseAlert(thing, thing);
        end;
        S_StartSound(mo, Ord(SFX_LAVA_SIZZLE));
        if (thing.player <> nil) and (leveltime and 31 <> 0) then
          P_DamageMobj(thing, @LavaInflictor, nil, 5);
        result := FLOOR_LAVA;
        exit;
      end;
    FLOOR_SLUDGE:
      begin
        if smallsplash then
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SLUDGESPLASH));
          if mo <> nil then
            mo.floorclip := mo.floorclip + SMALLSPLASHCLIP;
        end
        else
        begin
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SLUDGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_SLUDGESPLASH));
          if thing.player <> nil then
            P_NoiseAlert(thing, thing);
        end;
        S_StartSound(mo, Ord(SFX_SLUDGE_GLOOP));
        result := FLOOR_SLUDGE;
        exit;
      end;
  end;
  result := FLOOR_SOLID;
end;


//---------------------------------------------------------------------------
//
// FUNC P_CheckMissileSpawn
//
// Returns true if the missile is at a valid spawn point, otherwise
// explodes it and returns false.
//
//---------------------------------------------------------------------------

function P_CheckMissileSpawn(missile: Pmobj_t): boolean;
begin
  // move a little forward so an angle can be computed if it
  // immediately explodes
  missile.x := missile.x + _SHR1(missile.momx);
  missile.y := missile.y + _SHR1(missile.momy);
  missile.z := missile.z + _SHR1(missile.momz);
  if not P_TryMove(missile, missile.x, missile.y) then
  begin
    P_ExplodeMissile(missile);
    result := false;
  end
  else
    result := true;
end;

//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissile
//
// Returns nil if the missile exploded immediately, otherwise returns
// a mobj_t pointer to the missile.
//
//---------------------------------------------------------------------------

function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  z: fixed_t;
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  case _type of
    Ord(MT_MNTRFX1): // Minotaur swing attack missile
      z := source.z + 40 * FRACUNIT;
    Ord(MT_MNTRFX2): // Minotaur floor fire missile
      z := ONFLOORZ + source.floorclip;
    Ord(MT_CENTAUR_FX):
      z := source.z + 45 * FRACUNIT;
    Ord(MT_ICEGUY_FX):
      z := source.z + 40 * FRACUNIT;
    Ord(MT_HOLY_MISSILE):
      z := source.z + 40 * FRACUNIT;
  else
    z := source.z + 32 * FRACUNIT;
  end;
  z := z - source.floorclip;
  th := P_SpawnMobj(source.x, source.y, z, _type);
  if th <> nil then
  begin
    A_SeeSound(th, th);
    th.target := source; // Originator
    an := R_PointToAngle2(source.x, source.y, dest.x, dest.y);
    if dest.flags and MF_SHADOW <> 0 then
    begin // Invisible target
      an := an + _SHLW(P_Random - P_Random, 21);
    end;
    th.angle := an;
    an := an shr ANGLETOFINESHIFT;
    th.momx := FixedMul(th.info.speed, finecosine[an]);
    th.momy := FixedMul(th.info.speed, finesine[an]);
    dist := P_AproxDistance(dest.x - source.x, dest.y - source.y);
    if th.info.speed = 0 then
      dist := 1
    else
    begin
      dist := dist div th.info.speed;
      if dist < 1 then
        dist := 1;
    end;
    th.momz := (dest.z - source.z) div dist;
    if P_CheckMissileSpawn(th) then
      result := th
    else
      result := nil;
  end
  else
    result := nil;
end;

//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissileXYZ
//
// Returns nil if the missile exploded immediately, otherwise returns
// a mobj_t pointer to the missile.
//
//---------------------------------------------------------------------------

function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
  flags_ex: integer;
begin
  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
    z := ONFLOORZ
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
    z := ONCEILINGZ
  else if z <> ONFLOORZ then
    z := z - source.floorclip;

  th := P_SpawnMobj(x, y, z, _type);
  A_SeeSound(th, th);
  th.target := source; // Originator
  an := R_PointToAngle2(source.x, source.y, dest.x, dest.y);
  if dest.flags and MF_SHADOW <> 0 then
  begin // Invisible target
    an := an + _SHLW(P_Random - P_Random, 21);
  end;

  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  th.momx := FixedMul(th.info.speed, finecosine[an]);
  th.momy := FixedMul(th.info.speed, finesine[an]);
  dist := P_AproxDistance(dest.x - source.x, dest.y - source.y);
  if th.info.speed = 0 then
    dist := 1
  else
  begin
    dist := dist div th.info.speed;
    if dist < 1 then
      dist := 1;
  end;
  if flags_ex and (MF_EX_FLOORHUGGER or MF_EX_CEILINGHUGGER) <> 0 then
    th.momz := 0
  else
    th.momz := (dest.z - source.z) div dist;
  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;
end;

//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissileAngleZSpeed
//
//---------------------------------------------------------------------------
function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;
var
  mo: Pmobj_t;
  flags_ex: integer;
begin
  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
    z := ONFLOORZ
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
    z := ONCEILINGZ
  else if z <> ONFLOORZ then
    z := z - source.floorz;

  mo := P_SpawnMobj(source.x, source.y, z, _type);
  if mo <> nil then
  begin
    A_SeeSound(mo, mo);
    if owner <> nil then
      mo.target := owner
    else
      mo.target := source;  // Originator
    mo.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    mo.momx := FixedMul(speed, finecosine[angle]);
    mo.momy := FixedMul(speed, finesine[angle]);
    mo.momz := momz;
    if P_CheckMissileSpawn(mo) then
      result := mo
    else
      result := nil;
  end
  else
    result := nil;
end;

//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissileAngleZ
//
//---------------------------------------------------------------------------
function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;
begin
  result := P_SpawnMissileAngleZSpeed(source, z, _type, angle, momz, mobjinfo[Ord(_type)].speed, nil);
end;


//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissileAngle
//
// Returns nil if the missile exploded immediately, otherwise returns
// a mobj_t pointer to the missile.
//
//---------------------------------------------------------------------------

function P_SpawnMissileAngle(source: Pmobj_t; _type: integer; angle: angle_t;
  momz: fixed_t): Pmobj_t;
var
  z: fixed_t;
  mo: Pmobj_t;
begin
  case _type of
    Ord(MT_MNTRFX1): // Minotaur swing attack missile
      z := source.z + 40 * FRACUNIT;
    Ord(MT_MNTRFX2): // Minotaur floor fire missile
      z := ONFLOORZ + source.floorclip;
    Ord(MT_ICEGUY_FX2): // Secondary Projectiles of the Ice Guy
      z := source.z + 3 * FRACUNIT;
    Ord(MT_MSTAFF_FX2):
      z := source.z + 40 * FRACUNIT;
  else
    z := source.z + 32 * FRACUNIT;
  end;
  z := z - source.floorclip;
  mo := P_SpawnMobj(source.x, source.y, z, _type);
  if mo <> nil then
  begin
    A_SeeSound(mo, mo);
    mo.target := source; // Originator
    mo.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    mo.momx := FixedMul(mo.info.speed, finecosine[angle]);
    mo.momy := FixedMul(mo.info.speed, finesine[angle]);
    mo.momz := momz;
    if P_CheckMissileSpawn(mo) then
      result := mo
    else
      result := nil;
  end
  else
    result := nil;
end;

//---------------------------------------------------------------------------
//
// FUNC P_SpawnMissileAngleSpeed
//
// Returns nil if the missile exploded immediately, otherwise returns
// a mobj_t pointer to the missile.
//
//---------------------------------------------------------------------------

function P_SpawnMissileAngleSpeed(source: Pmobj_t; _type: integer;
  angle: angle_t; momz: fixed_t; speed: fixed_t): Pmobj_t;
var
  z: fixed_t;
  mo: Pmobj_t;
begin
  z := source.z;
  z := z - source.floorclip;
  mo := P_SpawnMobj(source.x, source.y, z, _type);
  if mo <> nil then
  begin
  //  A_SeeSound(mo, mo); JVAL SOS
    mo.target := source; // Originator
    mo.angle := angle;
    angle := angle shr ANGLETOFINESHIFT;
    mo.momx := FixedMul(speed, finecosine[angle]);
    mo.momy := FixedMul(speed, finesine[angle]);
    mo.momz := momz;
    if P_CheckMissileSpawn(mo) then
      result := mo
    else
      result := nil;
  end
  else
    result := nil;
end;



//
//================
//
// P_SpawnPlayerMissile
//
// Tries to aim at a nearby monster
//================
//

function P_SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;
var
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if zaxisshift and (linetarget = nil) then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
      end;

    end;
  end;

  x := source.x;
  y := source.y;
  if _type = Ord(MT_LIGHTNING_FLOOR) then
  begin
    z := ONFLOORZ;
    slope := 0;
  end
  else if _type = Ord(MT_LIGHTNING_CEILING) then
  begin
    z := ONCEILINGZ;
    slope := 0;
  end
  else
  begin
  // Also z axis shift calculation
    if zaxisshift then
      z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
    else
      z := source.z + 4 * 8 * FRACUNIT;
    z := z - source.floorclip;
  end;

  MissileMobj := P_SpawnMobj(x, y, z, _type);
  if MissileMobj <> nil then
  begin
//    A_SeeSound(MissileMobj, MissileMobj); JVAL SOS
    MissileMobj.target := source;
    MissileMobj.angle := an;
    MissileMobj.momx := FixedMul(MissileMobj.info.speed, finecosine[an shr ANGLETOFINESHIFT]);
    MissileMobj.momy := FixedMul(MissileMobj.info.speed, finesine[an shr ANGLETOFINESHIFT]);
    MissileMobj.momz := FixedMul(MissileMobj.info.speed, slope);
    if (MissileMobj._type = Ord(MT_MWAND_MISSILE)) or (MissileMobj._type = Ord(MT_CFLAME_MISSILE)) then
    begin // Ultra-fast ripper spawning missile
      MissileMobj.x := MissileMobj.x + _SHR3(MissileMobj.momx);
      MissileMobj.y := MissileMobj.y + _SHR3(MissileMobj.momy);
      MissileMobj.z := MissileMobj.z + _SHR3(MissileMobj.momz);
    end
    else
    begin // Normal missile
      MissileMobj.x := MissileMobj.x + _SHR1(MissileMobj.momx);
      MissileMobj.y := MissileMobj.y + _SHR1(MissileMobj.momy);
      MissileMobj.z := MissileMobj.z + _SHR1(MissileMobj.momz);
    end;
    if not P_TryMove(MissileMobj, MissileMobj.x, MissileMobj.y) then
    begin // Exploded immediately
      P_ExplodeMissile(MissileMobj);
      result := nil;
    end
    else
      result := MissileMobj;
  end
  else
    result := nil;
end;

function P_SPMAngle(source: Pmobj_t; _type: integer; angle: angle_t): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  x, y, z, slope: fixed_t;
begin
//
// see which target is to be aimed at
//
  an := angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack (source, an, 16 * 64 * FRACUNIT);
    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack (source, an, 16 * 64 * FRACUNIT);
      if zaxisshift and (linetarget = nil) then
      begin
        an := angle;
        slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
      end;
    end
  end;
  x := source.x;
  y := source.y;
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;
  z := z - source.floorclip;

  th := P_SpawnMobj(x, y, z, _type);
  if th <> nil then
  begin
  //  A_SeeSound(th, th); JVAL SOS

    th.target := source;
    th.angle := an;
    th.momx := FixedMul(th.info.speed, finecosine[an shr ANGLETOFINESHIFT]);
    th.momy := FixedMul(th.info.speed, finesine[an shr ANGLETOFINESHIFT]);
    th.momz := FixedMul(th.info.speed, slope);
    if P_CheckMissileSpawn(th) then
      result := th
    else
      result := nil;

  end
  else
    result := nil;
end;

//===========================================================================
//
// P_SPMAngleXYZ
//
//===========================================================================

function P_SPMAngleXYZ(source: Pmobj_t; x, y, z: fixed_t; _type: integer;
  angle: angle_t): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  slope: fixed_t;
begin
//
// see which target is to be aimed at
//
  an := angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
      if zaxisshift and (linetarget = nil) then
      begin
        an := angle;
        slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
      end
    end;
  end;
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;
  z := z - source.floorclip;
  th := P_SpawnMobj(x, y, z, _type);
  if th <> nil then
  begin
//  if th.info.seesound)      // JVAL SOS
//  begin
//    S_StartSound(th, th.info.seesound);
//  end;
    th.target := source;
    th.angle := an;
    th.momx := FixedMul(th.info.speed, finecosine[an shr ANGLETOFINESHIFT]);
    th.momy := FixedMul(th.info.speed, finesine[an shr ANGLETOFINESHIFT]);
    th.momz := FixedMul(th.info.speed, slope);
    if P_CheckMissileSpawn(th) then
      result := th
    else
      result := nil;
  end
  else
    result := nil;
end;

function P_SpawnKoraxMissile(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t;
  _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  z := z - source.floorclip;
  th := P_SpawnMobj(x, y, z, _type);
  if th <> nil then
  begin
    A_SeeSound(th, th);
    th.target := source; // Originator
    an := R_PointToAngle2(x, y, dest.x, dest.y);
    if dest.flags and MF_SHADOW <> 0 then
    begin // Invisible target
      an := an + _SHLW(P_Random - P_Random, 21);
    end;
    th.angle := an;
    an := an shr ANGLETOFINESHIFT;
    th.momx := FixedMul(th.info.speed, finecosine[an]);
    th.momy := FixedMul(th.info.speed, finesine[an]);
    dist := P_AproxDistance(dest.x - x, dest.y - y);
    if th.info.speed = 0 then
      dist := 1
    else
    begin
      dist := dist div th.info.speed;
      if dist < 1 then
        dist := 1;
    end;
    th.momz := (dest.z - z + 30 * FRACUNIT) div dist;
    if P_CheckMissileSpawn(th) then
      result := th
    else
      result := nil;
  end
  else
    result := nil;
end;

{//---------------------------------------------------------------------------
//
// FUNC P_GetThingFloorType
//
//---------------------------------------------------------------------------

function P_GetThingFloorType(thing: Pmobj_t): integer;
begin
  result := flats[thing.floorpic].terraintype;
end;} // JVAL SOS


//---------------------------------------------------------------------------
//
// FUNC P_GetThingFloorType
//
//---------------------------------------------------------------------------

function P_GetThingFloorType(thing: Pmobj_t): integer;
begin
  result := flats[Psubsector_t(thing.subsector).sector.floorpic].terraintype;
end;

end.
