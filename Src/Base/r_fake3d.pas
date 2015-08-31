//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Fake 3d perspective in software rendering mode
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_fake3d;

// JVAL: Fake 3D Emulation

interface

uses
  d_delphi,
  d_player;

var
  usefake3d: boolean;

procedure R_Set3DLookup(p: Pplayer_t);

procedure R_Wait3DLookup;

procedure R_Execute3DTransform;

procedure R_ShutDownFake3D;

procedure R_InitFake3D;

function R_Fake3DAspectCorrection(const p: Pplayer_t): Double;

procedure R_Fake3DAdjustPlanes(const p: Pplayer_t);

var
  fake3dspanpresent: PBooleanArray = nil;

var
  fake3dtopclip: smallint = 0;
  fake3dbottomclip: smallint = 0;

implementation

uses
  doomdef,
  tables,
  m_fixed,
  i_system,
  i_threads,
  r_draw,
  r_hires,
  r_main,
  r_plane,
  v_data,
  z_zone;

type
  f3dinfo_t = record
    ylookup: PIntegerArray;  // Row translation
    yPresent: PBooleanArray; // Must draw y spans?
    left: PIntegerArray;     // Left limit
    right: PIntegerArray;    // Right limit
    fracstep: PIntegerArray; // Right limit
    xclip: PSmallintArray;   // Precomputed floorclip/ceilingclip
    aspect: double;          // Aspect correction
    lefttop, righttop: integer;
    leftbottom, rightbottom: Integer;
    topclip, bottomclip: integer;
    computed: boolean;
  end;
  Pf3dinfo_t = ^f3dinfo_t;
  f3dinfobuffer_t = array[MINLOOKDIR..MAXLOOKDIR] of Pf3dinfo_t;

var
  f3dinfobuffer: f3dinfobuffer_t;

const
  LOOKDIR_TO_ANGLE = 0.5;

procedure R_ComputeFake3DTables(const l: integer);
var
  f3d: Pf3dinfo_t;
  ang: double;
  i, j: integer;
  buffer: array[0..MAXHEIGHT - 1] of double;
  buffer2: array[0..MAXHEIGHT - 1] of double;
  c, c1, c2: Double;
  c1frac: Double;
  invc2: Double;
  r: double;
  leftstep: double;
  rightstep: double;
  ymin, ymax: integer;
  df: integer;
  viewheightdiff: integer;
  viewheightrest: integer;
  frac: fixed_t;
  left, right: integer;
  err: integer;
