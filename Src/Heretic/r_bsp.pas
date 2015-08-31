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
//  Refresh module, BSP traversal and handling.
//  BSP traversal, handling of LineSegs for rendering.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_bsp;

interface

uses
  r_defs;

// BSP?
procedure R_ClearClipSegs;
procedure R_ClearDrawSegs;


procedure R_RenderBSPNode(bspnum: integer);

type
  drawfunc_t = procedure(start: integer; stop: integer);

var
  ds_p: integer; // JVAL was: Pdrawseg_t
  max_ds_p: integer;

  curline: Pseg_t;
  frontsector: Psector_t;
  backsector: Psector_t;

  sidedef: Pside_t;
  linedef: Pline_t;
  drawsegs: array[0..MAXDRAWSEGS - 1] of Pdrawseg_t;


implementation

uses
  d_delphi,
  doomdata,
  m_fixed,
  tables,
  doomdef,
  m_bbox,
  p_setup,
  r_segs,
  r_main,
  r_plane,
  r_things,
  r_draw,
  r_sky,
// State.
  doomstat{$IFDEF OPENGL},
  doomtype,
  r_data,
  gl_render,      // JVAL OPENGL
  gl_clipper,     // JVAL OPENGL
  gl_defs,
  z_zone{$ENDIF}; // JVAL OPENGL

//
// R_ClearDrawSegs
//
procedure R_ClearDrawSegs;
begin
  ds_p := 0;
end;

//
// ClipWallSegment
// Clips the given range of columns
// and includes it in the new clip list.
//
type
  cliprange_t = record
    first: integer;
    last: integer;
  end;
  Pcliprange_t = ^cliprange_t;

// 1/11/98: Lee Killough
//
// This fixes many strange venetian blinds crashes, which occurred when a scan
// line had too many "posts" of alternating non-transparent and transparent
// regions. Using a doubly-linked list to represent the posts is one way to
// do it, but it has increased overhead and poor spatial locality, which hurts
// cache performance on modern machines. Since the maximum number of posts
// theoretically possible is a function of screen width, a static limit is
// okay in this case. It used to be 32, which was way too small.
//
// This limit was frequently mistaken for the visplane limit in some Doom
// editing FAQs, where visplanes were said to "double" if a pillar or other
// object split the view's space into two pieces horizontally. That did not
// have anything to do with visplanes, but it had everything to do with these
// clip posts.

const
  MAXSEGS = MAXWIDTH div 2 + 1;

var
// newend is one past the last valid seg
  newend: Pcliprange_t;
  solidsegs: array[0..MAXSEGS - 1] of cliprange_t;

// R_ClipSolidWallSegment
// Does handle solid walls,
//  e.g. single sided LineDefs (middle texture)
//  that entirely block the view.
//
{$IFNDEF OPENGL}
procedure R_ClipSolidWallSegment(first, last: integer);
var
  next: Pcliprange_t;
  start: Pcliprange_t;
  tmp: Pcliprange_t;

  procedure crunch;
  begin
    if next = start then
    // Post just extended past the bottom of one post.
      exit;
    while next <> newend do
    begin
      // Remove a post.
      inc(start);
      inc(next);
      start^ := next^;
    end;
    newend := start;
    inc(newend);
  end;

begin
  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := @solidsegs[0];
  while start.last < first - 1 do
    inc(start);

  if first < start.first then
  begin
    if last < start.first - 1 then
    begin
      // Post is entirely visible (above start),
      //  so insert a new clippost.
      R_StoreWallRange(first, last);
      next := newend;
      inc(newend);

      while next <> start do
      begin
        tmp := next;
        dec(tmp);
        next^ := tmp^;
        dec(next);
      end;
      next.first := first;
      next.last := last;
      exit;
    end;

    // There is a fragment above *start.
    R_StoreWallRange(first, start.first - 1);
    // Now adjust the clip size.
    start.first := first;
  end;

  // Bottom contained in start?
  if last <= start.last then
    exit;

  next := start;
  tmp := next;
  inc(tmp);
  while last >= tmp.first - 1 do
  begin
    // There is a fragment between two posts.
    R_StoreWallRange(next.last + 1, tmp.first - 1);
    inc(next);
    inc(tmp);

    if last <= next.last then
    begin
      // Bottom is contained in next.
      // Adjust the clip size.
      start.last := next.last;
      crunch;
      exit;
    end;
  end;

  // There is a fragment after *next.
  R_StoreWallRange(next.last + 1, last);
  // Adjust the clip size.
  start.last := last;

  // Remove start+1 to next from the clip list,
  // because start now covers their area.
  crunch;
