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

unit r_aspect;

interface

procedure R_InitAspect;

function R_GetRelativeAspect: double;

var
  widescreensupport: Boolean = true;
  forcedaspectstr: string = '0.00';

implementation

uses
  Windows,
  d_delphi,
  m_misc,
  c_cmds,
  r_main;

var
  relative_aspect: Double = 1.0;

procedure R_CmdWideScreen(const parm: string);
var
  neww: boolean;
begin
  if parm = '' then
  begin
    printf('Current setting: widescreensupport = %s.'#13#10, [truefalseStrings[widescreensupport]]);
    exit;
  end;

  neww := C_BoolEval(parm, widescreensupport);
  if neww <> widescreensupport then
  begin
    widescreensupport := neww;
    setsizeneeded := true;
  end;

  R_CmdWideScreen('');
end;

function R_ForcedAspect: Double;
var
  ar, par: string;
  nar, npar: integer;
begin
  splitstring(forcedaspectstr, ar, par, [':', '/']);
  if par <> '' then
  begin
    nar := atoi(strtrim(ar));
    npar := atoi(strtrim(par));
    if npar > 0 then
      result := nar / npar
    else
      result := 0.0;
  end
  else
    result := atof(forcedaspectstr);

  if result < 1.0 then
    result := 0.0;
  forcedaspectstr := ftoa(result);
end;

procedure R_CmdForcedAspect(const parm: string);
begin
  if parm = '' then
  begin
    printf('Current setting: forcedaspect = %s.'#13#10, [forcedaspectstr]);
    exit;
  end;

  forcedaspectstr := parm;
  setsizeneeded := true;

  R_CmdForcedAspect('');
end;



procedure R_InitAspect;
var
  dm: TDevMode;
  i: integer;
  widths, heights: TDNumberList;
  maxwidth, maxheight: integer;
begin
  widths := TDNumberList.Create;
  maxwidth := 640;
  widths.Add(maxwidth);
  heights := TDNumberList.Create;
  maxheight := 480;
  heights.Add(maxheight);
  i := 0;
  while EnumDisplaySettings(nil, i, dm) do
  begin
    if (dm.dmPelsWidth > 640) and (dm.dmPelsHeight > 480) and (dm.dmBitsPerPel = 32) then
    begin
      widths.Add(dm.dmPelsWidth);
      heights.Add(dm.dmPelsHeight);
    end;
    inc(i);
  end;
  for i := 1 to widths.Count - 1 do
    if (widths.Numbers[i] >= maxwidth) and (heights.Numbers[i] >= maxheight) then
    begin
      maxwidth := widths.Numbers[i];
      maxheight := heights.Numbers[i];
    end;

  if maxheight > 0 then
  begin
    relative_aspect := maxwidth / maxheight / (4 / 3);
    if relative_aspect < 1.0 then
      relative_aspect := 1.0
    else if relative_aspect > 2.0 then
      relative_aspect := 2.0;
  end;
  widths.Free;
  heights.Free;
  C_AddCmd('widescreen,widescreensupport', @R_CmdWideScreen);
  C_AddCmd('forcedaspect', @R_CmdForcedAspect);
end;

function R_GetRelativeAspect: double;
var
  asp: Double;
begin
  if widescreensupport then
  begin
    asp := R_ForcedAspect;
    if asp < 1.0 then
      result := relative_aspect
    else
      result := asp / (4 / 3);
    if result < 1.0 then
      result := 1.0
    else if result > 2.0 then
      result := 2.0;
  end
  else
    result := 1.0;
end;

end.
