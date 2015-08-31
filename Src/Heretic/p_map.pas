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
//  Movement, collision handling.
//  Shooting and aiming.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_map;

interface

uses
  m_bbox,
  m_rnd,
  i_system,
  doomdef,
  p_local,
  p_mobj_h,
  s_sound,
  m_fixed,
  tables,
  d_player,
  r_defs,
// State.
  doomstat,
// Data.
  sounds;

function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;

function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;

procedure P_LineAttack(t1: Pmobj_t; angle: angle_t;
  distance: fixed_t; slope: fixed_t; damage: integer);

procedure P_UseLines(player: Pplayer_t);

procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; const damage: integer);

procedure P_RadiusAttackEx(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);

function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;

procedure P_SlideMove(mo: Pmobj_t);

function P_CheckOnmobj(thing: Pmobj_t): Pmobj_t;

var
  linetarget: Pmobj_t;  // who got hit (or NULL)

// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
  floatok: boolean;

  tmfloorz: fixed_t;
  tmceilingz: fixed_t;
  tmdropoffz: fixed_t;

var
  spechit: Pline_tPArray = nil;  // JVAL Now spechit is dynamic
  maxspechit: integer = 0;
  numspechit: integer;

// keep track of the line that lowers the ceiling,
// so missiles don't explode against sky hack walls
  ceilingline: Pline_t;                                    

  attackrange: fixed_t;

function P_SectorJumpOverhead(const s: Psector_t; const p: Pplayer_t): integer;

function P_TestMobjLocation(mobj: Pmobj_t): boolean;

implementation

uses
  d_delphi,
  doomdata,
  g_game,
  info_h,
  info,
  p_setup,
  p_maputl,
  p_inter,
  p_mobj,
  p_spec,
  p_sight,
  p_switch,
  p_tick,
  r_main,
  r_sky,
  r_intrpl,
  z_zone;

var
  tmbbox: array[0..3] of fixed_t;
  tmthing: Pmobj_t;
  tmflags: integer;
  tmx: fixed_t;
  tmy: fixed_t;

//
// TELEPORT MOVE
// 

//
// PIT_StompThing
//
function PIT_StompThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    result := true;
    exit;
  end;

  // monsters don't stomp things except on boss level
  if (tmthing.player = nil) and (gamemap <> 30) then
  begin
    result := false;
    exit;
  end;

  P_DamageMobj(thing, tmthing, tmthing, 10000);

  result := true;
end;

//
// P_TeleportMove
//
function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsubsec: Psubsector_t;
begin
  // kill anything occupying the position
  tmthing := thing;
  tmflags := thing.flags;

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing.radius;
  tmbbox[BOXBOTTOM] := y - tmthing.radius;
  tmbbox[BOXRIGHT] := x + tmthing.radius;
  tmbbox[BOXLEFT] := x - tmthing.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := nil;

  // The base floor/ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  tmdropoffz := newsubsec.sector.floorheight;
  tmfloorz := tmdropoffz;

  tmceilingz := newsubsec.sector.ceilingheight + P_SectorJumpOverhead(newsubsec.sector, thing.player);

  inc(validcount); 
  numspechit := 0;

  // stomp on any things contacted
  xl := MapBlockInt(tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS);
  xh := MapBlockInt(tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS);
  yl := MapBlockInt(tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS);
  yh := MapBlockInt(tmbbox[BOXTOP] - bmaporgy + MAXRADIUS);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_StompThing) then
      begin
        result := false;
        exit;
      end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;
  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  if thing.player = viewplayer then
    R_SetInterpolateSkipTicks(1);

  thing.flags := thing.flags or MF_JUSTAPPEARED;

  result := true;
end;

//
// MOVEMENT ITERATOR FUNCTIONS
//


//
// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
//
function PIT_CheckLine(ld: Pline_t): boolean;
begin
  if (tmbbox[BOXRIGHT] <= ld.bbox[BOXLEFT]) or
     (tmbbox[BOXLEFT] >= ld.bbox[BOXRIGHT]) or
     (tmbbox[BOXTOP] <= ld.bbox[BOXBOTTOM]) or
     (tmbbox[BOXBOTTOM] >= ld.bbox[BOXTOP]) then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@tmbbox, ld) <> -1 then
  begin
    result := true;
    exit;
  end;
    
  // A line has been hit

  // The moving thing's destination position will cross
  // the given line.
  // If this should not be allowed, return false.
  // If the line is special, keep track of it
  // to process later if the move is proven ok.
  // NOTE: specials are NOT sorted by order,
  // so two special lines that are only 8 pixels apart
  // could be crossed in either order.

  if ld.backsector = nil then
  begin
    result := false;  // one sided line
    exit;
  end;

  if tmthing.flags and MF_MISSILE = 0 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      result := false;  // explicitly blocking everything
      exit;
    end;

    if (tmthing.player = nil) and ((ld.flags and ML_BLOCKMONSTERS) <> 0) then
    begin
      result := false;  // block monsters only
      exit;
    end;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(ld);

  // adjust floor / ceiling heights
  if opentop < tmceilingz then
  begin
    tmceilingz := opentop;
    ceilingline := ld;
  end;

  if openbottom > tmfloorz then
    tmfloorz := openbottom;

  if lowfloor < tmdropoffz then
    tmdropoffz := lowfloor;

  // if contacted a special line, add it to the list
  if ld.special <> 0 then
  begin
    if maxspechit = 0 then
    begin
      maxspechit := 64;
      spechit := Z_Malloc(64 * SizeOf(Pline_t), PU_STATIC, nil)
    end
    else if numspechit = maxspechit then
    begin
      maxspechit := maxspechit + 8;
      spechit := Z_ReAlloc(spechit, maxspechit * SizeOf(Pline_t), PU_STATIC, nil)
    end;

    spechit[numspechit] := ld;
    inc(numspechit);

