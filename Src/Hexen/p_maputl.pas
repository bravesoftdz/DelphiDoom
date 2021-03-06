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
//  Movement/collision utility functions,
//  as used by function in p_map.c.
//  BLOCKMAP Iterator functions,
//  and some PIT_* functions to use for iteration.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_maputl;

interface

uses
  m_bbox,
  doomdef,
  p_local,
  p_mobj_h,
  m_fixed,
  r_defs;

function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;

function P_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): integer;

function P_BoxOnLineSide(tmbox: Pfixed_tArray; ld: Pline_t): integer;

function P_InterceptVector(v2: Pdivline_t; v1: Pdivline_t): fixed_t;

procedure P_LineOpening(linedef: Pline_t);

procedure P_UnsetThingPosition(thing: Pmobj_t);

procedure P_SetThingPosition(thing: Pmobj_t);

function P_BlockLinesIterator(x, y: integer; func: ltraverser_t): boolean;

function P_BlockThingsIterator(x, y: integer; func: ttraverser_t): boolean;

function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: integer;
  trav: traverser_t): boolean;

function P_PointOnDivlineSide(x: fixed_t; y: fixed_t; line: Pdivline_t): integer;

procedure P_MakeDivline(li: Pline_t; dl: Pdivline_t);

function P_RoughMonsterSearch(mo: Pmobj_t; distance: integer): Pmobj_t;

var
  opentop: fixed_t;
  openbottom: fixed_t;
  openrange: fixed_t;
  lowfloor: fixed_t;

  trace: divline_t;

var
  intercepts: array[0..MAXINTERCEPTS - 1] of intercept_t;
  intercept_p: integer;
  
implementation

uses
  d_delphi,
  g_game,
  i_system,
  info_h,
  p_setup,
  p_map,
  p_sight,
  po_man,
  r_main,
  tables,
  z_zone;

//
// P_AproxDistance
// Gives an estimation of distance (not exact)
//
function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;
begin
  dx := abs(dx);
  dy := abs(dy);
  if dx < dy then
    result := dx + dy - _SHR1(dx)
  else
    result := dx + dy - _SHR1(dy);
end;

//
// P_PointOnLineSide
// Returns 0 or 1
//
function P_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if line.dx = 0 then
  begin
    if x <= line.v1.x then
      result := intval(line.dy > 0)
    else
      result := intval(line.dy < 0);
    exit;
  end;

  if line.dy = 0 then
  begin
    if y <= line.v1.y then
      result := intval(line.dx < 0)
    else
      result := intval(line.dx > 0);
    exit;
  end;

  dx := x - line.v1.x;
  dy := y - line.v1.y;

  left := IntFixedMul(line.dy, dx);
  right := FixedIntMul(dy, line.dx);

  if right < left then
    result := 0  // front side
  else
    result := 1; // back side
end;

//
// P_BoxOnLineSide
// Considers the line to be infinite
// Returns side 0 or 1, -1 if box crosses the line.
//
function P_BoxOnLineSide(tmbox: Pfixed_tArray; ld: Pline_t): integer;
var
  p1: integer;
  p2: integer;
begin
  case ld.slopetype of
    ST_HORIZONTAL:
      begin
        p1 := intval(tmbox[BOXTOP] > ld.v1.y);
        p2 := intval(tmbox[BOXBOTTOM] > ld.v1.y);
        if ld.dx < 0 then
        begin
          p1 := p1 xor 1;
          p2 := p2 xor 1;
        end;
      end;
    ST_VERTICAL:
      begin
        p1 := intval(tmbox[BOXRIGHT] < ld.v1.x);
        p2 := intval(tmbox[BOXLEFT] < ld.v1.x);
        if ld.dy < 0 then
        begin
          p1 := p1 xor 1;
          p2 := p2 xor 1;
        end;
      end;
    ST_POSITIVE:
      begin
        p1 := P_PointOnLineSide(tmbox[BOXLEFT], tmbox[BOXTOP], ld);
        p2 := P_PointOnLineSide(tmbox[BOXRIGHT], tmbox[BOXBOTTOM], ld);
      end;
    ST_NEGATIVE:
      begin
        p1 := P_PointOnLineSide(tmbox[BOXRIGHT], tmbox[BOXTOP], ld);
        p2 := P_PointOnLineSide(tmbox[BOXLEFT], tmbox[BOXBOTTOM], ld);
      end;
  else
    begin
      p1 := 0;
      p2 := 0;
      I_Error('P_BoxOnLineSide(): wierd slopetype %d', [Ord(ld.slopetype)]);
    end;
  end;
  if p1 = p2 then
    result := p1
  else
    result := -1;