end;

//
// R_ClipPassWallSegment
// Clips the given range of columns,
//  but does not includes it in the clip list.
// Does handle windows,
//  e.g. LineDefs with upper and lower texture.
//
procedure R_ClipPassWallSegment(first, last: integer);
var
  start: Pcliprange_t;
  tmp: Pcliprange_t;
begin
  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := @solidsegs[0];
  while start.last < first - 1 do
    inc(start);

  if first < start.first then
  begin
    if last < start.first - 1 then
    begin
      // Post is entirely visible (above start).
      R_StoreWallRange(first, last);
      exit;
    end;
    // There is a fragment above *start.
    R_StoreWallRange(first, start.first - 1);
  end;

  // Bottom contained in start?
  if last <= start.last then
    exit;

  tmp := start;
  inc(tmp);
  while last >= tmp.first - 1 do
  begin
    // There is a fragment between two posts.
    R_StoreWallRange(start.last + 1, tmp.first - 1);
    inc(start);
    inc(tmp);

    if last <= start.last then
      exit;
  end;

  // There is a fragment after *next.
  R_StoreWallRange(start.last + 1, last);
end;
{$ENDIF}

//
// R_ClearClipSegs
//
procedure R_ClearClipSegs;
begin
  newend := @solidsegs[0];
  newend.first := -$7fffffff;
  newend.last := -1;
  inc(newend);
  newend.first := viewwidth;
  newend.last := $7fffffff;
  inc(newend);
end;

{$IFDEF OPENGL}
function R_CheckClip(seg: Pseg_t): boolean;
var
  frontsector, backsector: Psector_t;
begin
  backsector := seg.backsector;
  frontsector := seg.frontsector;

  // check for closed sectors!
  if backsector.ceilingheight <= frontsector.floorheight then
  begin
    if seg.sidedef.toptexture = NO_TEXTURE then
      result := false
    else if (backsector.ceilingpic = skyflatnum) and (frontsector.ceilingpic = skyflatnum) then
      result := false
    else
      result := true;
    exit;
  end;

  if frontsector.ceilingheight <= backsector.floorheight then
  begin
    if seg.sidedef.bottomtexture = NO_TEXTURE then
      result := false
    // properly render skies (consider door "open" if both floors are sky):
    else if (backsector.ceilingpic = skyflatnum) and (frontsector.ceilingpic = skyflatnum) then
      result := false
    else
      result := true;
    exit;
  end;

  if backsector.ceilingheight <= backsector.floorheight then
  begin
    // preserve a kind of transparent door/lift special effect:
    if backsector.ceilingheight < frontsector.ceilingheight then
    begin
      if seg.sidedef.toptexture = NO_TEXTURE then
      begin
        result := false;
        exit;
      end;
    end;
    if backsector.floorheight > frontsector.floorheight then
    begin
      if seg.sidedef.bottomtexture = NO_TEXTURE then
      begin
        result := false;
        exit;
      end;
    end;
    if (backsector.ceilingpic = skyflatnum) and (frontsector.ceilingpic = skyflatnum) then
    begin
      result := false;
      exit;
    end;

    if (backsector.floorpic = skyflatnum) and (frontsector.floorpic = skyflatnum) then
    begin
      result := false;
      exit;
    end;

    result := true;
    exit;
  end;
  result := false;
end;
{$ENDIF}

//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//
procedure R_AddLine(line: Pseg_t);
var
  x1: integer;
  x2: integer;
  tspan: angle_t;
  clipangle2: angle_t;
  angle1: angle_t;
  angle2: angle_t;
  span: angle_t;
begin
  curline := line;

  // OPTIMIZE: quickly reject orthogonal back sides.
  angle1 := R_PointToAngle(line.v1.x, line.v1.y);
  angle2 := R_PointToAngle(line.v2.x, line.v2.y);

  // Clip to view edges.
  // OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
  span := angle1 - angle2;

  // Back side? I.e. backface culling?
  if span >= ANG180 then
    exit;

