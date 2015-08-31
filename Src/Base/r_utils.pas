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
//  Rendering utility functions
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_utils;

interface

uses
  m_fixed;
  
function R_PointToScreenBuffer(const wx, wy, wz: fixed_t; var x, y: Integer): boolean;

procedure R_ColumnToScreenBuffer(const wx, wy, wz1, wz2: fixed_t; var x, y1, y2: Integer);

function R_PointToScreen(const wx, wy, wz: fixed_t; var x, y: Integer): boolean;

implementation

uses
  r_main,
  r_draw;

function R_PointToScreenBuffer(const wx, wy, wz: fixed_t; var x, y: Integer): boolean;
var
  tr_x: fixed_t;
  tr_y: fixed_t;
  gxt: fixed_t;
  gyt: fixed_t;
  tx: fixed_t;
  tz: fixed_t;
  xscale: fixed_t;
begin
  result := true;
  tr_x := wx - viewx;
  tr_y := wy - viewy;
  gxt := FixedMul(tr_x, viewcos);
  gyt := -FixedMul(tr_y, viewsin);
  tz := gxt - gyt;
  if tz < 0 then
  begin
    result := false;
    exit;
  end;

  xscale := FixedDiv(projection, tz);
  if xscale <= 0 then
  begin
    result := false;
    exit;
  end;

  gxt := -FixedMul(tr_x, viewsin);
  gyt := FixedMul(tr_y, viewcos);
  tx := -(gyt + gxt);

  x := centerx + FixedInt(FixedMul(tx, xscale));
  if x >= viewwidth then
  begin
    result := false;
    exit;
  end
  else if x < 0 then
  begin
    result := false;
    exit;
  end;

  xscale := FixedDiv(projectiony, tz);
  y := centery - FixedInt(FixedMul(wz - viewz, xscale));
  if y >= viewheight then
  begin
    result := false;
    exit;
  end
  else if y < 0 then
  begin
    result := false;
    exit;
  end;
end;

procedure R_ColumnToScreenBuffer(const wx, wy, wz1, wz2: fixed_t; var x, y1, y2: Integer);
var
  tr_x: fixed_t;
  tr_y: fixed_t;
  tx: fixed_t;
  tz: fixed_t;
  xscale: fixed_t;
begin
  tr_x := wx - viewx;
  tr_y := wy - viewy;
  tz := FixedMul(tr_x, viewcos) + FixedMul(tr_y, viewsin);

  xscale := FixedDiv(projection, tz);

  tx := FixedMul(tr_x, viewsin) - FixedMul(tr_y, viewcos);

  x := centerx + FixedInt_FixedMul(tx, xscale);

  xscale := FixedDiv(projectiony, tz);
  y1 := centery - FixedInt_FixedMul(wz1 - viewz, xscale);
  y2 := centery - FixedInt_FixedMul(wz2 - viewz, xscale);
end;

function R_PointToScreen(const wx, wy, wz: fixed_t; var x, y: Integer): boolean;
begin
  result := R_PointToScreenBuffer(wx, wy, wz, x, y);
  x := x + viewwindowx;
  y := y + viewwindowy;
end;


end.