//    fprintf(stderr, 'numspechit = %d' + #13#10, [numspechit]);
  end;

  result := true;
end;

//
// PIT_CheckThing
//
function PIT_CheckThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
  solid: boolean;
  damage: integer;
begin
  if (thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE)) = 0 then
  begin
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    result := true;
    exit;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  if tmthing.flags2 and MF2_PASSMOBJ <> 0 then
  begin // check if a mobj passed over/under another object

    if ((tmthing._type = Ord(MT_IMP)) or (tmthing._type = Ord(MT_WIZARD))) and
       ((thing._type = Ord(MT_IMP)) or (thing._type = Ord(MT_WIZARD))) then
    begin // don't let imps/wizards fly over other imps/wizards
      result := false;
      exit;
    end;

    if (tmthing.z > thing.z + thing.height) and
       (thing.flags and MF_SPECIAL = 0) then
    begin
      result := true;
      exit;
    end;

    if (tmthing.z + tmthing.height < thing.z) and
       (thing.flags and MF_SPECIAL = 0) then
    begin // under thing
      result := true;
      exit;
    end;
  end;

  // check for skulls slamming into things
  if tmthing.flags and MF_SKULLFLY <> 0 then
  begin
    damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
    P_DamageMobj(thing, tmthing, tmthing, damage);

    tmthing.flags := tmthing.flags and (not MF_SKULLFLY);
    tmthing.momx := 0;
    tmthing.momy := 0;
    tmthing.momz := 0;

    P_SetMobjState(tmthing, statenum_t(tmthing.info.spawnstate));

    result := false;  // stop moving
    exit;
  end;

  // missiles can hit other things
  if tmthing.flags and MF_MISSILE <> 0 then
  begin
    if (thing.flags_ex and MF_EX_GHOST <> 0) and (tmthing.flags_ex and MF_EX_THRUGHOST <> 0) then
    begin
      result := true;
      exit;
    end;

    // Check for passing through a ghost
    if (thing.flags and MF_SHADOW <> 0) and (tmthing.flags2 and MF2_THRUGHOST <> 0) then
    begin
      result := true;
      exit;
    end;

    // see if it went over / under
    if tmthing.z > thing.z + thing.height then
    begin
      result := true; // overhead
      exit;
    end;
    if tmthing.z + tmthing.height < thing.z then
    begin
      result := true; // underneath
      exit;
    end;

    if (tmthing.target <> nil) and
       (tmthing.target._type = thing._type) then
    begin // Don't hit same species as originator.
      if thing = tmthing.target then // Don't missile self
      begin
        result := true;
        exit;
      end;

      if thing._type <> Ord(MT_PLAYER) then // Hit same species as originator, explode, no damage
      begin
        // Explode, but do no damage.
        // Let players missile other players.
        result := false;
        exit;
      end;
    end;

    if thing.flags and MF_SHOOTABLE = 0 then
    begin
      // didn't do any damage
      result := (thing.flags and MF_SOLID) = 0;
      exit;
    end;

    if tmthing.flags2 and MF2_RIP <> 0 then
    begin
      if thing.flags and MF_NOBLOOD = 0 then
      begin // Ok to spawn some blood
        P_RipperBlood(tmthing);
      end;

      S_StartSound(tmthing, Ord(sfx_ripslop));
      damage := ((P_Random and 3) + 2) * tmthing.damage;
      P_DamageMobj(thing, tmthing, tmthing.target, damage);
      if (thing.flags2 and MF2_PUSHABLE <> 0) and
         (tmthing.flags2 and MF2_CANNOTPUSH = 0) then
      begin // Push thing
        thing.momx := thing.momx + tmthing.momx div 4;
        thing.momy := thing.momy + tmthing.momy div 4;
      end;
      numspechit := 0;
      result := true;
      exit;
    end;

    // damage / explode
    damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
    if damage <> 0 then
    begin
      if (thing.flags and MF_NOBLOOD = 0) and (P_Random < 192) then
        P_BloodSplatter(tmthing.x, tmthing.y, tmthing.z, thing);
      P_DamageMobj(thing, tmthing, tmthing.target, damage);
    end;

    // don't traverse any more
    result := false;
    exit;
  end;

  if (thing.flags2 and MF2_PUSHABLE <> 0) and (tmthing.flags2 and MF2_CANNOTPUSH = 0) then
  begin // Push thing
    thing.momx := thing.momx + tmthing.momx div 4;
    thing.momy := thing.momy + tmthing.momy div 4;
  end;

  // check for special pickup
  if thing.flags and MF_SPECIAL <> 0 then
  begin
    solid := (thing.flags and MF_SOLID) <> 0;
    if tmflags and MF_PICKUP <> 0 then
    begin
      // can remove thing
      P_TouchSpecialThing(thing, tmthing);
    end;
    result := not solid;
  end
  else
    result := (thing.flags and MF_SOLID) = 0;
