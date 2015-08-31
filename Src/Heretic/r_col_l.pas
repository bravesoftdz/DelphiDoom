//------------------------------------------------------------------------------
//
//  DelphiHeretic: A modified and improved Heretic port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2007 by Jim Valavanis
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
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_col_l;

interface

// Light column drawing functions
procedure R_DrawWhiteLightColumnHi;
procedure R_DrawRedLightColumnHi;
procedure R_DrawGreenLightColumnHi;
procedure R_DrawBlueLightColumnHi;
procedure R_DrawYellowLightColumnHi;

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  r_draw, r_main, r_column, r_hires,
  v_video;
  
procedure R_DrawWhiteLightColumnHi;
{$DEFINE WHITE}
{$I R_DrawLightColumnHi.inc}
{$UNDEF WHITE}

procedure R_DrawRedLightColumnHi;
{$DEFINE RED}
{$I R_DrawLightColumnHi.inc}
{$UNDEF RED}

procedure R_DrawGreenLightColumnHi;
{$DEFINE GREEN}
{$I R_DrawLightColumnHi.inc}
{$UNDEF GREEN}

procedure R_DrawBlueLightColumnHi;
{$DEFINE BLUE}
{$I R_DrawLightColumnHi.inc}
{$UNDEF BLUE}

procedure R_DrawYellowLightColumnHi;
{$DEFINE YELLOW}
{$I R_DrawLightColumnHi.inc}
{$UNDEF YELLOW}

end.
