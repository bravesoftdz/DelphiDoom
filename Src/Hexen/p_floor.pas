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
//  DESCRIPTION:
//    Floor animation: raising stairs.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_floor;

interface

uses
  d_delphi,
  doomdef,
  z_zone,
  p_spec,
  m_fixed,
  p_local,
  r_defs,
  s_sound,
  doomstat,
  sounds;

//
// FLOORS
//

function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; dir: integer): result_e;

procedure T_MoveFloor(floor: Pfloormove_t);

function EV_DoFloor(line: Pline_t; args: PByteArray; floortype: floor_e): boolean;

function EV_BuildStairs(line: Pline_t; args: PByteArray; dir: integer;
  stairsType: stairs_e): boolean;

function EV_BuildPillar(line: Pline_t; args: PByteArray; crush: boolean): boolean;

function EV_OpenPillar(line: Pline_t; args: PByteArray): boolean;

function EV_FloorCrushStop(line: Pline_t; args: PByteArray): boolean;

function EV_DoFloorAndCeiling(line: Pline_t; args: PByteArray; doraise: boolean): boolean;

function EV_StartFloorWaggle(tag: integer; height: integer; speed: integer;
  offset: integer; timer: integer): boolean;

procedure T_BuildPillar(pillar: Ppillar_t);

procedure T_FloorWaggle(waggle: PfloorWaggle_t);

implementation

uses
  doomdata,
  d_think,
  i_system,
  p_map, p_tick, p_mobj_h, p_setup, p_ceilng, p_acs, p_extra,
  r_data, r_main,
  s_sndseq;

//
// Move a plane (floor or ceiling) and check for crushing
//
function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; dir: integer): result_e;
var
  lastpos: fixed_t;
begin
  case floorOrCeiling of
    0:
      begin
        // FLOOR
        if dir = -1 then
        begin
        // DOWN
          if sector.floorheight - speed < dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end;
          end;
        end
        else if dir = 1 then
        begin
        // UP
          if sector.floorheight + speed > dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight + speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end
          end;
        end;
      end;
    1:
      begin
      // CEILING
        if dir = -1 then
        begin
        // DOWN
          if sector.ceilingheight - speed < dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end;
          end;
        end
        else if dir = 1 then
        begin
        // UP
          if sector.ceilingheight + speed > dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
            sector.ceilingheight := sector.ceilingheight + speed;
            P_ChangeSector(sector, crush);
          end;
        end;
      end;
  end;
  result := RES_OK;
end;

//
// MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
//
procedure T_MoveFloor(floor: Pfloormove_t);
var
  res: result_e;
begin
  if floor.resetDelayCount <> 0 then
  begin
    dec(floor.resetDelayCount);
    if floor.resetDelayCount = 0 then
    begin
      floor.floordestheight := floor.resetHeight;
      floor.direction := -floor.direction;
      floor.resetDelay := 0;
      floor.delayCount := 0;
      floor.delayTotal := 0;
    end;
  end;

  if floor.delayCount <> 0 then
  begin
    dec(floor.delayCount);
    if (floor.delayCount = 0) and (floor.textureChange <> 0) then
      floor.sector.floorpic := floor.sector.floorpic + floor.textureChange;
    exit;
  end;

  res := T_MovePlane(floor.sector, floor.speed, floor.floordestheight,
            floor.crush, 0, floor.direction);

  if floor._type = FLEV_RAISEBUILDSTEP then
  begin
    if ((floor.direction = 1) and (floor.sector.floorheight >= floor.stairsDelayHeight)) or
       ((floor.direction = -1) and (floor.sector.floorheight <= floor.stairsDelayHeight)) then
    begin
      floor.delayCount := floor.delayTotal;
      floor.stairsDelayHeight := floor.stairsDelayHeight + floor.stairsDelayHeightDelta;
    end;
  end;

  if res = RES_PASTDEST then 
  begin
    S_StopSequence(Pmobj_t(@floor.sector.soundorg));
    if floor.delayTotal <> 0 then
      floor.delayTotal := 0;
    if floor.resetDelay <> 0 then
      exit;
    floor.sector.specialdata := nil;
    if floor.textureChange <> 0 then
      floor.sector.floorpic := floor.sector.floorpic - floor.textureChange;
    P_TagFinished(floor.sector.tag);
    P_RemoveThinker(@floor.thinker);
  end;
  