end;

//
// MOVEMENT CLIPPING
//

//
// P_CheckPosition
// This is purely informative, nothing is modified
// (except things picked up).
//
// in:
//  a mobj_t (can be valid or invalid)
//  a position to be checked
//   (doesn't need to be related to the mobj_t->x,y)
//
// during:
//  special things are touched if MF_PICKUP
//  early out on solid lines?
//
// out:
//  newsubsec
//  floorz
//  ceilingz
//  tmdropoffz
//   the lowest point contacted
//   (monsters won't move to a dropoff)
//  speciallines[]
//  numspeciallines
//
function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsubsec: Psubsector_t;
begin
  tmthing := thing;
  tmflags := thing.flags;

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing.radius;
  tmbbox[BOXBOTTOM] := y - tmthing.radius;
  tmbbox[BOXRIGHT] := x + tmthing.radius;
  tmbbox[BOXLEFT] := x - tmthing.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := nil;

  // The base floor / ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  tmdropoffz := newsubsec.sector.floorheight;
  tmfloorz := tmdropoffz;
  tmceilingz := newsubsec.sector.ceilingheight + P_SectorJumpOverhead(newsubsec.sector, thing.player);

  inc(validcount);
  numspechit := 0;

  if tmflags and MF_NOCLIP <> 0 then
  begin
    result := true;
    exit;
  end;

  // Check things first, possibly picking things up.
  // The bounding box is extended by MAXRADIUS
  // because mobj_ts are grouped into mapblocks
  // based on their origin point, and can overlap
  // into adjacent blocks by up to MAXRADIUS units.
  xl := MapBlockInt(tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS);
  xh := MapBlockInt(tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS);
  yl := MapBlockInt(tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS);
  yh := MapBlockInt(tmbbox[BOXTOP] - bmaporgy + MAXRADIUS);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckThing) then
      begin
        result := false;
        exit;
      end;

  // check lines
  xl := MapBlockInt(tmbbox[BOXLEFT] - bmaporgx);
  xh := MapBlockInt(tmbbox[BOXRIGHT] - bmaporgx);
  yl := MapBlockInt(tmbbox[BOXBOTTOM] - bmaporgy);
  yh := MapBlockInt(tmbbox[BOXTOP] - bmaporgy);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockLinesIterator(bx, by, PIT_CheckLine) then
      begin
        result := false;
        exit;
      end;

  result := true;
end;

//=============================================================================
//
// P_FakeZMovement
//
//     Fake the zmovement so that we can check if a move is legal
//=============================================================================

procedure P_FakeZMovement(mo: Pmobj_t);
var
  dist: integer;
  delta: integer;
