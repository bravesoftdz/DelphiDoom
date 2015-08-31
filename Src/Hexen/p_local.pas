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
//  Play functions, animation, global header. 
// 
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_local;

interface

uses
  doomtype,
  m_fixed,
  p_mobj_h,
  r_defs;

const
  TOCENTER = -8;
  TOFORWARD = -8;

  FLOATSPEED = FRACUNIT * 4;

// Player VIEWHEIGHT
  PVIEWHEIGHT = 48 * FRACUNIT;

// mapblocks are used to check movement
// against lines and things
  MAPBLOCKUNITS = 128;
  MAPBLOCKSIZE = MAPBLOCKUNITS * FRACUNIT;

  MAPBLOCKSHIFT = FRACBITS + 7;
  MAPBMASK = MAPBLOCKSIZE - 1;
  MAPBTOFRAC = MAPBLOCKSHIFT - FRACBITS;

// player radius for movement checking
  PLAYERRADIUS = 16 * FRACUNIT;

// MAXRADIUS is for precalculated sector block boxes
// the spider demon is larger,
// but we do not have any moving sectors nearby
  MAXRADIUS = 32 * FRACUNIT;

  GRAVITY = FRACUNIT;
  MAXMOVE = 30 * FRACUNIT;

  USERANGEINT = 64;
  USERANGE = USERANGEINT * FRACUNIT;
  MELEERANGE = 64 * FRACUNIT;
  MISSILERANGE = (32 * 64) * FRACUNIT;


// follow a player exlusively for 3 seconds
  BASETHRESHOLD = 100;

const
  FLOOR_SOLID = 0;
  FLOOR_ICE = 1;
  FLOOR_LIQUID = 2;
  FLOOR_WATER = 3;
  FLOOR_LAVA = 4;
  FLOOR_SLUDGE = 5;

const
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  STARTPOISONPALS = 13;
  STARTICEPAL = 21;
  STARTHOLYPAL = 22;
  STARTSCOURGEPAL = 25;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;
  NUMPOISONPALS = 8;

const
  ONFLOORZ = MININT;
  ONCEILINGZ = MAXINT;
  FLOATRANDZ = MAXINT - 1;

type
  divline_t = record
    x: fixed_t;
    y: fixed_t;
    dx: fixed_t;
    dy: fixed_t;
  end;
  Pdivline_t = ^divline_t;
  divline_tArray = array[0..$FFFF] of divline_t;
  Pdivline_tArray = ^divline_tArray;

  thingORline_t = record
    case integer of
      0: (thing: Pmobj_t);
      1: (line: Pline_t);
    end;

  intercept_t = record
    frac : fixed_t; // along trace line
    isaline : boolean;
    d: thingORline_t;
  end;
  Pintercept_t = ^intercept_t;

const
  MAXINTERCEPTS = 128;

type
  traverser_t = function(f: Pintercept_t): boolean;
  ltraverser_t = function(p: Pline_t): boolean;
  ttraverser_t = function(p: Pmobj_t): boolean;

const
  PT_ADDLINES = 1;
  PT_ADDTHINGS = 2;
  PT_EARLYOUT = 4;

const
  USE_GWND_AMMO_1 = 1;
  USE_GWND_AMMO_2 = 1;
  USE_CBOW_AMMO_1 = 1;
  USE_CBOW_AMMO_2 = 1;
  USE_BLSR_AMMO_1 = 1;
  USE_BLSR_AMMO_2 = 5;
  USE_SKRD_AMMO_1 = 1;
  USE_SKRD_AMMO_2 = 5;
  USE_PHRD_AMMO_1 = 1;
  USE_PHRD_AMMO_2 = 1;
  USE_MACE_AMMO_1 = 1;
  USE_MACE_AMMO_2 = 5;

const
  FOOTCLIPSIZE = 10 * FRACUNIT;

function MapBlockInt(const x: integer): integer;

function MapToFrac(const x: integer): integer;

function HITDICE(a: integer): integer;

implementation

uses
  m_rnd;

function MapBlockInt(const x: integer): integer; assembler;
asm
  sar eax, MAPBLOCKSHIFT
end;

function MapToFrac(const x: integer): integer; assembler;
asm
  sar eax, MAPBTOFRAC
end;

function HITDICE(a: integer): integer;
begin
  result :=  (1 + (P_Random and 7)) * a;
end;

end.