end;

//
// P_PointOnDivlineSide
// Returns 0 or 1.
//
function P_PointOnDivlineSide(x: fixed_t; y: fixed_t; line: Pdivline_t): integer;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if line.dx = 0 then
  begin
    if x <= line.x then
    begin
      if line.dy > 0 then
        result := 1
      else
        result := 0;
    end
    else
    begin
      if line.dy < 0 then
        result := 1
      else
        result := 0;
    end;
    exit;
  end;

  if line.dy = 0 then
  begin
    if y <= line.y then
    begin
      if line.dx < 0 then
        result := 1
      else
        result := 0;
    end
    else
    begin
      if line.dx > 0 then
        result := 1
      else
        result := 0;
    end;
    exit;
  end;

  dx := x - line.x;
  dy := y - line.y;

  // try to quickly decide by looking at sign bits
  if ((line.dy xor line.dx xor dx xor dy) and $80000000) <> 0 then
  begin                                                              //(left is negative)
    result := (line.dy xor dx) and $80000000;
    if result <> 0 then
      result := 1;
    exit;
  end;

  left := FixedMul88(line.dy, dx);
  right := FixedMul88(dy, line.dx);

  if right < left then
    result := 0  // front side
  else
    result := 1; // back side
end;


//
// P_MakeDivline
//
procedure P_MakeDivline(li: Pline_t; dl: Pdivline_t);
begin
  dl.x := li.v1.x;
  dl.y := li.v1.y;
  dl.dx := li.dx;
  dl.dy := li.dy;
end;

//
// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
//
function P_InterceptVector(v2: Pdivline_t; v1: Pdivline_t): fixed_t;
var
  num: fixed_t;
  den: fixed_t;
begin
  den := FixedMul8(v1.dy, v2.dx) -
         FixedMul8(v1.dx, v2.dy);

  if den = 0 then
    result := 0     // Parallel
  else
  begin
    num := FixedMul8(v1.x - v2.x, v1.dy)  +
           FixedMul8(v2.y - v1.y, v1.dx);
    result := FixedDiv(num, den);
  end;
end;

//
// P_LineOpening
// Sets opentop and openbottom to the window
// through a two sided line.
// OPTIMIZE: keep this precalculated
//
procedure P_LineOpening(linedef: Pline_t);
var
  front: Psector_t;
  back: Psector_t;
begin
  if linedef.sidenum[1] = -1 then
  begin
    // single sided line
    openrange := 0;
    exit;
  end;

  front := linedef.frontsector;
  back := linedef.backsector;

  if front.ceilingheight < back.ceilingheight then
    opentop := front.ceilingheight + P_SectorJumpOverhead(front, nil)
  else
    opentop := back.ceilingheight + P_SectorJumpOverhead(back, nil);

  if front.floorheight > back.floorheight then
  begin
    openbottom := front.floorheight;
    lowfloor := back.floorheight;
    tmfloorpic := front.floorpic;
  end
  else
  begin
    openbottom := back.floorheight;
    lowfloor := front.floorheight;
    tmfloorpic := back.floorpic;
  end;

  openrange := opentop - openbottom;
end;

//
// THING POSITION SETTING
//