begin
//
// adjust height
//
  mo.z := mo.z + mo.momz;
  if(mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin  // float down towards target if too close
    if (mo.flags and MF_SKULLFLY = 0) and (mo.flags and MF_INFLOAT = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);
      delta := mo.target.z + (mo.height div 2) - mo.z;
      if (delta < 0) and (dist < -delta * 3) then
        mo.z := mo.z - FLOATSPEED
      else if (delta > 0) and (dist < delta * 3) then
        mo.z := mo.z + FLOATSPEED;
    end;
  end;
  if (mo.player <> nil) and (mo.flags2 and MF2_FLY <> 0) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then
    mo.z := mo.z + finesine[(FINEANGLES div 20 * leveltime div 4) and FINEMASK];

//
// clip movement
//
  if mo.z <= mo.floorz then
  begin // Hit the floor
    mo.z := mo.floorz;
    if mo.momz < 0 then
      mo.momz := 0;
    if mo.flags and MF_SKULLFLY <> 0 then // The skull slammed into something
      mo.momz := -mo.momz;
    if (mo.info.crashstate <> 0) and (mo.flags and MF_CORPSE <> 0) then
      exit;
  end
  else if (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0) then
  begin
    if mo.momz = 0 then
      mo.momz := -(GRAVITY div 8) * 2
    else
      mo.momz := mo.momz - GRAVITY div 8;
  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -GRAVITY * 2
    else
      mo.momz := mo.momz - GRAVITY;
  end
  else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -(GRAVITY div 8) * 4
    else
      mo.momz := mo.momz - GRAVITY div 4;
  end;

  if mo.z + mo.height > mo.ceilingz then
  begin  // hit the ceiling
    if mo.momz > 0 then
      mo.momz := 0;
    mo.z := mo.ceilingz - mo.height;
    if mo.flags and MF_SKULLFLY <> 0 then // the skull slammed into something
      mo.momz := -mo.momz;
  end;
end;

var
  onmobj: Pmobj_t; //generic global onmobj...used for landing on pods/players

//---------------------------------------------------------------------------
//
// PIT_CheckOnmobjZ
//
//---------------------------------------------------------------------------

function PIT_CheckOnmobjZ(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then
  begin // Can't hit thing
    result := true;
    exit;
  end;

  blockdist := thing.radius + tmthing.radius;
  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin // Didn't hit thing
    result := true;
    exit;
  end;

  if thing = tmthing then
  begin // Don't clip against self
    result := true;
    exit;
  end;

  if tmthing.z > thing.z + thing.height then
  begin
    result := true;
    exit;
  end
  else if tmthing.z + tmthing.height < thing.z then
  begin // under thing
    result := true;
    exit;
  end;

  result := thing.flags and MF_SOLID = 0;
  if not result then
    onmobj := thing;

end;

//=============================================================================
//
// P_CheckOnmobj(mobj_t *thing)
//
//     Checks if the new Z position is legal
//=============================================================================

function P_CheckOnmobj(thing: Pmobj_t): Pmobj_t;
var
  xl, xh, yl, yh, bx, by: integer;
  newsubsec: Psubsector_t;
  x: fixed_t;
  y: fixed_t;
  oldmo: mobj_t;
begin
  x := thing.x;
  y := thing.y;
  tmthing := thing;
  tmflags := thing.flags;
  oldmo := thing^; // save the old mobj before the fake zmovement
  P_FakeZMovement(tmthing);

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing.radius;
  tmbbox[BOXBOTTOM] := y - tmthing.radius;
  tmbbox[BOXRIGHT] := x + tmthing.radius;
  tmbbox[BOXLEFT] := x - tmthing.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := nil;

//
// the base floor / ceiling is from the subsector that contains the
// point.  Any contacted lines the step closer together will adjust them
//
  tmfloorz := newsubsec.sector.floorheight;
  tmdropoffz := tmfloorz;
  tmceilingz := newsubsec.sector.ceilingheight;

  inc(validcount);
  numspechit := 0;

  if tmflags and MF_NOCLIP <> 0 then
  begin
    result := nil;
    exit;
  end;

//
// check things first, possibly picking things up
// the bounding box is extended by MAXRADIUS because mobj_ts are grouped
// into mapblocks based on their origin point, and can overlap into adjacent
// blocks by up to MAXRADIUS units
//
  xl := MapBlockInt(tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS);
  xh := MapBlockInt(tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS);
  yl := MapBlockInt(tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS);
  yh := MapBlockInt(tmbbox[BOXTOP] - bmaporgy + MAXRADIUS);

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckOnmobjZ) then
      begin
        tmthing^ := oldmo;
        result := onmobj;
        exit;
      end;

  tmthing^ := oldmo;
  result := nil;
end;


//
// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
//
function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  oldx: fixed_t;
  oldy: fixed_t;
  side: integer;
  oldside: integer;
  ld: Pline_t;
begin
  floatok := false;
  if not P_CheckPosition(thing, x, y) then
  begin
    result := false;  // solid wall or thing
    exit;
  end;

  if thing.flags and MF_NOCLIP = 0 then
  begin
    if tmceilingz - tmfloorz < thing.height then
    begin
      result := false;  // doesn't fit
      exit;
    end;

    floatok := true;

    if (thing.flags and MF_TELEPORT = 0) and
       (tmceilingz - thing.z < thing.height) then
    begin
      result := false;  // mobj must lower itself to fit
      exit;
    end;

    if (thing.flags and MF_TELEPORT = 0) and
       (tmfloorz - thing.z > 24 * FRACUNIT) then
    begin
      result := false;  // too big a step up
      exit;
    end;

    if ((thing.flags and (MF_DROPOFF or MF_FLOAT)) = 0) and
       (tmfloorz - tmdropoffz > 24 * FRACUNIT) then
    begin
      result := false;  // don't stand over a dropoff
      exit;
    end;
  end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  oldx := thing.x;
  oldy := thing.y;
  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;
  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  if (thing.flags2 and MF2_FOOTCLIP <> 0) and (P_GetThingFloorType(thing) <> FLOOR_SOLID) then
    thing.flags2 := thing.flags2 or MF2_FEETARECLIPPED
  else if thing.flags2 and MF2_FEETARECLIPPED <> 0 then
    thing.flags2 := thing.flags2 and not MF2_FEETARECLIPPED;


  // if any special lines were hit, do the effect
  if thing.flags and (MF_TELEPORT or MF_NOCLIP) = 0 then
  begin
    while numspechit > 0 do
    begin
      // see if the line was crossed
      dec(numspechit); // JVAL what happens to while loops ???
      ld := spechit[numspechit];
      side := P_PointOnLineSide(thing.x, thing.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      if side <> oldside then
      begin
        if ld.special <> 0 then
          P_CrossSpecialLine(pDiff(ld, @lines[0], SizeOf(ld^)), oldside, thing);
      end;
    end;
  end;

  result := true;
end;

//
// P_ThingHeightClip
// Takes a valid thing and adjusts the thing->floorz,
// thing->ceilingz, and possibly thing->z.
// This is called for all nearby monsters
// whenever a sector changes height.
// If the thing doesn't fit,
// the z will be set to the lowest value
// and false will be returned.
//
function P_ThingHeightClip(thing: Pmobj_t): boolean;
var
  onfloor: boolean;
begin
  onfloor := thing.z = thing.floorz;

  P_CheckPosition(thing, thing.x, thing.y);
  // what about stranding a monster partially off an edge?

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;

  if onfloor then
  begin
    // walking monsters rise and fall with the floor
    thing.z := thing.floorz;
  end
  else
  begin
    // don't adjust a floating monster unless forced to
    if thing.z + thing.height > thing.ceilingz then
      thing.z := thing.ceilingz - thing.height;
  end;

  result := thing.ceilingz - thing.floorz >= thing.height;
end;

//
// SLIDE MOVE
// Allows the player to slide along any angled walls.
//
var
  bestslidefrac: fixed_t;
  secondslidefrac: fixed_t;

  bestslideline: Pline_t;
  secondslideline: Pline_t;

  slidemo: Pmobj_t;

  tmxmove: fixed_t;
  tmymove: fixed_t;

//
// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
//
procedure P_HitSlideLine(ld: Pline_t);
var
  side: integer;
  lineangle: angle_t;
  moveangle: angle_t;
  deltaangle: angle_t;
  movelen: fixed_t;
  newlen: fixed_t;
begin
  if ld.slopetype = ST_HORIZONTAL then
  begin
    tmymove := 0;
    exit;
  end;

  if ld.slopetype = ST_VERTICAL then
  begin
    tmxmove := 0;
    exit;
  end;

  side := P_PointOnLineSide(slidemo.x, slidemo.y, ld);

  lineangle := R_PointToAngle2(0, 0, ld.dx, ld.dy);

  if side = 1 then
    lineangle := lineangle + ANG180;

  moveangle := R_PointToAngle2(0, 0, tmxmove, tmymove);
  deltaangle := moveangle - lineangle;

  if deltaangle > ANG180 then
    deltaangle := deltaangle + ANG180;
    //  I_Error ("SlideLine: ang>ANG180");

  {$IFDEF FPC}
  lineangle := _SHRW(lineangle, ANGLETOFINESHIFT);
  deltaangle := _SHRW(deltaangle, ANGLETOFINESHIFT);
  {$ELSE}
  lineangle := lineangle shr ANGLETOFINESHIFT;
  deltaangle := deltaangle shr ANGLETOFINESHIFT;
  {$ENDIF}

  movelen := P_AproxDistance(tmxmove, tmymove);
  newlen := FixedMul(movelen, finecosine[deltaangle]);

  tmxmove := FixedMul(newlen, finecosine[lineangle]);
  tmymove := FixedMul(newlen, finesine[lineangle]);
end;

//
// PTR_SlideTraverse
//
function PTR_SlideTraverse(_in: Pintercept_t): boolean;
var
  li: Pline_t;

  procedure isblocking;
  begin
    // the line does block movement,
    // see if it is closer than best so far
    if _in.frac < bestslidefrac then
    begin
      secondslidefrac := bestslidefrac;
      secondslideline := bestslideline;
      bestslidefrac := _in.frac;
      bestslideline := li;
    end;
  end;

begin
  if not _in.isaline then
    I_Error('PTR_SlideTraverse(): not a line?');

  li := _in.d.line;

  if li.flags and ML_TWOSIDED = 0 then
  begin
    if P_PointOnLineSide(slidemo.x, slidemo.y, li) <> 0 then
    begin
      // don't hit the back side
      result := true;
      exit;
    end;
    isblocking;
    result := false; // stop
    exit;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(li);

  if openrange < slidemo.height then
  begin
    isblocking; // doesn't fit
    result := false; // stop
    exit;
  end;

  if opentop - slidemo.z < slidemo.height then
  begin
    isblocking; // mobj is too high
    result := false; // stop
    exit;
  end;

  if openbottom - slidemo.z > 24 * FRACUNIT then
  begin
    isblocking; // too big a step up
    result := false; // stop
    exit;
  end;

  // this line doesn't block movement
  result := true;
end;

//
// P_SlideMove
// The momx / momy move is bad, so try to slide
// along a wall.
// Find the first line hit, move flush to it,
// and slide along it
//
// This is a kludgy mess.
//
procedure P_SlideMove(mo: Pmobj_t);
var
  leadx: fixed_t;
  leady: fixed_t;
  trailx: fixed_t;
  traily: fixed_t;
  newx: fixed_t;
  newy: fixed_t;
  hitcount: integer;

  procedure stairstep;
  begin
    if not P_TryMove(mo, mo.x, mo.y + mo.momy) then
      P_TryMove(mo, mo.x + mo.momx, mo.y);
  end;

begin
  slidemo := mo;
  hitcount := 0;

  repeat
    inc(hitcount);
    if hitcount = 3 then
    begin
      stairstep;
      exit;  // don't loop forever
    end;

    // trace along the three leading corners
    if mo.momx > 0 then
    begin
      leadx := mo.x + mo.radius;
      trailx := mo.x - mo.radius;
    end
    else
    begin
      leadx := mo.x - mo.radius;
      trailx := mo.x + mo.radius;
    end;

    if mo.momy > 0 then
    begin
      leady := mo.y + mo.radius;
      traily := mo.y - mo.radius;
    end
    else
    begin
      leady := mo.y - mo.radius;
      traily := mo.y + mo.radius;
    end;

    bestslidefrac := FRACUNIT + 1;

    P_PathTraverse(leadx, leady, leadx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(trailx, leady, trailx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(leadx, traily, leadx + mo.momx, traily + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);

    // move up to the wall
    if bestslidefrac = FRACUNIT + 1 then
    begin
      // the move most have hit the middle, so stairstep
      stairstep;
      exit;
    end;

    // fudge a bit to make sure it doesn't hit
    bestslidefrac := bestslidefrac - $800;
    if bestslidefrac > 0 then
    begin
      newx := FixedMul(mo.momx, bestslidefrac);
      newy := FixedMul(mo.momy, bestslidefrac);

      if not P_TryMove(mo, mo.x + newx, mo.y + newy) then
      begin
        stairstep;
        exit;
      end;
    end;

    // Now continue along the wall.
    // First calculate remainder.
    bestslidefrac := FRACUNIT - (bestslidefrac + $800);

    if bestslidefrac > FRACUNIT then
      bestslidefrac := FRACUNIT;

    if bestslidefrac <= 0 then
      exit;

    tmxmove := FixedMul(mo.momx, bestslidefrac);
    tmymove := FixedMul(mo.momy, bestslidefrac);

    P_HitSlideLine(bestslideline);  // clip the moves

    mo.momx := tmxmove;
    mo.momy := tmymove;

  until P_TryMove(mo, mo.x + tmxmove, mo.y + tmymove);

end;

//
// P_LineAttack
//
var
  shootthing: Pmobj_t;

// Height if not aiming up or down
// ???: use slope for monsters?
  shootz: fixed_t;

  la_damage: integer;

  aimslope: fixed_t;

//
// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
//
function PTR_AimTraverse(_in: Pintercept_t): boolean;
var
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;
  dist: fixed_t;
begin
  if _in.isaline then
  begin
    li := _in.d.line;

    if li.flags and ML_TWOSIDED = 0 then
    begin
      result := false; // stop
      exit;
    end;

    // Crosses a two sided line.
    // A two sided line will restrict
    // the possible target ranges.
    P_LineOpening(li);

    if openbottom >= opentop then
    begin
      result := false; // stop
      exit;
    end;

    dist := FixedMul(attackrange, _in.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - shootz, dist);
      if slope > bottomslope then
        bottomslope := slope;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - shootz, dist);
      if slope < topslope then
        topslope := slope;
    end;

    if topslope <= bottomslope then
    begin
      result := false; // stop
      exit;
    end;

    result := true;  // shot continues
    exit;
  end;

  // shoot a thing
  th := _in.d.thing;
  if th = shootthing then
  begin
    result := true;  // can't shoot self
    exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    result := true; // corpse or something
    exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, _in.frac);
  thingtopslope := FixedDiv(th.z + th.height - shootz, dist);

  if thingtopslope < bottomslope then
  begin
    result := true; // shot over the thing
    exit;
  end;

  thingbottomslope := FixedDiv(th.z - shootz, dist);

  if thingbottomslope > topslope then
  begin
    result := true; // shot under the thing
    exit;
  end;

  // this thing can be hit!
  if thingtopslope > topslope then
    thingtopslope := topslope;

  if thingbottomslope < bottomslope then
    thingbottomslope := bottomslope;

  aimslope := (thingtopslope + thingbottomslope) div 2;
  linetarget := th;

  result := false; // don't go any farther
end;

//
// PTR_ShootTraverse
//
function PTR_ShootTraverse(_in: Pintercept_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  frac: fixed_t;
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  dist: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;

  function hitline: boolean;
  var
    zoffs: fixed_t;
  begin
    // hit line
    // position a bit closer
    frac := _in.frac - FixedDiv(4 * FRACUNIT, attackrange);
    x := trace.x + FixedMul(trace.dx, frac);
    y := trace.y + FixedMul(trace.dy, frac);
    z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

    if li.frontsector.ceilingpic = skyflatnum then
    begin
      // don't shoot the sky!
      if z > li.frontsector.ceilingheight then
      begin
        result := false;
        exit;
      end;

      // it's a sky hack wall
      if (li.backsector <> nil) and (li.backsector.ceilingpic = skyflatnum) then
      begin
        if li.backsector.ceilingheight < z then
        begin
          result := false;
          exit;
        end;
      // JVAL: Spawn puff to lower textures.
        if G_NeedsCompatibilityMode then
        begin
          P_SaveRandom;
          zoffs := (li.backsector.ceilingheight - z) * P_Random div 256;
          if zoffs > dist div 2 then
            zoffs := dist div 2;
          P_SpawnPuff(x, y, z + zoffs);
          P_RestoreRandom;
          result := false;
          exit;
        end;
      end;
    end;
    // Spawn bullet puffs.
    P_SpawnPuff(x, y, z);

    // don't go any farther
    result := false;
  end;

begin
  if _in.isaline then
  begin
    li := _in.d.line;

    if li.special <> 0 then
      P_ShootSpecialLine(shootthing, li);

    if li.flags and ML_TWOSIDED = 0 then
    begin
      result := hitline;
      exit;
    end;

    // crosses a two sided line
    P_LineOpening(li);

    dist := FixedMul(attackrange, _in.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - shootz, dist);
      if slope > aimslope then
      begin
        result := hitline;
        exit;
      end;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - shootz, dist);
      if slope < aimslope then
      begin
        result := hitline;
        exit;
      end;
    end;

    // shot continues
    result := true;
    exit;
  end;

  // shoot a thing
  th := _in.d.thing;
  if th = shootthing then
  begin
    result := true; // can't shoot self
    exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    result := true; // corpse or something
    exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, _in.frac);
  thingtopslope := FixedDiv(th.z + th.height - shootz, dist);

  if thingtopslope < aimslope then
  begin
    result := true; // shot over the thing
    exit;
  end;

  thingbottomslope := FixedDiv(th.z - shootz, dist);

  if thingbottomslope > aimslope then
  begin
    result := true; // shot under the thing
    exit;
  end;


  // hit thing
  // position a bit closer
  frac := _in.frac - FixedDiv(10 * FRACUNIT, attackrange);

  x := trace.x + FixedMul(trace.dx, frac);
  y := trace.y + FixedMul(trace.dy, frac);
  z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

  // Spawn bullet puffs or blood spots,
  // depending on target type.
  if _in.d.thing.flags and MF_NOBLOOD <> 0 then
    P_SpawnPuff(x, y, z)
  else
    P_SpawnBlood(x, y, z, la_damage);

  if la_damage <> 0 then
    P_DamageMobj(th, shootthing, shootthing, la_damage);

  // don't go any farther
  result := false;
end;

//
// P_AimLineAttack
//

function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;
var
  x2: fixed_t;
  y2: fixed_t;
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  shootthing := t1;

  x2 := t1.x + FixedInt(distance) * finecosine[angle];
  y2 := t1.y + FixedInt(distance) * finesine[angle];
  shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;

  // can't shoot outside view angles
  topslope := (100 * FRACUNIT) div 160; // JVAL maybe screenwidth / 2
  bottomslope := -topslope; // JVAL

  attackrange := distance;
  linetarget := nil;

  P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_AimTraverse);

  if linetarget <> nil then
    result := aimslope
  else
    result := 0;