end;

//==================================================================
//
//      HANDLE FLOOR TYPES
//
//==================================================================
function EV_DoFloor(line: Pline_t; args: PByteArray; floortype: floor_e): boolean;
var
  secnum: integer;
  sec: Psector_t;
  floor: Pfloormove_t;

  function _FindSectorFromTag: integer;
  begin
    secnum := P_FindSectorFromTag(args[0], secnum);
    result := secnum;
  end;

begin
  floor := nil;

  secnum := -1;
  result := false;

  while _FindSectorFromTag >= 0 do
  begin
    sec := @sectors[secnum];

    //      ALREADY MOVING?  IF SO, KEEP GOING...
    if sec.specialdata <> nil then
      continue;

    //
    //      new floor thinker
    //
    result := true;
    floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
    memset(floor, 0, sizeof(floormove_t));
    P_AddThinker(@floor.thinker);
    sec.specialdata := floor;
    floor.thinker._function.acp1 := @T_MoveFloor;
    floor._type := floortype;
    floor.crush := false;
    floor.speed := args[1] * (FRACUNIT div 8);
    if (floortype = FLEV_LOWERTIMES8INSTANT) or (floortype = FLEV_RAISETIMES8INSTANT) then
      floor.speed := 2000 shl FRACBITS;

    case floortype of
      FLEV_LOWERFLOOR:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.floordestheight := P_FindHighestFloorSurrounding(sec);
        end;
      FLEV_LOWERFLOORTOLOWEST:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.floordestheight := P_FindLowestFloorSurrounding(sec);
        end;
      FLEV_LOWERFLOORBYVALUE:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.floordestheight := floor.sector.floorheight - args[2] * FRACUNIT;
        end;
      FLEV_LOWERTIMES8INSTANT,
      FLEV_LOWERBYVALUETIMES8:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.floordestheight := floor.sector.floorheight - args[2] * FRACUNIT * 8;
        end;
      FLEV_RAISEFLOORCRUSH:
        begin
          floor.crush := args[2] <> 0; // arg[2] := crushing value
          floor.direction := 1;
          floor.sector := sec;
          floor.floordestheight := sec.ceilingheight - 8 * FRACUNIT;
        end;
      FLEV_RAISEFLOOR:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.floordestheight := P_FindLowestCeilingSurrounding(sec);
          if floor.floordestheight > sec.ceilingheight then
            floor.floordestheight := sec.ceilingheight;
        end;
      FLEV_RAISEFLOORTONEAREST:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.floordestheight := P_FindNextHighestFloor(sec, sec.floorheight);
        end;
      FLEV_RAISEFLOORBYVALUE:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.floordestheight := floor.sector.floorheight + args[2] * FRACUNIT;
        end;
      FLEV_RAISETIMES8INSTANT,
      FLEV_RAISEBYVALUETIMES8:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.floordestheight := floor.sector.floorheight + args[2] * FRACUNIT * 8;
        end;
      FLEV_MOVETOVALUETIMES8:
        begin
          floor.sector := sec;
          floor.floordestheight := args[2] * FRACUNIT * 8;
          if args[3] <> 0 then
            floor.floordestheight := -floor.floordestheight;
          if floor.floordestheight > floor.sector.floorheight then
            floor.direction := 1
          else if floor.floordestheight < floor.sector.floorheight then
            floor.direction := -1
          else // already at lowest position
            result := false;
        end;
      else
        result := false;
    end;
  end;

  if result then
    S_StartSequence(Pmobj_t(@floor.sector.soundorg), Ord(SEQ_PLATFORM) + Ord(floor.sector.seqType));  // JVAL SOS
end;

//============================================================================
//
// EV_DoFloorAndCeiling
//
//============================================================================

function EV_DoFloorAndCeiling(line: Pline_t; args: PByteArray; doraise: boolean): boolean;
var
  floor, ceiling: boolean;
  secnum: integer;
  sec: Psector_t;

  function _FindSectorFromTag: integer;
  begin
    secnum := P_FindSectorFromTag(args[0], secnum);
    result := secnum;
  end;