//
// P_UnsetThingPosition
// Unlinks a thing from block map and sectors.
// On each position change, BLOCKMAP and other
// lookups maintaining lists ot things inside
// these structures need to be updated.
//
procedure P_UnsetThingPosition(thing: Pmobj_t);
var
  link: Pblocklinkitem_t;
begin
  if thing.flags and MF_NOSECTOR = 0 then
  begin
    // inert things don't need to be in blockmap?
    // unlink from subsector
    if thing.snext <> nil then
      thing.snext.sprev := thing.sprev;

    if thing.sprev <> nil then
      thing.sprev.snext := thing.snext
    else
      Psubsector_t(thing.subsector).sector.thinglist := thing.snext;
  end;

  if thing.flags and MF_NOBLOCKMAP = 0 then
  begin
    // inert things don't need to be in blockmap
    // unlink from block map
    if (thing.bpos >= 0) and (thing.bpos < bmapsize) then
    begin
      link := @blocklinks[thing.bpos];
      dec(link.size);
      link.links[thing.bidx] := link.links[link.size];
      link.links[thing.bidx].bidx := thing.bidx;
      thing.bpos := -1;
      thing.bidx := -1;
    end;
  end;
end;

//
// P_SetThingPosition
// Links a thing into both a block and a subsector
// based on it's x y.
// Sets thing->subsector properly
//
procedure P_SetThingPosition(thing: Pmobj_t);
var
  ss: Psubsector_t;
  sec: Psector_t;
  blockx: integer;
  blocky: integer;
  link: Pblocklinkitem_t;
begin
  // link into subsector
  ss := R_PointInSubsector(thing.x, thing.y);
  thing.subsector := ss;

  if (thing.flags and MF_NOSECTOR) = 0 then
  begin
    // invisible things don't go into the sector links
    sec := ss.sector;

    thing.sprev := nil;
    thing.snext := sec.thinglist;

    if sec.thinglist <> nil then
      sec.thinglist.sprev := thing;

    sec.thinglist := thing;
  end;

  // link into blockmap
  if thing.flags and MF_NOBLOCKMAP = 0 then
  begin
    // inert things don't need to be in blockmap
    blockx := MapBlockInt(thing.x - bmaporgx);
    blocky := MapBlockInt(thing.y - bmaporgy);
    if (blockx >= 0) and (blockx < bmapwidth) and
       (blocky >= 0) and (blocky < bmapheight) then
    begin
      thing.bpos := blocky * bmapwidth + blockx;
      link := @blocklinks[thing.bpos];
      if link.size >= link.realsize then
      begin
        link.links := Z_ReAlloc(link.links, SizeOf(Pmobj_t) * (link.size + 16), PU_LEVEL, nil);
        link.realsize := link.size + 16;
      end;
      link.links[link.size] := thing;
      thing.bidx := link.size;
      inc(link.size);
    end
    else
    begin
      thing.bpos := -1;
      thing.bidx := -1;
    end;
  end;
end;

//
// BLOCK MAP ITERATORS
// For each line/thing in the given mapblock,
// call the passed PIT_* function.
// If the function returns false,
// exit with false without checking anything else.
//


//
// P_BlockLinesIterator
// The validcount flags are used to avoid checking lines
// that are marked in multiple mapblocks,
// so increment validcount before the first call
// to P_BlockLinesIterator, then make one or more calls
// to it.
//
function P_BlockLinesIterator(x, y: integer; func: ltraverser_t): boolean;
var
  offset: PSmallInt;
  ld: Pline_t;
  polyLink: Ppolyblock_t;
  tempSeg: PPseg_t;
  i: integer;