end;

//
// P_LineAttack
// If damage == 0, it is just a test trace
// that will leave linetarget set.
//
procedure P_LineAttack(t1: Pmobj_t; angle: angle_t;
  distance: fixed_t; slope: fixed_t; damage: integer);
var
  x2: fixed_t;
  y2: fixed_t;
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  shootthing := t1;
  la_damage := damage;
  x2 := t1.x + FixedInt(distance) * finecosine[angle];
  y2 := t1.y + FixedInt(distance) * finesine[angle];
  shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;
  if t1.flags2 and MF2_FEETARECLIPPED <> 0 then
    shootz := shootz - FOOTCLIPSIZE;
  attackrange := distance;
  aimslope := slope;

  P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_ShootTraverse);
end;

//
// USE LINES
//
var
  usething: Pmobj_t;

function PTR_UseTraverse(_in: Pintercept_t): boolean;
var
  side: integer;
begin
  if _in.d.line.special = 0 then
  begin
    P_LineOpening(_in.d.line);
    if openrange <= 0 then
    begin
      //S_StartSound(usething, Ord(sfx_noway));
      // can't use through a wall
      result := false;
      exit;
    end;
    // not a special line, but keep checking
    result := true;
    exit;
  end;

  side := 0;
  if P_PointOnLineSide(usething.x, usething.y, _in.d.line) = 1 then
    side := 1;

    //  return false;    // don't use back side

  P_UseSpecialLine(usething, _in.d.line, side);

  // can't use for than one special line in a row
  result := false;
