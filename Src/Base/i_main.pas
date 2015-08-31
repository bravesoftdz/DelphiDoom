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
//
// DESCRIPTION:
//   Main program, simply calls D_DoomMain high level loop.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

{$WARN SYMBOL_DEPRECATED OFF}

unit i_main;

interface

uses
  Windows;

var
  hMainWnd: HWND = 0;

procedure DoomMain;

implementation

uses
  Messages,
  doomdef,
  g_game,
  i_input,
  i_system,
  m_argv,
  m_base,
  d_main;

function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;
begin
  if not I_GameFinished then
  begin
    case Msg of
      WM_SETCURSOR:
        begin
          SetCursor(0);
        end;
      WM_SYSCOMMAND:
        begin
          if (wParam = SC_SCREENSAVE) or (wParam = SC_MINIMIZE) then
          begin
            result := 0;
            exit;
          end;
          if fullscreen and (wParam = SC_TASKLIST) then
          begin
            result := 0;
            exit;
          end;
        end;
      WM_SIZE:
        begin
          result := 0;
          exit;
        end;
      WM_ACTIVATE:
        begin
          InBackground := (LOWORD(wparam) = WA_INACTIVE) or (HIWORD(wparam) <> 0);
          I_SynchronizeInput(not InBackground);
        end;
      WM_CLOSE:
        begin
          result := 0; // Preserve closing window by pressing Alt + F4
          exit;
        end;
      WM_DESTROY:
        begin
          result := 0;
          I_Destroy(0);
          exit;
        end;
    end;
  end;

  result := DefWindowProc(hWnd, Msg, WParam, LParam);
end;

procedure DoomMain;
var
  WindowClass: TWndClass;
begin
  ZeroMemory(@WindowClass, SizeOf(WindowClass));
  WindowClass.lpfnWndProc := @WindowProc;
  WindowClass.hbrBackground := GetStockObject(DKGRAY_BRUSH);
  WindowClass.lpszClassName := WINCLASSNAME;
  if HPrevInst = 0 then
  begin
    WindowClass.hInstance := HInstance;
    WindowClass.hIcon := LoadIcon(HInstance, 'MAINICON');
    WindowClass.hCursor := 0;
    if RegisterClass(WindowClass) = 0 then
      halt(1);
  end;
  hMainWnd := CreateWindowEx(
    CS_HREDRAW or CS_VREDRAW,
    WindowClass.lpszClassName,
    AppTitle,
    WS_OVERLAPPED {$IFDEF FPC} or WS_SYSMENU{$ENDIF},
    0,
    0,
    0,
    0,
    0,
    0,
    HInstance,
    nil);

  SetCursor(0);
  D_DoomMain;
end;

end.