{$IFDEF OPENGL}
  if not gld_clipper_SafeCheckRange(angle2, angle1) then
    exit;

  if line.backsector = nil then
    gld_clipper_SafeAddClipRange(angle2, angle1)
  else
  begin
    if line.frontsector = line.backsector then
      if texturetranslation[line.sidedef.midtexture] = NO_TEXTURE then
        exit; //e6y: nothing to do here!
    if R_CheckClip(line) then
      gld_clipper_SafeAddClipRange(angle2, angle1);
  end;

  if absviewpitch < 10 then
  begin
{$ENDIF}
    // Global angle needed by segcalc.
    rw_angle1 := angle1;
    angle1 := angle1 - viewangle;
    angle2 := angle2 - viewangle;

    tspan := angle1 + clipangle;
    clipangle2 := 2 * clipangle;
    if tspan > clipangle2 then
    begin
      tspan := tspan - clipangle2;

      // Totally off the left edge?
      if tspan >= span then
        exit;

      angle1 := clipangle;
    end;

    tspan := clipangle - angle2;
    if tspan > clipangle2 then
    begin
      tspan := tspan - clipangle2;

      // Totally off the left edge?
      if tspan >= span then
        exit;

      angle2 := -clipangle;
    end;

    // The seg is in the view range,
    // but not necessarily visible.
    {$IFDEF FPC}
    angle1 := _SHRW(angle1 + ANG90, ANGLETOFINESHIFT);
    angle2 := _SHRW(angle2 + ANG90, ANGLETOFINESHIFT);
    {$ELSE}
    angle1 := (angle1 + ANG90) shr ANGLETOFINESHIFT;
    angle2 := (angle2 + ANG90) shr ANGLETOFINESHIFT;
    {$ENDIF}
    x1 := viewangletox[angle1];
    x2 := viewangletox[angle2];

    // Does not cross a pixel?
    if x1 >= x2 then
      exit;

{$IFDEF OPENGL}
  end;

  gld_AddWall(line); // JVAL OPENGL
{$ELSE}
  backsector := line.backsector;

  // Single sided line?
  if backsector = nil then
  begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  end;

  // Closed door.
  if (backsector.ceilingheight <= frontsector.floorheight) or
     (backsector.floorheight >= frontsector.ceilingheight) then
  begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  end;

  // Window.
  if (backsector.ceilingheight <> frontsector.ceilingheight) or
     (backsector.floorheight <> frontsector.floorheight) then
  begin
    R_ClipPassWallSegment(x1, x2 - 1);
    exit;
  end;

  // Reject empty lines used for triggers
  //  and special events.
  // Identical floor and ceiling on both sides,
  // identical light levels on both sides,
  // and no middle texture.
  if (backsector.ceilingpic = frontsector.ceilingpic) and
     (backsector.floorpic = frontsector.floorpic) and
     (backsector.lightlevel = frontsector.lightlevel) and
     (curline.sidedef.midtexture = 0) then
    exit;

  R_ClipPassWallSegment(x1, x2 - 1);
{$ENDIF}
end;

//
// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.
//
const
  checkcoord: array[0..11, 0..3] of integer = (
    (3, 0, 2, 1),
    (3, 0, 2, 0),
    (3, 1, 2, 0),
    (0, 0, 0, 0),
    (2, 0, 2, 1),
    (0, 0, 0, 0),
    (3, 1, 3, 0),
    (0, 0, 0, 0),
    (2, 0, 3, 1),
    (2, 1, 3, 1),
    (2, 1, 3, 0),
    (0, 0, 0, 0)
  );