begin
  if l = 0 then
    exit;

  if f3dinfobuffer[l] = nil then
  begin
    f3dinfobuffer[l] := Z_Malloc(SizeOf(f3dinfo_t), PU_STATIC, nil);
    f3dinfobuffer[l].ylookup := Z_Malloc(SCREENHEIGHT * SizeOf(integer), PU_STATIC, nil);
    f3dinfobuffer[l].yPresent := Z_Malloc(SCREENHEIGHT * SizeOf(boolean), PU_STATIC, nil);
    f3dinfobuffer[l].left := Z_Malloc(SCREENHEIGHT * SizeOf(integer), PU_STATIC, nil);
    f3dinfobuffer[l].right := Z_Malloc(SCREENHEIGHT * SizeOf(integer), PU_STATIC, nil);
    f3dinfobuffer[l].fracstep := Z_Malloc(SCREENHEIGHT * SizeOf(integer), PU_STATIC, nil);
    f3dinfobuffer[l].xclip := Z_Malloc(SCREENWIDTH * SizeOf(smallint), PU_STATIC, nil);
  end;

  f3d := f3dinfobuffer[l];

  if l < 0 then
    ang := l * LOOKDIR_TO_ANGLE * D_PI / 270
  else
    ang := l * LOOKDIR_TO_ANGLE * D_PI / 180;

  c := Cos(ang);
  c1 := 2 * (c - 1);
  c2 := 2 - c;
  invc2 := 1 / c2;
  c1frac := c1 / viewheight;
  buffer[0] := 0;
  for i := 1 to viewheight - 1 do
    buffer[i] := buffer[i - 1] + i * c1frac;

  for i := 0 to viewheight - 1 do
    buffer2[i] := buffer[i] + i * c2;

  r := Sqrt(3);
  if l >= 0 then
    for i := 0 to viewheight - 1 do
      f3d.ylookup[i] := Round(invc2 * (i + r * (buffer2[i] - i) ));

  if l < 0 then
    for i := 0 to viewheight - 1 do
      f3d.ylookup[i] := Round(invc2 * (i - r * (buffer2[i] - i) ));

  if l < 0 then
  begin
    df := viewheight - f3d.ylookup[viewheight - 1] + 1;
    for i := 0 to viewheight - 1 do
      f3d.ylookup[i] := f3d.ylookup[i] + df;
  end;

  ymin := viewheight;
  ymax := -2;
  for i := 0 to viewheight - 1 do
  begin
    if f3d.ylookup[i] < 0 then
      f3d.ylookup[i] := 0
    else if f3d.ylookup[i] >= viewheight then
      f3d.ylookup[i] := viewheight - 1;
    if f3d.ylookup[i] < ymin then
      ymin := f3d.ylookup[i];
    if f3d.ylookup[i] > ymax then
      ymax := f3d.ylookup[i];
  end;
  ymax := ymax + 1;
  if ymax >= viewheight then
    ymax := viewheight - 1;
  viewheightdiff := f3d.ylookup[viewheight - 1] - f3d.ylookup[0] + 1;
  if viewheightdiff >= viewheight then
    viewheightdiff := viewheight - 1;
  viewheightrest := viewheight - viewheightdiff;

  // JVAL
  // Create yPresent table, determine if we must draw a span at y position
  for i := 0 to viewheight - 1 do
    f3d.yPresent[i] := false;
  // Only spans present at ylookup needed
  for i := 0 to viewheight - 1 do
    f3d.yPresent[f3d.ylookup[i]] := true;

  f3d.aspect := c2;

  err := viewwidth div 32 + 1;
  if l >= 0 then
  begin
    f3d.lefttop := 0;
    f3d.righttop := viewwidth - 1;
    r := viewwidth / f3d.aspect;
    f3d.leftbottom := Round(viewwidth - r);
    f3d.rightbottom := viewwidth - f3d.leftbottom - 1;
    leftstep := f3d.leftbottom - f3d.lefttop;
    rightstep := f3d.rightbottom - f3d.righttop;
    r := FRACUNIT / viewwidth;
    for i := 0 to viewheightdiff do
    begin
      f3d.left[i] := Round(f3d.lefttop + leftstep * i / viewheightdiff - l / MAXLOOKDIR * Sin(i / viewheightdiff) * viewheight / 10);
      if f3d.left[i] < 0 then
        f3d.left[i] := 0;
      f3d.right[i] := Round(f3d.righttop + rightstep * i / viewheightdiff + l / MAXLOOKDIR * Sin(i / viewheightdiff) * viewheight / 10);
      if f3d.right[i] >= viewwidth then
        f3d.right[i] := viewwidth - 1;
      f3d.fracstep[i] := Round((f3d.right[i] - f3d.left[i]) * r);
    end;
    left := f3d.left[viewheightdiff - 1];
    right := f3d.right[viewheightdiff - 1];
    frac := f3d.fracstep[viewheightdiff - 1];
    for i := viewheightdiff to viewheight - 1 do
    begin
      f3d.left[i] := left;
      f3d.right[i] := right;
      f3d.fracstep[i] := frac;
    end;
    // JVAL
    // Adjust floorclip
    for i := 0 to viewwidth - 1 do
      f3d.xclip[i] := ymax;

    for i := ymin + 1 to viewheight - 1 do
      f3d.xclip[f3d.left[i]] := i + err;
    for i := ymin + 1 to viewheight - 1 do
      f3d.xclip[f3d.right[i]] := i + err;
    for i := 0 to viewwidth - 1 do
      if f3d.xclip[i] > ymax then
        f3d.xclip[i] := ymax
      else if f3d.xclip[i] < -1 then
        f3d.xclip[i] := -1;
    f3d.topclip := -1;
    f3d.bottomclip := ymax + 1;
    if f3d.bottomclip > viewheight then
      f3d.bottomclip := viewheight;
  end
  else
  begin
    r := viewwidth / f3d.aspect;
    f3d.lefttop := Round(viewwidth - r);
    f3d.righttop := viewwidth - f3d.lefttop - 1;
    f3d.leftbottom := 0;
    f3d.rightbottom := viewwidth - 1;
    leftstep := f3d.leftbottom - f3d.lefttop;
    rightstep := f3d.rightbottom - f3d.righttop;
    r := FRACUNIT / viewwidth;
    for i := 0 to viewheightdiff - 1 do
    begin
      j := i + viewheightrest;
      f3d.left[j] := Round(f3d.lefttop + leftstep * i / viewheightdiff);
      if f3d.left[j] < 0 then
        f3d.left[j] := 0;
      f3d.right[j] := Round(f3d.righttop + rightstep * i / viewheightdiff);
      if f3d.right[j] >= viewwidth then
        f3d.right[j] := viewwidth - 1;
      f3d.fracstep[j] := Round((f3d.right[j] - f3d.left[j]) * r);
    end;
    left := f3d.left[viewheightrest];
    right := f3d.right[viewheightrest];
    frac := f3d.fracstep[viewheightrest];
    for i := 0 to viewheightrest - 1 do
    begin
      f3d.left[i] := left;
      f3d.right[i] := right;
      f3d.fracstep[i] := frac;
    end;
    // JVAL
    // Adjust ceilingclip
    for i := 0 to viewwidth - 1 do
      f3d.xclip[i] := ymin - 1; // - 1;
    for i := ymin + 1 to viewheight - 1 do
      f3d.xclip[f3d.left[i]] := i - err;
    for i := ymin + 1 to viewheight - 1 do
      f3d.xclip[f3d.right[i]] := i - err;
    for i := 0 to viewwidth - 1 do
      if f3d.xclip[i] > viewheight then
        f3d.xclip[i] := viewheight
      else if f3d.xclip[i] <= ymin then
        f3d.xclip[i] := ymin - 1;

    f3d.topclip := ymin - 2;
    if f3d.topclip < -1 then
      f3d.topclip := -1;
    f3d.bottomclip := viewheight;
  end;

  f3d.computed := true;