begin
  if doraise then
  begin
    floor := EV_DoFloor(line, args, FLEV_RAISEFLOORBYVALUE);
    secnum := -1;
    while _FindSectorFromTag >= 0 do
    begin
      sec := @sectors[secnum];
      sec.specialdata := nil;
    end;
    ceiling := EV_DoCeiling(line, args, CLEV_RAISEBYVALUE);
  end
  else
  begin
    floor := EV_DoFloor(line, args, FLEV_LOWERFLOORBYVALUE);
    secnum := -1;
    while _FindSectorFromTag >= 0 do
    begin
      sec := @sectors[secnum];
      sec.specialdata := nil;
    end;
    ceiling := EV_DoCeiling(line, args, CLEV_LOWERBYVALUE);
  end;
  result := floor or ceiling;
end;

// ===== Build Stairs Private Data =====

const
  STAIR_SECTOR_TYPE = 26;
  STAIR_QUEUE_SIZE = 32;

type
  stairqueueitem_t = record
    sector: Psector_t;
    _type: integer;
    height: integer;
  end;

var
  StairQueue: array[0..STAIR_QUEUE_SIZE - 1] of stairqueueitem_t;

var
  QueueHead: integer;
  QueueTail: integer;

  StepDelta: integer;
  Direction: integer;
  Speed: integer;
  Texture: integer;
  StartDelay: integer;
  StartDelayDelta: integer;
  TextureChange: integer;
  StartHeight: integer;

//==========================================================================
//
// QueueStairSector
//
//==========================================================================

procedure QueueStairSector(sec: Psector_t; _type: integer; height: integer);
begin
  if (QueueTail + 1) mod STAIR_QUEUE_SIZE = QueueHead then
    I_Error('BuildStairs():  Too many branches located.');

  StairQueue[QueueTail].sector := sec;
  StairQueue[QueueTail]._type := _type;
  StairQueue[QueueTail].height := height;

  QueueTail := (QueueTail + 1) mod STAIR_QUEUE_SIZE;
end;

//==========================================================================
//
// DequeueStairSector
//
//==========================================================================

function DequeueStairSector(_type: PInteger; height: PInteger): Psector_t;
begin
  if QueueHead = QueueTail then
  begin // queue is empty
    result := nil;
    exit;
  end;

  _type^ := StairQueue[QueueHead]._type;
  height^ := StairQueue[QueueHead].height;
  result := StairQueue[QueueHead].sector;
  QueueHead := (QueueHead + 1) mod STAIR_QUEUE_SIZE;
end;

//==========================================================================
//
// ProcessStairSector
//
//==========================================================================

procedure ProcessStairSector(sec: Psector_t; _type: integer; height: integer;
  stairsType: stairs_e; delay: integer; resetDelay: integer);
var
  i: integer;
  tsec: Psector_t;
  floor: Pfloormove_t;
begin
  //
  // new floor thinker
  //
  height := height + StepDelta;
  floor := Z_Malloc(SizeOf(floormove_t), PU_LEVSPEC, nil);
  memset(floor, 0, SizeOf(floormove_t));
  P_AddThinker(@floor.thinker);
  sec.specialdata := floor;
  floor.thinker._function.acp1 := @T_MoveFloor;
  floor._type := FLEV_RAISEBUILDSTEP;
  floor.direction := Direction;
  floor.sector := sec;
  floor.floordestheight := height;
  case stairsType of
    STAIRS_NORMAL:
      begin
        floor.speed := Speed;
        if delay <> 0 then
        begin
          floor.delayTotal := delay;
          floor.stairsDelayHeight := sec.floorheight+StepDelta;
          floor.stairsDelayHeightDelta := StepDelta;
        end;
        floor.resetDelay := resetDelay;
        floor.resetDelayCount := resetDelay;
        floor.resetHeight := sec.floorheight;
      end;
    STAIRS_SYNC:
      begin
        floor.speed := FixedMul(Speed, FixedDiv(height - StartHeight, StepDelta));
        floor.resetDelay := delay; //arg4
        floor.resetDelayCount := delay;
        floor.resetHeight := sec.floorheight;
      end;
  end;
  S_StartSequence(Pmobj_t(@sec.soundorg), Ord(SEQ_PLATFORM) + Ord(sec.seqType));

  //
  // Find next sector to doraise
  // Find nearby sector with sector special equal to type
  //
  for i := 0 to sec.linecount - 1 do
  begin
    if sec.lines[i].flags and ML_TWOSIDED = 0 then
      continue;

    tsec := sec.lines[i].frontsector;
    if (tsec.special = _type + STAIR_SECTOR_TYPE) and (tsec.specialdata = nil) and
       (tsec.floorpic = Texture) and (tsec.validcount <> validcount) then
    begin
      QueueStairSector(tsec, _type xor 1, height);
      tsec.validcount := validcount;
    end;
    tsec := sec.lines[i].backsector;
    if (tsec.special = _type + STAIR_SECTOR_TYPE) and (tsec.specialdata = nil) and
       (tsec.floorpic = Texture) and (tsec.validcount <> validcount) then
    begin
      QueueStairSector(tsec, _type xor 1, height);
      tsec.validcount := validcount;
    end;
  end;
