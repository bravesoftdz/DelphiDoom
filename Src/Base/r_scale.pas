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
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_scale;

interface

uses
  m_fixed,
  tables;

function R_ScaleFromGlobalAngle(const visangle: angle_t; out overflow: boolean): fixed_t;
function R_ScaleFromGlobalAngle_DBL(const visangle: angle_t): double;

var
  precisescalefromglobalangle: Boolean = true;

implementation

uses
  doomtype,
  r_segs,
  r_main;

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//
// JVAL: SOS -> Here lays a problem with rendering accuracy
function R_ScaleFromGlobalAngle(const visangle: angle_t; out overflow: boolean): fixed_t;
var
  anglea: angle_t;
  angleb: angle_t;
  num: fixed_t;
  den: integer;
begin
  anglea := ANG90 + (visangle - viewangle);
  angleb := ANG90 + (visangle - rw_normalangle);

  {$IFDEF FPC}
  num := FixedMul(projectiony, finesine[_SHRW(angleb, ANGLETOFINESHIFT)]); // JVAL For correct aspect
  den := FixedMul(rw_distance, finesine[_SHRW(anglea, ANGLETOFINESHIFT)]);
  {$ELSE}
  num := FixedMulEx(projectiony, finesine[angleb shr ANGLETOFINESHIFT]); // JVAL For correct aspect
  den := FixedMulEx(rw_distance, finesine[anglea shr ANGLETOFINESHIFT]);
  {$ENDIF}

// JVAL: SOS -> Using  result := FixedDivEx(num, den); Exit; eliminates rendering
//        precision erros but crash the game as rw_scale & rw_scalestep are 16:16
//        fixed point
  if den > FixedInt(num) then
  begin
    result := FixedDiv(num, den);
  // JVAL: Change it to 256 * FRACUNIT ??  - original
    if result > 64 * FRACUNIT then
    begin
      result := 64 * FRACUNIT;
      overflow := true and precisescalefromglobalangle;
    end
    else if result < 256 then
    begin
      result := 256;
      overflow := true and precisescalefromglobalangle;
    end
    else
      overflow := false;
  end
  else
  begin
    result := 64 * FRACUNIT;
    overflow := true and precisescalefromglobalangle;
  end;
end;

function R_ScaleFromGlobalAngle_DBL(const visangle: angle_t): double;
var
  anglea: angle_t;
  angleb: angle_t;
  num: Double;
  den: Double;
begin
  anglea := ANG90 + (visangle - viewangle);
  angleb := ANG90 + (visangle - rw_normalangle);

  num := projectiony * Sin(angleb * ANGLE_T_TO_RAD);
  den := rw_distance * Sin(anglea * ANGLE_T_TO_RAD);

  if den = 0 then
  begin
    if num < 0 then
      result := MININT
    else
      result := MAXINT;
  end
  else
  begin
    result := (num / den) * FRACUNIT;
    if result < MININT then
      result := MININT
    else if result > MAXINT then
      result := MAXINT
  end;

end;

end.