end;

procedure R_Fake3DAdjustPlanes(const p: Pplayer_t);
var
  i: integer;
  f3d: Pf3dinfo_t;
  l: integer;
begin
  if not usefake3d or not zaxisshift then
  begin
    fake3dtopclip := -1;
    fake3dbottomclip := viewheight;
    Exit;
  end;

  l := p.lookdir;
  if l = 0 then
  begin
    fake3dtopclip := -1;
    fake3dbottomclip := viewheight;
    Exit;
  end;

  if f3dinfobuffer[l] = nil then
     R_ComputeFake3DTables(l)
  else if not f3dinfobuffer[l].computed then
     R_ComputeFake3DTables(l);

  f3d := f3dinfobuffer[l];
  if l > 0 then
  begin
    for i := 0 to viewwidth - 1 do
      floorclip[i] := f3d.xclip[i];
  end
  else
  begin
    for i := 0 to viewwidth - 1 do
      ceilingclip[i] := f3d.xclip[i];
  end;
  fake3dtopclip := f3d.topclip;
  fake3dbottomclip := f3d.bottomclip;
end;

var
  fake3dlookdir: integer;

var
  oldfake3dlookdir: integer = 0;
  oldviewwidth: integer = -1;
  oldviewheight: integer = -1;

//
// JVAL
// Setup lookup table
//
var
  setup3dworker: TDThread;

function do_Set3DLookup(p: Pplayer_t): Integer; stdcall;
begin
  R_ComputeFake3DTables(fake3dlookdir);

  result := 0;
end;

procedure R_Set3DLookup(p: Pplayer_t);
var
  i: integer;
