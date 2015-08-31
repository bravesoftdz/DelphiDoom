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
// DESCRIPTION:
//  Door animation code (opening/closing)
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_doors;

interface

uses
  d_delphi,
  z_zone,
  doomdef,
  m_fixed,
  p_local,
  p_mobj_h,
  p_spec,
  r_defs,
  s_sound,
// State.
  doomstat,
// Data.
  sounds;

procedure T_VerticalDoor(door: Pvldoor_t);

function EV_DoDoor(line: Pline_t; args: PByteArray; _type: vldoor_e): boolean;

function EV_VerticalDoor(line: Pline_t; thing: Pmobj_t): boolean;

implementation

uses
  d_player,
  p_tick,
  p_setup,
  p_floor,
  p_acs,
  s_sndseq,
  xn_strings;

//
// VERTICAL DOORS
//

//
// T_VerticalDoor
//
procedure T_VerticalDoor(door: Pvldoor_t);
var
  res: result_e;
begin
  case door.direction of
    0:
      begin
  // WAITING
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door._type of
            DREV_NORMAL:
              begin
                door.direction := -1; // time to go back down
                S_StartSequence(Pmobj_t(@door.sector.soundorg), Ord(SEQ_DOOR_STONE) + Ord(door.sector.seqType));
              end;
            DREV_CLOSE30THENOPEN:
              begin
                door.direction := 1;
              end;
          end;
        end;
      end;
    2:
      begin
  //  INITIAL WAIT
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door._type of
            DREV_RAISEIN5MINS:
              begin
                door.direction := 1;
                door._type := DREV_NORMAL;
              end;
          end;
        end;
      end;

   -1:
      begin
  // DOWN
        res := T_MovePlane(door.sector, door.speed, door.sector.floorheight,
                  false, 1, door.direction);
        if res = RES_PASTDEST then
        begin
           S_StopSequence(Pmobj_t(@door.sector.soundorg));
          case door._type of
            DREV_NORMAL,
            DREV_CLOSE:
              begin
                door.sector.specialdata := nil;
                P_TagFinished(door.sector.tag);
                P_RemoveThinker(@door.thinker);  // unlink and free
              end;
            DREV_CLOSE30THENOPEN:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 30;
              end;
          end;
        end
        else if res = RES_CRUSHED then
        begin
          case door._type of
            DREV_CLOSE:    // DO NOT GO BACK UP!
              begin
              end;
          else
            begin
              door.direction := 1;
            end;
          end;
        end;
      end;
    1:
      begin
  // UP
        res := T_MovePlane(door.sector, door.speed, door.topheight,
                  false, 1, door.direction);
        if res = RES_PASTDEST then
        begin
          S_StopSequence(Pmobj_t(@door.sector.soundorg));
          case door._type of
            DREV_NORMAL:
              begin
                door.direction := 0; // wait at top
                door.topcountdown := door.topwait;
              end;
            DREV_CLOSE30THENOPEN,
            DREV_OPEN:
              begin
                door.sector.specialdata := nil;
                P_TagFinished(door.sector.tag);
                P_RemoveThinker(@door.thinker); // unlink and free
              end;
          end;
        end;
      end;
  end;
end;


//----------------------------------------------------------------------------
//
// EV_DoDoor
//
// Move a door up/down
//
//----------------------------------------------------------------------------

function EV_DoDoor(line: Pline_t; args: PByteArray; _type: vldoor_e): boolean;
var
  initial: boolean;
  secnum: integer;
  sec: Psector_t;
  door: Pvldoor_t;
  speed: fixed_t;
begin
  speed := args[1] * (FRACUNIT div 8);
  secnum := -1;
  result := false;

  initial := true;
  while (secnum >= 0) or initial do
  begin
    initial := false;
    secnum := P_FindSectorFromTag(args[0], secnum);
    if secnum < 0 then
      break;

    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue;

    // new door thinker
    result := true;
    door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
    P_AddThinker(@door.thinker);
    sec.specialdata := door;

    door.thinker._function.acp1 := @T_VerticalDoor;
    door.sector := sec;

    case _type of
      DREV_CLOSE:
        begin
          door.topheight := P_FindLowestCeilingSurrounding(sec);
          door.topheight := door.topheight - 4 * FRACUNIT;
          door.direction := -1;
        end;

      DREV_CLOSE30THENOPEN:
        begin
          door.topheight := sec.ceilingheight;
          door.direction := -1;
        end;

      DREV_NORMAL,
      DREV_OPEN:
        begin
          door.direction := 1;
          door.topheight := P_FindLowestCeilingSurrounding(sec);
          door.topheight := door.topheight - 4 * FRACUNIT;
        end;
    end;

    door._type := _type;
    door.speed := speed;
    door.topwait := args[2];
    S_StartSequence(Pmobj_t(@door.sector.soundorg), Ord(SEQ_DOOR_STONE) + Ord(door.sector.seqType));
  end;
end;

//
// EV_VerticalDoor : open a door manually, no tag value
//
function EV_VerticalDoor(line: Pline_t; thing: Pmobj_t): boolean;
var
  sec: Psector_t;
  door: Pvldoor_t;
  side: integer;
begin
  side := 0; // only front sides can be used

  // if the sector has an active thinker, use it
  sec := sides[line.sidenum[side xor 1]].sector;
  if sec.specialdata <> nil then
  begin
    result := false;
    exit;
  end;

  //
  // new door thinker
  //
  door := Z_Malloc(SizeOf(vldoor_t), PU_LEVSPEC, nil);
  P_AddThinker(@door.thinker);
  sec.specialdata := door;
  door.thinker._function.acp1 := @T_VerticalDoor;
  door.sector := sec;
  door.direction := 1;
  case line.special of
    11:
      begin
        door._type := DREV_OPEN;
        line.special := 0;
      end;
    12,
    13:
      begin
        door._type := DREV_NORMAL;
      end;
  else
    door._type := DREV_NORMAL;
  end;

  door.speed := line.arg2 * (FRACUNIT div 8);
  door.topwait := line.arg3;

  //
  // find the top and bottom of the movement range
  //
  door.topheight := P_FindLowestCeilingSurrounding(sec);
  door.topheight := door.topheight - 4 * FRACUNIT;
  S_StartSequence(Pmobj_t(@door.sector.soundorg), Ord(SEQ_DOOR_STONE) + Ord(door.sector.seqType));
  result := true;
end;

end.