end;

//
// P_UseLines
// Looks for special lines in front of the player to activate.
//
procedure P_UseLines(player: Pplayer_t);
var
  angle: angle_t;
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
begin
  usething := player.mo;

  {$IFDEF FPC}
  angle := _SHRW(player.mo.angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := player.mo.angle shr ANGLETOFINESHIFT;
  {$ENDIF}

  x1 := player.mo.x;
  y1 := player.mo.y;
  x2 := x1 + USERANGEINT * finecosine[angle];
  y2 := y1 + USERANGEINT * finesine[angle];

  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES, PTR_UseTraverse);
end;

//
// RADIUS ATTACK
//
var
  bombsource: Pmobj_t;
  bombspot: Pmobj_t;
  bombdamage: integer;


//
// PIT_RadiusAttack
// "bombsource" is the creature
// that caused the explosion at "bombspot".
//
function PIT_RadiusAttack(thing: Pmobj_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  dist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  // Boss spider and cyborg
  // take no damage from concussion.
  if (thing._type = Ord(MT_MINOTAUR)) or (thing._type = Ord(MT_SORCERER1)) or (thing._type = Ord(MT_SORCERER2)) then
  begin
    result := true;
    exit;
  end;

  // Other bosses
  if (thing.flags_ex and MF_EX_BOSS <> 0) or (thing.flags2 and MF2_BOSS <> 0) then
  begin
    result := true;
    exit;
  end;

  if thing.flags_ex and MF_EX_NORADIUSDMG <> 0 then
  begin
    result := true;
    exit;
  end;

  if bombsource <> nil then
  begin
    if thing.player = nil then
      if bombsource.info.doomednum > 0 then
      begin
        if bombsource.info.flags_ex and MF_EX_DONTHURTSPECIES <> 0 then
          if Info_GetInheritance(thing.info) = Info_GetInheritance(bombsource.info) then
          begin
            result := true;
            exit;
          end;
      end;
  end;

  dx := abs(thing.x - bombspot.x);
  dy := abs(thing.y - bombspot.y);

  if dx > dy then
    dist := dx
  else
    dist := dy;
  dist := FixedInt(dist - thing.radius);

  if dist < 0 then
    dist := 0;

  if dist >= bombdamage then
  begin
    result := true; // out of range
    exit;
  end;

  if P_CheckSight(thing, bombspot) then
  begin
    // must be in direct path
    P_DamageMobj(thing, bombspot, bombsource, bombdamage - dist);
  end;

  result := true;
end;

//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; const damage: integer);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := (damage + MAXRADIUS) * FRACUNIT;
  yh := MapBlockInt(spot.y + dist - bmaporgy);
  yl := MapBlockInt(spot.y - dist - bmaporgy);
  xh := MapBlockInt(spot.x + dist - bmaporgx);
  xl := MapBlockInt(spot.x - dist - bmaporgx);
  bombspot := spot;
  bombsource := source;
  bombdamage := damage;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttack);