begin
  if (x < 0) or (y < 0) or (x >= bmapwidth) or (y >= bmapheight) then
  begin
    result := true;
    exit;
  end;

  polyLink := PolyBlockMap[y * bmapwidth + x];
  while polyLink <> nil do
  begin
    if polyLink.polyobj <> nil then
    begin
      if polyLink.polyobj.validcount <> validcount then
      begin
        polyLink.polyobj.validcount := validcount;
        tempSeg := polyLink.polyobj.segs;
        for i := 0 to polyLink.polyobj.numsegs - 1 do
        begin
          {$IFDEF OPENGL}
          if not tempSeg^.miniseg then
          {$ENDIF}
          if tempSeg^.linedef.validcount <> validcount then
          begin
            tempSeg^.linedef.validcount := validcount;
            if not func(tempSeg^.linedef) then
            begin
              result := false;
              exit;
            end;
          end;
          inc(tempSeg);
        end;
      end;
    end;
    polyLink := polyLink.next;
  end;

  offset := @blockmaplump[blockmap[y * bmapwidth + x]];

  while offset^ <> - 1 do
  begin
    ld := @lines[offset^];
    inc(offset);
    if ld.validcount = validcount then
      continue; // line has already been checked

    ld.validcount := validcount;

    if not func(ld) then
    begin
      result := false;
      exit;
    end;
  end;

  result := true; // everything was checked
end;

//
// P_BlockThingsIterator
//
function P_BlockThingsIterator(x, y: integer; func: ttraverser_t): boolean;
var
  i: integer;
  link: Pblocklinkitem_t;
begin
  if (x < 0) or (y < 0) or (x >= bmapwidth) or (y >= bmapheight) then
  begin
    result := true;
    exit;
  end;

  link := @blocklinks[y * bmapwidth + x];
  for i := 0 to link.size - 1 do
    if not func(link.links[i]) then
    begin
      result := false;
      exit;
    end;

  result := true;
end;

//
// INTERCEPT ROUTINES
//
var
  earlyout: boolean;

//
// PIT_AddLineIntercepts.
// Looks for lines in the given block
// that intercept the given trace
// to add to the intercepts list.
//
// A line is crossed if its endpoints
// are on opposite sides of the trace.
// Returns true if earlyout and a solid line hit.
//
function PIT_AddLineIntercepts(ld: Pline_t): boolean;
var
  s1: integer;
  s2: integer;
  frac: fixed_t;
  dl: divline_t;
begin
  // avoid precision problems with two routines
  if (trace.dx > FRACUNIT * 16) or (trace.dy > FRACUNIT * 16) or
     (trace.dx < -FRACUNIT * 16) or (trace.dy < -FRACUNIT * 16) then
  begin
    s1 := P_PointOnDivlineSide(ld.v1.x, ld.v1.y, @trace);
    s2 := P_PointOnDivlineSide(ld.v2.x, ld.v2.y, @trace);
  end
  else
  begin
    s1 := P_PointOnLineSide(trace.x, trace.y, ld);
    s2 := P_PointOnLineSide(trace.x + trace.dx, trace.y + trace.dy, ld);
  end;

  if s1 = s2 then
  begin
    result := true; // line isn't crossed
    exit;
  end;

  // hit the line
  P_MakeDivline(ld, @dl);
  frac := P_InterceptVector(@trace, @dl);

  if frac < 0 then
  begin
    result := true; // behind source
    exit;
  end;

  // try to early out the check
  if earlyout and (frac < FRACUNIT) and (ld.backsector = nil) then
  begin
    result := false; // stop checking
    exit;
  end;

  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := true;
  intercepts[intercept_p].d.line := ld;
  inc(intercept_p);

  result := true; // continue
end;

//
// PIT_AddThingIntercepts
//
function PIT_AddThingIntercepts(thing: Pmobj_t): boolean;
var
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
  s1: integer;
  s2: integer;
  tracepositive: boolean;
  dl: divline_t;
  frac: fixed_t;