end;

//==================================================================
//
//      BUILD A STAIRCASE!
//
// Direction is either positive or negative, denoting build stairs
//      up or down.
//==================================================================

function EV_BuildStairs(line: Pline_t; args: PByteArray; dir: integer;
  stairsType: stairs_e): boolean;
var
  secnum: integer;
  height: integer;
  delay: integer;
  resetDelay: integer;
  sec: Psector_t;
  qSec: Psector_t;
  _type: integer;

  function _FindSectorFromTag: integer;
  begin
    secnum := P_FindSectorFromTag(args[0], secnum);
    result := secnum;
  end;

  function _DequeueStairSector: Psector_t;
  begin
    qSec := DequeueStairSector(@_type, @height);
    result := qSec;
  end;

begin
  // Set global stairs variables
  TextureChange := 0;
  Direction := dir;
  StepDelta := Direction * (args[2] * FRACUNIT);
  Speed := args[1] * (FRACUNIT div 8);
  resetDelay := args[4];
  delay := args[3];
  if stairsType = STAIRS_PHASED then
  begin
    StartDelayDelta := args[3];
    StartDelay := StartDelayDelta;
    resetDelay := StartDelayDelta;
    delay := 0;
    TextureChange := args[4];
  end;

  secnum := -1;

  inc(validcount);
  while _FindSectorFromTag >= 0 do
  begin
    sec := @sectors[secnum];

    Texture := sec.floorpic;
    StartHeight := sec.floorheight;

    // ALREADY MOVING?  IF SO, KEEP GOING...
    if sec.specialdata <> nil then
      continue;

    QueueStairSector(sec, 0, sec.floorheight);
    sec.special := 0;
  end;

  while _DequeueStairSector <> nil do
    ProcessStairSector(qSec, _type, height, stairsType, delay, resetDelay);

  result := true;
end;

//=========================================================================
//
// T_BuildPillar
//
//=========================================================================

procedure T_BuildPillar(pillar: Ppillar_t);
var
  res1, res2: result_e;
begin
  // First, doraise the floor
  res1 := T_MovePlane(pillar.sector, pillar.floorSpeed, pillar.floordest,
    pillar.crush, 0, pillar.direction); // floorOrCeiling, direction
  // Then, lower the ceiling
  res2 := T_MovePlane(pillar.sector, pillar.ceilingSpeed,
     pillar.ceilingdest, pillar.crush, 1, -pillar.direction);
  if (res1 = RES_PASTDEST) and (res2 = RES_PASTDEST) then
  begin
    pillar.sector.specialdata := nil;
    S_StopSequence(Pmobj_t(@pillar.sector.soundorg));
    P_TagFinished(pillar.sector.tag);
    P_RemoveThinker(@pillar.thinker);
  end;
end;

//=========================================================================
//
// EV_BuildPillar
//
//=========================================================================

function EV_BuildPillar(line: Pline_t; args: PByteArray; crush: boolean): boolean;
var
  secnum: integer;
  sec: Psector_t;
  pillar: Ppillar_t;
  newHeight: integer;

  function _FindSectorFromTag: integer;
  begin
    secnum := P_FindSectorFromTag(args[0], secnum);
    result := secnum;
  end;