function R_CheckBBox(bspcoordA: Pfixed_tArray; const side: integer): boolean;
var
  bspcoord: Pfixed_tArray;
  boxx: integer;
  boxy: integer;
  boxpos: integer;
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
  angle1: angle_t;
  angle2: angle_t;
{$IFNDEF OPENGL}
  span: angle_t;
  tspan: angle_t;
  clipangle2: angle_t;
  start: Pcliprange_t;
  sx1: integer;
  sx2: integer;
{$ENDIF}
begin
  if side = 0 then
    bspcoord := bspcoordA
  else
    bspcoord := @bspcoordA[4];

  // Find the corners of the box
  // that define the edges from current viewpoint.
  if viewx <= bspcoord[BOXLEFT] then
    boxx := 0
  else if viewx < bspcoord[BOXRIGHT] then
    boxx := 1
  else
    boxx := 2;

  if viewy >= bspcoord[BOXTOP] then
    boxy := 0
  else if viewy > bspcoord[BOXBOTTOM] then
    boxy := 1
  else
    boxy := 2;

  boxpos := boxy * 4 + boxx;
  if boxpos = 5 then
  begin
    result := true;
    exit;
  end;

  x1 := bspcoord[checkcoord[boxpos][0]];
  y1 := bspcoord[checkcoord[boxpos][1]];
  x2 := bspcoord[checkcoord[boxpos][2]];
  y2 := bspcoord[checkcoord[boxpos][3]];

{$IFDEF OPENGL}
  angle1 := R_PointToAngle(x1, y1);
  angle2 := R_PointToAngle(x2, y2);
  result := gld_clipper_SafeCheckRange(angle2, angle1);
  exit;
{$ELSE}
  // check clip list for an open space
  angle1 := R_PointToAngle(x1, y1) - viewangle;
  angle2 := R_PointToAngle(x2, y2) - viewangle;

  span := angle1 - angle2;

  // Sitting on a line?
  if span >= ANG180 then
  begin
    result := true;
    exit;
  end;

  tspan := angle1 + clipangle;
  clipangle2 := 2 * clipangle;
  if tspan > clipangle2 then
  begin
    tspan := tspan - clipangle2;

    // Totally off the left edge?
    if tspan >= span then
    begin
      result := false;
      exit;
    end;

    angle1 := clipangle;
  end;

  tspan := clipangle - angle2;
  if tspan > clipangle2 then
  begin
    tspan := tspan - clipangle2;

    // Totally off the left edge?
    if tspan >= span then
    begin
      result := false;
      exit;
    end;

    angle2 := -clipangle;
  end;


  // Find the first clippost
  //  that touches the source post
  //  (adjacent pixels are touching).
  {$IFDEF FPC}
  angle1 := _SHRW(angle1 + ANG90, ANGLETOFINESHIFT);
  angle2 := _SHRW(angle2 + ANG90, ANGLETOFINESHIFT);
  {$ELSE}
  angle1 := (angle1 + ANG90) shr ANGLETOFINESHIFT;
  angle2 := (angle2 + ANG90) shr ANGLETOFINESHIFT;
  {$ENDIF}

  sx1 := viewangletox[angle1];
  sx2 := viewangletox[angle2];

  // Does not cross a pixel.
  if sx1 = sx2 then
  begin
    result := false;
    exit;
  end;

  dec(sx2);

  start := @solidsegs[0];
  while start.last < sx2 do
    inc(start);

  if (sx1 >= start.first) and
     (sx2 <= start.last) then
    // The clippost contains the new span.
    result := false
  else
    result := true;
{$ENDIF}    
end;

//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//
procedure R_Subsector(const num: integer);
var
  count: integer;
  line: Pseg_t;
  i_line: integer;
  sub: Psubsector_t;
{$IFDEF OPENGL}
  i: integer;
  dummyfloorplane: visplane_t;
  dummyceilingplane: visplane_t;
  tmpline: Pline_t;
{$ENDIF}
begin
  inc(sscount);
  sub := @subsectors[num];
  frontsector := sub.sector;
  count := sub.numlines;
  i_line := sub.firstline;
  line := @segs[i_line];

  if frontsector.floorheight < viewz then
  begin
    floorplane := R_FindPlane(frontsector.floorheight,
                              frontsector.floorpic,
                              frontsector.lightlevel,
                              frontsector.renderflags and not SRF_RIPPLE_CEILING);
  end
  else
    floorplane := nil;

  if (frontsector.ceilingheight > viewz) or
     (frontsector.ceilingpic = skyflatnum) then
  begin
    ceilingplane := R_FindPlane(frontsector.ceilingheight,
                                frontsector.ceilingpic,
                                frontsector.lightlevel,
                                frontsector.renderflags and not SRF_RIPPLE_FLOOR);
  end
  else
    ceilingplane := nil;