begin
  tracepositive := (trace.dx xor trace.dy) > 0;

  // check a corner to corner crossection for hit
  if tracepositive then
  begin
    x1 := thing.x - thing.radius;
    y1 := thing.y + thing.radius;
    x2 := thing.x + thing.radius;
    y2 := thing.y - thing.radius;
  end
  else
  begin
    x1 := thing.x - thing.radius;
    y1 := thing.y - thing.radius;
    x2 := thing.x + thing.radius;
    y2 := thing.y + thing.radius;
  end;

  s1 := P_PointOnDivlineSide(x1, y1, @trace);
  s2 := P_PointOnDivlineSide(x2, y2, @trace);

  if s1 = s2 then
  begin
    result := true; // line isn't crossed
    exit;
  end;

  dl.x := x1;
  dl.y := y1;
  dl.dx := x2 - x1;
  dl.dy := y2 - y1;

  frac := P_InterceptVector(@trace, @dl);

  if frac < 0 then
  begin
    result := true; // behind source
    exit;
  end;

  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := false;
  intercepts[intercept_p].d.thing := thing;
  inc(intercept_p);

  result := true; // keep going
end;

//
// P_TraverseIntercepts
// Returns true if the traverser function returns true
// for all lines.
//
function P_TraverseIntercepts(func: traverser_t; maxfrac: fixed_t): boolean;
var
  i: integer;
  dist: fixed_t;
  scan: integer;
  _in: Pintercept_t;
begin
  _in := nil; // shut up compiler warning

  for i := 0 to intercept_p - 1 do
  begin
    dist := MAXINT;

    for scan := 0 to intercept_p - 1 do
    begin
      if intercepts[scan].frac < dist then
      begin
        dist := intercepts[scan].frac;
        _in := @intercepts[scan];
      end;
    end;

    if dist > maxfrac then
    begin
      result := true; // checked everything in range
      exit;
    end;

    if not func(_in) then
    begin
      result := false; // don't bother going farther
      exit;
    end;
    _in.frac := MAXINT;
  end;

  result := true; // everything was traversed
end;

//
// P_PathTraverse
// Traces a line from x1,y1 to x2,y2,
// calling the traverser function for each.
// Returns true if the traverser function returns true
// for all lines.
//
function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: integer;
  trav: traverser_t): boolean;
var
  xt1: fixed_t;
  yt1: fixed_t;
  xt2: fixed_t;
  yt2: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  partial: fixed_t;
  xintercept: fixed_t;
  yintercept: fixed_t;
  mapx: integer;
  mapy: integer;
  mapxstep: integer;
  mapystep: integer;
  count: integer;