begin
  result := false;
  secnum := -1;
  while _FindSectorFromTag >= 0 do
  begin
    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue; // already moving

    if sec.floorheight = sec.ceilingheight then
      continue; // pillar is already closed

    result := true;
    if args[2] = 0 then
      newHeight := sec.floorheight + ((sec.ceilingheight - sec.floorheight) div 2)
    else
      newHeight := sec.floorheight+(args[2] shl FRACBITS);

    pillar := Z_Malloc(SizeOf(pillar_t), PU_LEVSPEC, nil);
    sec.specialdata := pillar;
    P_AddThinker(@pillar.thinker);
    pillar.thinker._function.acp1 := @T_BuildPillar;
    pillar.sector := sec;
    if args[2] = 0 then
    begin
      pillar.ceilingSpeed := args[1] * (FRACUNIT div 8);
      pillar.floorSpeed := pillar.ceilingSpeed;
    end
    else if (newHeight - sec.floorheight) > (sec.ceilingheight - newHeight) then
    begin
      pillar.floorSpeed := args[1] * (FRACUNIT div 8);
      pillar.ceilingSpeed := FixedMul(sec.ceilingheight - newHeight,
        FixedDiv(pillar.floorSpeed, newHeight - sec.floorheight));
    end
    else
    begin
      pillar.ceilingSpeed := args[1] * (FRACUNIT div 8);
      pillar.floorSpeed := FixedMul(newHeight - sec.floorheight,
        FixedDiv(pillar.ceilingSpeed, sec.ceilingheight - newHeight));
    end;
    pillar.floordest := newHeight;
    pillar.ceilingdest := newHeight;
    pillar.direction := 1;
    pillar.crush := crush and (args[3] <> 0); // JVAL SOS
    S_StartSequence(Pmobj_t(@pillar.sector.soundorg), Ord(SEQ_PLATFORM) + Ord(pillar.sector.seqType));
  end;
end;

//=========================================================================
//
// EV_OpenPillar
//
//=========================================================================

function EV_OpenPillar(line: Pline_t; args: PByteArray): boolean;
var
  secnum: integer;
  sec: Psector_t;
  pillar: Ppillar_t;

  function _FindSectorFromTag: integer;
  begin
    secnum := P_FindSectorFromTag(args[0], secnum);
    result := secnum;
  end;

begin
  result := false;
  secnum := -1;
  while _FindSectorFromTag >= 0 do
  begin
    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue; // already moving

    if sec.floorheight <> sec.ceilingheight then
      continue; // pillar isn't closed

    result := true;
    pillar := Z_Malloc(SizeOf(pillar_t), PU_LEVSPEC, nil);
    sec.specialdata := pillar;
    P_AddThinker(@pillar.thinker);
    pillar.thinker._function.acp1 := @T_BuildPillar;
    pillar.sector := sec;
    if args[2] = 0 then
      pillar.floordest := P_FindLowestFloorSurrounding(sec)
    else
      pillar.floordest := sec.floorheight-(args[2] shl FRACBITS);

    if args[3] = 0 then
      pillar.ceilingdest := P_FindHighestCeilingSurrounding(sec)
    else
      pillar.ceilingdest := sec.ceilingheight+(args[3] shl FRACBITS);

    if (sec.floorheight - pillar.floordest) >=
       (pillar.ceilingdest - sec.ceilingheight) then
    begin
      pillar.floorSpeed := args[1] * (FRACUNIT div 8);
      pillar.ceilingSpeed :=
        FixedMul(sec.ceilingheight - pillar.ceilingdest,
          FixedDiv(pillar.floorSpeed, pillar.floordest - sec.floorheight));
    end
    else
    begin
      pillar.ceilingSpeed := args[1] * (FRACUNIT div 8);
      pillar.floorSpeed :=
        FixedMul(pillar.floordest - sec.floorheight,
          FixedDiv(pillar.ceilingSpeed, sec.ceilingheight - pillar.ceilingdest));
    end;
    pillar.direction := -1; // open the pillar
    S_StartSequence(Pmobj_t(@pillar.sector.soundorg), Ord(SEQ_PLATFORM) + Ord(pillar.sector.seqType));
  end;