{$IFDEF OPENGL}
  if (frontsector = sub.sector) and (frontsector.renderflags = 0) then
  begin
    // if the sector has bottomtextures, then the floorheight will be set to the
    // highest surounding floorheight
    if frontsector.no_bottomtextures or (floorplane = nil) then
    begin
      i := frontsector.linecount;

      dummyfloorplane.renderflags := 0;
      dummyfloorplane.height := MININT;
      while i > 0 do
      begin
        dec(i);
        tmpline := frontsector.lines[i];
        if tmpline.backsector <> nil then
          if tmpline.backsector <> frontsector then
            if tmpline.backsector.floorheight > dummyfloorplane.height then
            begin
              dummyfloorplane.height := tmpline.backsector.floorheight;
              dummyfloorplane.lightlevel := tmpline.backsector.lightlevel;
            end;
        if tmpline.frontsector <> nil then
          if tmpline.frontsector <> frontsector then
            if tmpline.frontsector.floorheight > dummyfloorplane.height then
            begin
              dummyfloorplane.height := tmpline.frontsector.floorheight;
              dummyfloorplane.lightlevel := tmpline.frontsector.lightlevel;
            end;
      end;
      if dummyfloorplane.height <> MININT then
        floorplane := @dummyfloorplane;
    end;
    // the same for ceilings. they will be set to the lowest ceilingheight
    if frontsector.no_toptextures or (ceilingplane = nil) then
    begin
      i := frontsector.linecount;

      dummyceilingplane.renderflags := 0;
      dummyceilingplane.height := MAXINT;
      while i > 0 do
      begin
        dec(i);
        tmpline := frontsector.lines[i];
        if tmpline.backsector <> nil then
          if tmpline.backsector <> frontsector then
            if tmpline.backsector.ceilingheight < dummyceilingplane.height then
            begin
              dummyceilingplane.height := tmpline.backsector.ceilingheight;
              dummyceilingplane.lightlevel := tmpline.backsector.lightlevel;
            end;
        if tmpline.frontsector <> nil then
          if tmpline.frontsector <> frontsector then
            if tmpline.frontsector.ceilingheight < dummyceilingplane.height then
            begin
              dummyceilingplane.height := tmpline.frontsector.ceilingheight;
              dummyceilingplane.lightlevel := tmpline.frontsector.lightlevel;
            end;
      end;
      if dummyceilingplane.height <> MAXINT then
        ceilingplane := @dummyceilingplane;
    end;
  end;
{$ENDIF}

  R_AddSprites(frontsector);

{$IFDEF OPENGL}
  if gl_add_all_lines then
  begin
    while count <> 0 do
    begin
      // JVAL 27/9/2009
      // If we have a one-sided linedef then we draw it regardless the clipping
      if not line.miniseg then
      begin
        if line.linedef.flags and ML_TWOSIDED = 0 then
          gld_AddWall(line)
        else
          R_AddLine(line);
      end;
      inc(line);
      dec(count);
    end;
  end
  else
  begin
    while count <> 0 do
    begin
      if not line.miniseg then
        R_AddLine(line);
      inc(line);
      dec(count);
    end;
  end;
  gld_AddPlane(num, floorplane, ceilingplane); // JVAL OPENGL
{$ELSE}
  while count <> 0 do
  begin
    R_AddLine(line);
    inc(line);
    dec(count);
  end;
{$ENDIF}  
end;

//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.
procedure R_RenderBSPNode(bspnum: integer);
var
  bsp: Pnode_t;
  side: integer;
begin
  while bspnum and NF_SUBSECTOR = 0 do  // Found a subsector?
  begin
    bsp := @nodes[bspnum];

    // Decide which side the view point is on.
    if R_PointOnSide(viewx, viewy, bsp) then
      side := 1
    else
      side := 0;
    // Recursively divide front space.
    R_RenderBSPNode(bsp.children[side]);

    // Possibly divide back space.

    side := side xor 1;
    if not R_CheckBBox(Pfixed_tArray(@(bsp.bbox)), side) then
      exit;

    bspnum := bsp.children[side];
  end;
  if bspnum = -1 then
    R_Subsector(0)
  else
    R_Subsector(bspnum and not NF_SUBSECTOR);
end;


end.