begin
  earlyout := flags and PT_EARLYOUT <> 0;

  inc(validcount);
  intercept_p := 0;

  if (x1 - bmaporgx) and (MAPBLOCKSIZE - 1) = 0 then
    x1 := x1 + FRACUNIT; // don't side exactly on a line

  if (y1 - bmaporgy) and (MAPBLOCKSIZE - 1) = 0 then
    y1 := y1 + FRACUNIT; // don't side exactly on a line

  trace.x := x1;
  trace.y := y1;
  trace.dx := x2 - x1;
  trace.dy := y2 - y1;

  x1 := x1 - bmaporgx;
  y1 := y1 - bmaporgy;
  xt1 := MapBlockInt(x1);
  yt1 := MapBlockInt(y1);

  x2 := x2 - bmaporgx;
  y2 := y2 - bmaporgy;
  xt2 := MapBlockInt(x2);
  yt2 := MapBlockInt(y2);

  if xt2 > xt1 then
  begin
    mapxstep := 1;
    partial := FRACUNIT - (MapToFrac(x1) and (FRACUNIT - 1));
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else if xt2 < xt1 then
  begin
    mapxstep := -1;
    partial := MapToFrac(x1) and (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  end
  else
  begin
    mapxstep := 0;
    partial := FRACUNIT;
    ystep := 256 * FRACUNIT;
  end;

  yintercept := MapToFrac(y1) + FixedMul(partial, ystep);

  if yt2 > yt1 then
  begin
    mapystep := 1;
    partial := FRACUNIT - (MapToFrac(y1) and (FRACUNIT - 1));
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else if yt2 < yt1 then
  begin
    mapystep := -1;
    partial := MapToFrac(y1) and (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  end
  else
  begin
    mapystep := 0;
    partial := FRACUNIT;
    xstep := 256 * FRACUNIT;
  end;

  xintercept := MapToFrac(x1) + FixedMul(partial, xstep);

  // Step through map blocks.
  // Count is present to prevent a round off error
  // from skipping the break.
  mapx := xt1;
  mapy := yt1;

  for count := 0 to 63 do
  begin
    if flags and PT_ADDLINES <> 0 then
    begin
      if not P_BlockLinesIterator(mapx, mapy, PIT_AddLineIntercepts) then
      begin
        result := false; // early out
        exit;
      end;
    end;

    if flags and PT_ADDTHINGS <> 0 then
    begin
      if not P_BlockThingsIterator(mapx, mapy, PIT_AddThingIntercepts) then
      begin
        result := false;// early out
        exit;
      end;
    end;

    if (mapx = xt2) and (mapy = yt2) then
      break;

    if FixedInt(yintercept) = mapy then
    begin
      yintercept := yintercept + ystep;
      mapx := mapx + mapxstep;
    end
    else if FixedInt(xintercept) = mapx then
    begin
      xintercept := xintercept + xstep;
      mapy := mapy + mapystep;
    end;
  end;

  // go through the sorted list
  result := P_TraverseIntercepts(trav, FRACUNIT);
 end;

//===========================================================================
//
// P_RoughBlockCheck
//
//===========================================================================

function P_RoughBlockCheck(mo: Pmobj_t; index: integer): Pmobj_t;
var
  mobj: Pmobj_t;
  master: Pmobj_t;
  angle: angle_t;
  link: Pblocklinkitem_t;
  i: integer;
begin
  link := @blocklinks[index];

  for i := 0 to link.size - 1 do
  begin
    mobj := link.links[i];
    if mo.player <> nil then  // Minotaur looking around player
    begin
      if (mobj.flags and MF_COUNTKILL <> 0) or
         ((mobj.player <> nil) and (mobj <> mo)) then
      begin
        if mobj.flags and MF_SHOOTABLE = 0 then
        begin
          continue;
        end;

        if mobj.flags2 and MF2_DORMANT <> 0 then
        begin
          continue;
        end;

        if (mobj._type = Ord(MT_MINOTAUR)) and
           (Pmobj_t(mobj.special1) = mo) then
        begin
          continue;
        end;

        if netgame and (deathmatch = 0) and (mobj.player <> nil) then
        begin
          continue;
        end;

        if P_CheckSight(mo, mobj) then
        begin
          result := mobj;
          exit;
        end;
        
      end;
    end

    else if mo._type = Ord(MT_MINOTAUR) then  // looking around minotaur
    begin
      master := Pmobj_t(mo.special1);
      if (mobj.flags and MF_COUNTKILL <> 0) or
         ((mobj.player <> nil) and (mobj <> master)) then
      begin
        if mobj.flags and MF_SHOOTABLE = 0 then
        begin
          continue;
        end;

        if mobj.flags2 and MF2_DORMANT <> 0 then
        begin
          continue;
        end;

        if (mobj._type = Ord(MT_MINOTAUR)) and
           (mobj.special1 = mo.special1) then
        begin
          continue;
        end;

        if netgame and (deathmatch = 0) and (mobj.player <> nil) then
        begin
          continue;
        end;

        if P_CheckSight(mo, mobj) then
        begin
          result := mobj;
          exit;
        end;
      end;
    end

    else if mo._type = Ord(MT_MSTAFF_FX2) then  // bloodscourge
    begin
      if (mobj.flags and MF_COUNTKILL <> 0) or
         ((mobj.player <> nil) and (mobj <> mo.target)) and
         (mobj.flags2 and MF2_DORMANT = 0) then
      begin
        if mobj.flags and MF_SHOOTABLE = 0 then
        begin
          continue;
        end;

        if netgame and (deathmatch = 0) and (mobj.player <> nil) then
        begin
          continue;
        end;

        if P_CheckSight(mo, mobj) then
        begin
          master := mo.target;
          angle := R_PointToAngle2(master.x, master.y, mobj.x, mobj.y) - master.angle;
          angle := angle shr 24;
          if (angle > 226) or (angle < 30) then
          begin
            result := mobj;
            exit;
          end;
        end;
      end;
    end

    else  // spirits
    begin
      if ((mobj.flags and MF_COUNTKILL <> 0) or
          ((mobj.player <> nil) and (mobj <> mo.target))) and
         (mobj.flags2 and MF2_DORMANT = 0) then
      begin
        if mobj.flags and MF_SHOOTABLE = 0 then
        begin
          continue;
        end;

        if netgame and (deathmatch = 0) and (mobj.player = nil) then
        begin
          continue;
        end;

        if mobj = mo.target then
        begin
          continue;
        end;

        if P_CheckSight(mo, mobj) then
        begin
          result := mobj;
          exit;
        end;
      end;
    end;
  end;

  result := nil;
end;

//===========================================================================
//
// P_RoughMonsterSearch
//
// Searches though the surrounding mapblocks for monsters/players
//    distance is in MAPBLOCKUNITS
//===========================================================================

function P_RoughMonsterSearch(mo: Pmobj_t; distance: integer): Pmobj_t;
var
  blockX: integer;
  blockY: integer;
  startX, startY: integer;
  blockIndex: integer;
  firstStop: integer;
  secondStop: integer;
  thirdStop: integer;
  finalStop: integer;
  count: integer;
begin
  startX := MapBlockInt(mo.x - bmaporgx);
  startY := MapBlockInt(mo.y - bmaporgy);

  if (startX >= 0) and (startX < bmapwidth) and (startY >= 0) and (startY < bmapheight) then
  begin
    result := P_RoughBlockCheck(mo, startY * bmapwidth + startX);
    if result <> nil then
    begin // found a target right away
      exit;
    end;
  end;

  for count := 1 to distance do
  begin
    blockX := startX - count;
    blockY := startY - count;

    if blockY < 0 then
      blockY := 0
    else if blockY >= bmapheight then
      blockY := bmapheight - 1;

    if blockX < 0 then
      blockX := 0
    else if blockX >= bmapwidth then
      blockX := bmapwidth - 1;

    blockIndex := blockY * bmapwidth + blockX;
    firstStop := startX + count;
    if firstStop < 0 then
      continue;

    if firstStop >= bmapwidth then
      firstStop := bmapwidth - 1;

    secondStop := startY + count;
    if secondStop < 0 then
      continue;

    if secondStop >= bmapheight then
      secondStop := bmapheight - 1;

    thirdStop := secondStop * bmapwidth + blockX;
    secondStop := secondStop * bmapwidth + firstStop;
    firstStop := firstStop + blockY * bmapwidth;
    finalStop := blockIndex;

    // Trace the first block section (along the top)
    while blockIndex <= firstStop do
    begin
      result := P_RoughBlockCheck(mo, blockIndex);
      if result <> nil then
      begin
        exit;
      end;
      inc(blockIndex);
    end;

    // Trace the second block section (right edge)
    dec(blockIndex);
    while blockIndex <= secondStop do
    begin
      result := P_RoughBlockCheck(mo, blockIndex);
      if result <> nil then
      begin
        exit;
      end;
      blockIndex := blockIndex + bmapwidth;
    end;

    // Trace the third block section (bottom edge)
    blockIndex := blockIndex - bmapwidth;
    while blockIndex >= thirdStop do
    begin
      result := P_RoughBlockCheck(mo, blockIndex);
      if result <> nil then
      begin
        exit;
      end;
      dec(blockIndex);
    end;

    // Trace the final block section (left edge)
    inc(blockindex);
    while blockIndex > finalStop do
    begin
      result := P_RoughBlockCheck(mo, blockIndex);
      if result <> nil then
      begin
        exit;
      end;
      blockIndex := blockIndex - bmapwidth;
    end;
  end;
  result := nil;
end;

end.