begin
  if (oldfake3dlookdir = p.lookdir) and
     (oldviewwidth = viewwidth) and
     (oldviewheight = viewheight) then
     exit;

  if (oldviewwidth <> viewwidth) or
     (oldviewheight <> viewheight) then
    for i := MINLOOKDIR to MAXLOOKDIR do
      if f3dinfobuffer[i] <> nil then
        f3dinfobuffer[i].computed := false;

  oldfake3dlookdir := p.lookdir;
  oldviewwidth := viewwidth;
  oldviewheight := viewheight;
  fake3dlookdir := oldfake3dlookdir;

  if fake3dlookdir <> 0 then
    fake3dspanpresent := f3dinfobuffer[fake3dlookdir].yPresent
  else
    fake3dspanpresent := nil;

  if f3dinfobuffer[fake3dlookdir] <> nil then
    if f3dinfobuffer[fake3dlookdir].computed then
      exit;

  if usemultithread then
    setup3dworker.Activate(p)
  else
    do_Set3DLookup(p);
end;

procedure R_Wait3DLookup;
begin
  setup3dworker.Wait;
end;

//
// JVAL
// Execute 3D Transform in 8 bit mode
//
procedure R_Execute3DTransform8(const start, stop: integer; buffer: PByteArray);
var
  f3d: Pf3dinfo_t;
  idx: Integer;
  dest: PByte;
  limit: PByte;
  limit2: PByte;
  src: PByte;
  frac, fracstep: fixed_t;
  range: integer;
  fb: fourbytes;
  top: integer;
  bottom: integer;
  top2: integer;
  i: integer;
  f3d_ylookup: PIntegerArray;
  y: integer;
begin
  f3d := f3dinfobuffer[fake3dlookdir];
  range := stop - start + 1;

  f3d_ylookup := f3d.ylookup;
  i := 0;
  while f3d_ylookup[i] > i do
  begin
    {$I R_Fake3DLoop8.inc}
    if i = viewheight - 1 then
      exit;
    inc(i);
  end;
  top := i;

  i := viewheight - 1;
  while f3d_ylookup[i] < i do
  begin
    {$I R_Fake3DLoop8.inc}
    if i = top then
      exit;
    dec(i);
  end;
  bottom := i;

  if top <= bottom then
  begin

    top2 := top;
    while f3d_ylookup[top2] <= top2 do
    begin
      if top2 = bottom then
        break;
      inc(top2);
    end;

    for i := top2 downto top do
    begin
      {$I R_Fake3DLoop8.inc}
    end;

    for i := top2 + 1 to bottom do
    begin
      {$I R_Fake3DLoop8.inc}
    end;

  end;
end;

//
// JVAL
// Execute 3D Transform in 32 bit mode
//
procedure R_Execute3DTransform32(const start, stop: integer; buffer: PLongWordArray);
var
  f3d: Pf3dinfo_t;
  idx: Integer;
  dest: PLongWord;
  limit: PLongWord;
  limit2: PLongWord;
  src: PLongWord;
  frac, fracstep: fixed_t;
  range: integer;
  bsize: Integer;
  top: integer;
  bottom: integer;
  top2: integer;
  i: integer;
  f3d_ylookup: PIntegerArray;
  y: integer;
begin
  f3d := f3dinfobuffer[fake3dlookdir];
  range := stop - start + 1;
  bsize := range * SizeOf(LongWord);

  f3d_ylookup := f3d.ylookup;
  i := 0;
  while f3d_ylookup[i] > i do
  begin
    {$I R_Fake3DLoop32.inc}
    if i = viewheight - 1 then
      exit;
    inc(i);
  end;
  top := i;

  i := viewheight - 1;
  while f3d_ylookup[i] < i do
  begin
    {$I R_Fake3DLoop32.inc}
    if i = top then
      exit;
    dec(i);
  end;
  bottom := i;

  if top <= bottom then
  begin

    top2 := top;
    while f3d_ylookup[top2] <= top2 do
    begin
      if top2 = bottom then
        break;
      inc(top2);
    end;

    for i := top2 downto top do
    begin
      {$I R_Fake3DLoop32.inc}
    end;

    for i := top2 + 1 to bottom do
    begin
      {$I R_Fake3DLoop32.inc}
    end;
  end;