end;

//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
procedure P_RadiusAttackEx(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := distance * FRACUNIT;
  yh := MapBlockInt(spot.y + dist - bmaporgy);
  yl := MapBlockInt(spot.y - dist - bmaporgy);
  xh := MapBlockInt(spot.x + dist - bmaporgx);
  xl := MapBlockInt(spot.x - dist - bmaporgx);
  bombspot := spot;
  bombsource := source;
  bombdamage := damage;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttack);
end;


//
// SECTOR HEIGHT CHANGING
// After modifying a sectors floor or ceiling height,
// call this routine to adjust the positions
// of all things that touch the sector.
//
// If anything doesn't fit anymore, true will be returned.
// If crunch is true, they will take damage
//  as they are being crushed.
// If Crunch is false, you should set the sector height back
//  the way it was and call P_ChangeSector again
//  to undo the changes.
//
var
  crushchange: boolean;
  nofit: boolean;

//
// PIT_ChangeSector
//
function PIT_ChangeSector(thing: Pmobj_t): boolean;
var
  mo: Pmobj_t;
begin
  if P_ThingHeightClip(thing) then
  begin
    // keep checking
    result := true;
    exit;
  end;

  // crunch bodies to giblets
  if thing.health <= 0 then
  begin
    thing.flags := thing.flags and (not MF_SOLID); // JVAL: check
    thing.height := 0;
    thing.radius := 0;

    // keep checking
    result := true;
    exit;
  end;

  // crunch dropped items
  if thing.flags and MF_DROPPED <> 0 then
  begin
    P_RemoveMobj(thing);

    // keep checking
    result := true;
    exit;
  end;

  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    // assume it is bloody gibs or something
    result := true;
    exit;
  end;

  nofit := true;

  if crushchange and ((leveltime and 3) = 0) then
  begin
    P_DamageMobj(thing, nil, nil, 10);

    // spray blood in a random direction
    mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, Ord(MT_BLOOD));

    mo.momx := _SHL(P_Random - P_Random, 12);
    mo.momy := _SHL(P_Random - P_Random, 12);
  end;

  // keep checking (crush other things)
  result := true;