end;

//=========================================================================
//
// EV_FloorCrushStop
//
//=========================================================================

function EV_FloorCrushStop(line: Pline_t; args: PByteArray): boolean;
var
  think: Pthinker_t;
  floor: Pfloormove_t;
begin
  result := false;

  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 <> @T_MoveFloor then
    begin
      think := think.next;
      continue;
    end;

    floor := Pfloormove_t(think);
    if floor._type <> FLEV_RAISEFLOORCRUSH then
    begin
      think := think.next;
      continue;
    end;

    // Completely remove the crushing floor
    S_StopSequence(Pmobj_t(@floor.sector.soundorg));
    floor.sector.specialdata := nil;
    P_TagFinished(floor.sector.tag);
    P_RemoveThinker(@floor.thinker);
    think := think.next;
    result := true;
  end;
end;

//==========================================================================
//
// T_FloorWaggle
//
//==========================================================================

const
  WGLSTATE_EXPAND = 1;
  WGLSTATE_STABLE = 2;
  WGLSTATE_REDUCE = 3;

procedure T_FloorWaggle(waggle: PfloorWaggle_t);
begin
  case waggle.state of
    WGLSTATE_EXPAND:
      begin
        waggle.scale := waggle.scale + waggle.scaleDelta;
        if waggle.scale >= waggle.targetScale then
        begin
          waggle.scale := waggle.targetScale;
          waggle.state := WGLSTATE_STABLE;
        end;
      end;
    WGLSTATE_REDUCE:
      begin
        waggle.scale := waggle.scale - waggle.scaleDelta;
        if waggle.scale <= 0 then
        begin // Remove
          waggle.sector.floorheight := waggle.originalHeight;
          P_ChangeSector(waggle.sector, true);
          waggle.sector.specialdata := nil;
          P_TagFinished(waggle.sector.tag);
          P_RemoveThinker(@waggle.thinker);
          exit;
        end;
      end;
    WGLSTATE_STABLE:
      begin
        if waggle.ticker <> -1 then
        begin
          dec(waggle.ticker); // JVAL SOS
          if waggle.ticker <> 0 then
            waggle.state := WGLSTATE_REDUCE;
        end;
      end;
  end;

  waggle.accumulator := waggle.accumulator + waggle.accDelta;
  waggle.sector.floorheight := waggle.originalHeight +
    FixedMul(FloatBobOffsets[_SHR(waggle.accumulator, FRACBITS) and 63], waggle.scale);
  P_ChangeSector(waggle.sector, true);
end;

//==========================================================================
//
// EV_StartFloorWaggle
//
//==========================================================================

function EV_StartFloorWaggle(tag: integer; height: integer; speed: integer;
  offset: integer; timer: integer): boolean;
var
  sectorIndex: integer;
  sector: Psector_t;
  waggle: PfloorWaggle_t;

  function _FindSectorFromTag: integer;
  begin
    result := P_FindSectorFromTag(tag, sectorIndex);
    sectorIndex := result;
  end;

begin
  result := false;
  sectorIndex := -1;

  while _FindSectorFromTag >= 0 do
  begin
    sector := @sectors[sectorIndex];
    if sector.specialdata <> nil then
      continue; // Already busy with another thinker

    result := true;
    waggle := Z_Malloc(SizeOf(floorWaggle_t), PU_LEVSPEC, nil);
    sector.specialdata := waggle;
    waggle.thinker._function.acp1 := @T_FloorWaggle;
    waggle.sector := sector;
    waggle.originalHeight := sector.floorheight;
    waggle.accumulator := offset * FRACUNIT;
    waggle.accDelta := _SHL(speed, 10);
    waggle.scale := 0;
    waggle.targetScale := _SHL(height, 10);
    waggle.scaleDelta := waggle.targetScale div (35 + ((3 * 35) * height) div 255);
    if timer <> 0 then
      waggle.ticker := timer * TICRATE
    else
      waggle.ticker := -1;

    waggle.state := WGLSTATE_EXPAND;
    P_AddThinker(@waggle.thinker);
  end;
end;

end.