end;

type
  exec3dtransparms_t = record
    start, stop: integer;
    buffer: pointer;
  end;
  Pexec3dtransparms_t = ^exec3dtransparms_t;

//
// JVAL
// Execute 3D Transform in 8 bit mode thread function
//
function R_Thr_Execute3DTransform8(p: pointer): integer; stdcall;
begin
  R_Execute3DTransform8(Pexec3dtransparms_t(p).start, Pexec3dtransparms_t(p).stop, PByteArray(Pexec3dtransparms_t(p).buffer));
  result := 0;
end;

//
// JVAL
// Execute 3D Transform in 32 bit mode thread function
//
function R_Thr_Execute3DTransform32(p: pointer): integer; stdcall;
begin
  R_Execute3DTransform32(Pexec3dtransparms_t(p).start, Pexec3dtransparms_t(p).stop, PLongWordArray(Pexec3dtransparms_t(p).buffer));
  result := 0;
end;


var
  threadworker8, threadworker32: TDThread;

//
// JVAL
//  R_Execute3DTransform
//  Transforms current view 
//
var
  buffer1: array[0..MAXWIDTH - 1] of LongWord;
  buffer2: array[0..MAXWIDTH - 1] of LongWord;

procedure R_Execute3DTransform;
var
//  h1: integer;
  parms1: exec3dtransparms_t;
begin
  // If we don't use fake 3d return
  if not usefake3d then
    exit;

  // If we don't use z-axis shift return again
  if not zaxisshift then
    exit;

  // If we look straigh ahead return
  if fake3dlookdir = 0 then
    exit;

  // If we use multithreading
  if usemultithread then
  begin
    parms1.start := 0;
    parms1.stop := (viewwidth div 2) and (not 3);
    parms1.buffer := @buffer1;

    if videomode = vm32bit then
    begin
    // JVAL
    // Activate the thread to process the half screen (left part of screen)
    // The other half is processed by application thread (right part of screen)
      threadworker32.Activate(@parms1);
      R_Execute3DTransform32(parms1.stop + 1, viewwidth - 1, @buffer2);
      threadworker32.Wait;
    end
    else
    begin
    // JVAL
    // As above
      threadworker8.Activate(@parms1);
      R_Execute3DTransform8(parms1.stop + 1, viewwidth - 1, PByteArray(@buffer2));
      threadworker8.Wait;
    end;

  end
  else
  begin
  // JVAL: The simple stuff
    if videomode = vm32bit then
      R_Execute3DTransform32(0, viewwidth - 1, @buffer1)
    else
      R_Execute3DTransform8(0, viewwidth - 1, PByteArray(@buffer1));
  end;

end;

procedure R_InitFake3D;
var
  i: integer;
begin
  for i := MINLOOKDIR to MAXLOOKDIR do
    f3dinfobuffer[i] := nil;
  threadworker8 := TDThread.Create(@R_Thr_Execute3DTransform8);
  threadworker32 := TDThread.Create(@R_Thr_Execute3DTransform32);
  setup3dworker := TDThread.Create(@do_Set3DLookup);
end;

procedure R_ShutDownFake3D;
begin
  threadworker8.Free;
  threadworker32.Free;
  setup3dworker.Free;
end;

function R_Fake3DAspectCorrection(const p: Pplayer_t): Double;
begin
  if p = nil then
  begin
    result := 1.0;
    exit;
  end;

  if zaxisshift and usefake3d and (p.lookdir <> 0) then
  begin
    if f3dinfobuffer[p.lookdir] = nil then
       R_ComputeFake3DTables(p.lookdir)
    else if not f3dinfobuffer[p.lookdir].computed then
       R_ComputeFake3DTables(p.lookdir);
    result := f3dinfobuffer[p.lookdir].aspect;
  end
  else
    result := 1.0;
end;

end.