end;

//
// P_ChangeSector
//
function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
var
  x: integer;
  y: integer;
  pbox: PIntegerArray;
begin
  nofit := false;
  crushchange := crunch;

  // re-check heights for all things near the moving sector
  pbox := @sector.blockbox;
  for x := pbox[BOXLEFT] to pbox[BOXRIGHT] do
    for y := pbox[BOXBOTTOM] to pbox[BOXTOP] do
      P_BlockThingsIterator(x, y, PIT_ChangeSector);

  result := nofit;
end;


// JVAL Allow jumps in sectors with sky ceiling.... (7/8/2007)
function P_SectorJumpOverhead(const s: Psector_t; const p: Pplayer_t): integer;
begin
  result := 0;
  if s.ceilingpic = skyflatnum then
  begin
    if p <> nil then
      if p.powers[Ord(pw_flight)] <> 0 then
        exit;
    if not G_NeedsCompatibilityMode then
      result := 128 * FRACUNIT;
  end;
end;

//----------------------------------------------------------------------------
//
// FUNC P_TestMobjLocation
//
// Returns true if the mobj is not blocked by anything at its current
// location, otherwise returns false.
//
//----------------------------------------------------------------------------

function P_TestMobjLocation(mobj: Pmobj_t): boolean;
var
  flags: integer;
begin
  flags := mobj.flags;
  mobj.flags := mobj.flags and (not MF_PICKUP);
  if P_CheckPosition(mobj, mobj.x, mobj.y) then
  begin // XY is ok, now check Z
    mobj.flags := flags;
    if (mobj.z < mobj.floorz) or
       (mobj.z + mobj.height > mobj.ceilingz) then
    begin // Bad Z
      result := false;
      exit;
    end;
    result := true;
    exit;
  end;
  mobj.flags := flags;
  result := false;
end;

end.
