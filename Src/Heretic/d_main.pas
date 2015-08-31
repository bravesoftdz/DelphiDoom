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
// DESCRIPTION (d_main.h:
//  System specific interface stuff.
//
// DESCRIPTION (d_main.c:
// DOOM main program (D_DoomMain) and game loop (D_DoomLoop),
// plus functions to determine game mode (shareware, registered),
// parse command line parameters, configure game parameters (turbo),
// and call the startup functions.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_main;

interface

uses
  d_event,
  doomdef;

const
{$IFDEF FPC}
  AppTitle = 'Free Pascal Heretic';
{$ELSE}
  AppTitle = 'Delphi Heretic';
{$ENDIF}

procedure D_ProcessEvents;
procedure D_DoAdvanceDemo;


procedure D_AddFile(const fname: string);

//
// D_DoomMain()
// Not a globally visible function, just included for source reference,
// calls all startup code, parses command line options.
// If not overrided by user input, calls N_AdvanceDemo.
//
procedure D_DoomMain;

// Called by IO functions when input is detected.
procedure D_PostEvent(ev: Pevent_t);

//
// BASE LEVEL
//
procedure D_PageTicker;

procedure D_PageDrawer;

procedure D_AdvanceDemo;

procedure D_StartTitle;

function D_IsPaused: boolean;

procedure D_Display;

// wipegamestate can be set to -1 to force a wipe on the next draw
var
  wipegamestate: integer = -1;   // JVAL was gamestate_t = GS_DEMOSCREEN;
  wipedisplay: boolean = false;

  nomonsters: boolean;          // checkparm of -nomonsters
  fastparm: boolean;            // checkparm of -fast
  devparm: boolean;             // started game with -devparm
  singletics: boolean;          // debug flag to cancel adaptiveness
  noartiskip: boolean;          // whether shift-enter skips an artifact
  autostart: boolean;
  startskill: skill_t;
  respawnparm: boolean;         // checkparm of -respawn

  startepisode: integer;
  startmap: integer;
  advancedemo: boolean;

  basedefault: string;          // default file

function D_Version: string;
function D_VersionBuilt: string;

procedure D_ShutDown;

var
  autoloadgwafiles: boolean = true;

var
  wads_autoload: string = '';
  paks_autoload: string = '';
  
implementation

uses
  d_delphi,
  deh_main,
  doomstat,
  d_ticcmd,
  d_player,
  d_net,
  d_net_h,
  c_con,
  c_cmds,
{$IFNDEF OPENGL}
  e_endoom,
  f_wipe,
{$ENDIF}
  f_finale,
  m_argv,
  m_misc,
  m_menu,
  m_fixed,
  h_strings,
  info,
  info_rnd,
  i_system,
  i_sound,
  i_io,
  i_tmp,
  i_startup,
{$IFDEF OPENGL}
  gl_main,
  gl_data,
{$ELSE}
  i_video,
{$ENDIF}
  g_game,
  sb_bar,
  hu_stuff,
  in_stuff,
  am_map,
  p_setup,
  p_mobj_h,
  r_draw,
  r_main,
  r_hires,
  r_defs,
  r_intrpl,
  r_data,
{$IFNDEF OPENGL}
  r_fake3d,
{$ENDIF}
  r_lights,
  sounds,
  s_sound,
  sc_decorate,
  t_main,
  v_data,
  v_video,
  w_autoload,
  w_wad,
  w_pak,
  z_zone;

const
  BGCOLOR = 7;
  FGCOLOR = 8;

//
// D_DoomLoop()
// Not a globally visible function,
//  just included for source reference,
//  called by D_DoomMain, never exits.
// Manages timing and IO,
//  calls all ?_Responder, ?_Ticker, and ?_Drawer,
//  calls I_GetTime, I_StartFrame, and I_StartTic
//

//
// D_PostEvent
// Called by the I/O functions when input is detected
//
procedure D_PostEvent(ev: Pevent_t);
begin
  events[eventhead] := ev^;
  inc(eventhead);
  eventhead := eventhead and (MAXEVENTS - 1);
end;

//
// D_ProcessEvents
// Send all the events of the given timestamp down the responder chain
//
procedure D_ProcessEvents;
var
  ev: Pevent_t;
begin
  if I_GameFinished then
    exit;

  while eventtail <> eventhead do
  begin
    ev := @events[eventtail];
    if C_Responder(ev) then
      // console ate the event
    else if M_Responder(ev) then
      // menu ate the event
    else
      G_Responder(ev);
    if I_GameFinished then
    begin
      eventtail := eventhead;
      exit;
    end;
    inc(eventtail);
    eventtail := eventtail and (MAXEVENTS - 1);
  end;
end;

//
// D_Display
//  draw current display, possibly wiping it from the previous
//

var
  viewactivestate: boolean = false;
  menuactivestate: boolean = false;
  inhelpscreensstate: boolean = false;
  borderdrawcount: integer;
  nodrawers: boolean = false; // for comparative timing purposes
  noblit: boolean = false;    // for comparative timing purposes
  norender: boolean = false;  // for comparative timing purposes
{$IFNDEF OPENGL}
  blancbeforerender: Boolean = false;
{$ENDIF}
  autoscreenshot: boolean = false;
  shotnumber: integer = 0;
  lastshotnumber: integer = -1;


procedure D_FinishUpdate;
begin
  if not noblit then
    I_FinishUpdate; // page flip or blit buffer
  if autoscreenshot then
  begin
    shotnumber := I_GetTime;
    if shotnumber <> lastshotnumber then
    begin
      M_ScreenShot(IntToStrZFill(8, shotnumber), true);
      inc(shotnumber);
    end;
  end;
end;

procedure D_RenderPlayerView(player: Pplayer_t);
begin
  if norender then
  begin
    R_PlayerViewBlanc(aprox_black);
    exit;
  end;

{$IFNDEF OPENGL}
  if blancbeforerender then
    R_PlayerViewBlanc(aprox_black);
{$ENDIF}

  if player <> nil then
    R_RenderPlayerView(player)
end;

var
  diskbusyend: integer = -1;

procedure D_Display;

{$IFDEF OPENGL}
procedure D_DisplayHU;
{$ENDIF}
var
  y: integer;
  redrawsbar: boolean;
  redrawbkscn: boolean;
  palette: PByteArray;
  drawhu: boolean;
  nowtime: integer;
{$IFNDEF OPENGL}
  tics: integer;
  wipe: boolean;
  wipestart: integer;
  done: boolean;
  oldvideomode: videomode_t;
{$ENDIF}
begin
{$IFNDEF OPENGL}
  if gamestate = GS_ENDOOM then
  begin
    E_Drawer;
    D_FinishUpdate; // page flip or blit buffer
    exit;
  end;
{$ENDIF}

{$IFNDEF OPENGL}
  HU_DoFPSStuff;
{$ENDIF}

  if nodrawers then
    exit; // for comparative timing / profiling

  redrawsbar := false;
  redrawbkscn := false;
  drawhu := false;

  // change the view size if needed
  if setsizeneeded then
  begin
    R_ExecuteSetViewSize;
    oldgamestate := -1; // force background redraw
    borderdrawcount := 3;
  end;

{$IFNDEF OPENGL}
  // save the current screen if about to wipe
  if Ord(gamestate) <> wipegamestate then
  begin
    wipe := true;
    wipe_StartScreen;
  end
  else
    wipe := false;
{$ENDIF}

  if (gamestate = GS_LEVEL) and (gametic <> 0) then
    HU_Erase;

  // do buffered drawing
  case gamestate of
    GS_LEVEL:
      begin
        if gametic <> 0 then
        begin
          if amstate = am_only then
            AM_Drawer;
          redrawsbar := true;
        end;
      end;
    GS_INTERMISSION:
      IN_Drawer;
    GS_FINALE:
      F_Drawer;
    GS_DEMOSCREEN:
      D_PageDrawer;
  end;

  // draw the view directly
  if gamestate = GS_LEVEL then
  begin
  {$IFNDEF OPENGL}
    if (amstate <> am_only) and (gametic <> 0) then
    begin
      D_RenderPlayerView(@players[displayplayer]);
      if amstate = am_overlay then
        AM_Drawer;
    end;
  {$ENDIF}
    redrawsbar := true;
    if gametic <> 0 then
      drawhu := true;
  end
  else if Ord(gamestate) <> oldgamestate then
  begin
  // clean up border stuff
    palette := V_ReadPalette(PU_STATIC);
    I_SetPalette(palette);
    V_SetPalette(palette);
    Z_ChangeTag(palette, PU_CACHE);
  end;

  // see if the border needs to be initially drawn
  if gamestate = GS_LEVEL then
  begin
{$IFNDEF OPENGL}
    if needsbackscreen or (oldgamestate <> Ord(GS_LEVEL)) then
    begin
      viewactivestate := false; // view was not active
      R_FillBackScreen;         // draw the pattern into the back screen
    end;
{$ENDIF}
  // see if the border needs to be updated to the screen
    if amstate <> am_only then
    begin
      if scaledviewwidth <> SCREENWIDTH then
      begin
        if menuactive or menuactivestate or (not viewactivestate) or C_IsConsoleActive then
          borderdrawcount := 3;
        if borderdrawcount > 0 then
        begin
          R_DrawViewBorder; // erase old menu stuff
          redrawbkscn := true;
          dec(borderdrawcount);
        end;
      end
      else if R_FullStOn and (gametic <> 0) then
        redrawsbar := true;
    end;
  end;

  menuactivestate := menuactive;
  viewactivestate := viewactive;
  inhelpscreensstate := inhelpscreens;
  oldgamestate := Ord(gamestate);
  wipegamestate := Ord(gamestate);

  // draw pause pic
  if paused then
  begin
    if amstate = am_only then
      y := 4
    else
      y := (viewwindowy * 200) div SCREENHEIGHT + 4;
    V_DrawPatch(160, y, SCN_FG,
      'PAUSED', true);
  end;

  if drawhu then
    HU_Drawer;

  nowtime := I_GetTime;

  if isdiskbusy then
  begin
    diskbusyend := nowtime + 4; // Display busy disk for a little...
    isdiskbusy := false;
  end;

  if redrawsbar then
    SB_Drawer;

  if diskbusyend > nowtime then
  begin
    // Menus go directly to the screen
    M_Drawer; // Menu is drawn even on top of everything

    // Console goes directly to the screen
    C_Drawer;   // Console is drawn even on top of menus

    // Draw disk busy patch
    R_DrawDiskBusy; // Draw disk busy is draw on top of console
  end
  else if (diskbusyend <= nowtime) and (diskbusyend <> -1) then
  begin
    if not redrawbkscn then
    begin
      R_DrawViewBorder;
      if drawhu then
        HU_Drawer;
    end;

    M_Drawer;
    C_Drawer;
    diskbusyend := -1;
  end
  else
  begin
    M_Drawer;
    C_Drawer;
  end;

  NetUpdate; // send out any new accumulation

  {$IFNDEF OPENGL}
  // normal update
  if not wipe then
  begin
    D_FinishUpdate; // page flip or blit buffer
    exit;
  end;

  // wipe update
  wipe_EndScreen;

  wipedisplay := true;
  wipestart := I_GetTime - 1;

  oldvideomode := videomode;
  videomode := vm32bit;
  repeat
    repeat
      nowtime := I_GetTime;
      tics := nowtime - wipestart;
    until tics <> 0;
    wipestart := nowtime;
    done := wipe_Ticker(tics);
    M_Drawer;         // Menu is drawn even on top of wipes
    C_Drawer;         // Console draw on top of wipes and menus
    D_FinishUpdate;   // page flip or blit buffer
    HU_DoFPSStuff;
  until done;
  videomode := oldvideomode;
  wipedisplay := false;
  {$ENDIF}
end;
{$IFDEF OPENGL}
begin
  HU_DoFPSStuff;
  if firstinterpolation then
    ZeroMemory(screen32, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) * 4);
  if gamestate = GS_LEVEL then
  begin
    if (amstate <> am_only) and (gametic <> 0) then
    begin
      R_FillBackScreen;         // draw the pattern into the back screen
      D_RenderPlayerView(@players[displayplayer]);
    end;
  end;
  if firstinterpolation then
  begin
    if gamestate = GS_LEVEL then
      if amstate = am_overlay then
        AM_Drawer;
    D_DisplayHU;
  end;
  D_FinishUpdate; // page flip or blit buffer
end;
{$ENDIF}

//
//  D_DoomLoop
//

{$IFDEF DEBUG}
var
  internalerrors: integer = 0;
{$ENDIF}

procedure D_DoomLoop;
{$IFNDEF DEBUG}
var
  iscritical: boolean;
{$ENDIF}
begin
  if demorecording then
    G_BeginRecording;

  while true do
  begin
{$IFDEF DEBUG}
    try
{$ENDIF}
    // frame syncronous IO operations
    I_StartFrame;

    iscritical := not usemultithread and not devparm and criticalcpupriority;
    if iscritical then
      I_SetCriticalCPUPriority;

    // process one or more tics
    if singletics then
      D_RunSingleTick // will run only one tick
    else
      D_RunMultipleTicks; // will run at least one tick

    if iscritical then
      I_SetNormalCPUPriority;

    S_UpdateSounds(players[consoleplayer].mo);// move positional sounds

{$IFDEF DEBUG}
    except
      inc(internalerrors);
      fprintf(debugfile, 'Internal Error No %d'#13#10, [internalerrors]);
    end;
{$ENDIF}
  end;
end;

//
//  DEMO LOOP
//
var
  demosequence: integer;
  pagetic: integer;
  pagename: string;

//
// D_PageTicker
// Handles timing for warped projection
//
procedure D_PageTicker;
begin
  dec(pagetic);
  if pagetic < 0 then
    D_AdvanceDemo;
end;

//
// D_PageDrawer
//
procedure D_PageDrawer;
begin
  V_PageDrawer(pagename);
  {$IFNDEF OPENGL}
  if demosequence = 0 then
    if (SCREENWIDTH = 1920) and (SCREENHEIGHT = 1080) then
      V_DrawPatch(120, 1060, SCN_FG, W_CacheLumpName('FULLHD', PU_CACHE), false);
  {$ENDIF}
  if demosequence = 1 then
    V_DrawPatch(4, 160, SCN_FG, W_CacheLumpName('ADVISOR', PU_CACHE), true);
end;

//
// D_AdvanceDemo
// Called after each demo or intro demosequence finishes
//
procedure D_AdvanceDemo;
begin
{$IFNDEF OPENGL}
  if gamestate <> GS_ENDOOM then
{$ENDIF}
    advancedemo := true;
end;

//
// This cycles through the demo sequences.
// FIXME - version dependend demo numbers?
//
procedure D_DoAdvanceDemo;
begin
  players[consoleplayer].playerstate := PST_LIVE;  // not reborn
  advancedemo := false;
  usergame := false;               // no save / end game here
  paused := false;
  gameaction := ga_nothing;

  demosequence := (demosequence + 1) mod 7;

  case demosequence of
    0:
      begin
        pagetic := 210;
        gamestate := GS_DEMOSCREEN;
        pagename := pg_TITLE;
        S_StartMusic(Ord(mus_titl));
      end;
    1:
      begin
        pagetic := 140;
        gamestate := GS_DEMOSCREEN;
        pagename := pg_TITLE;
      end;
    2:
      begin
        G_DeferedPlayDemo('1');
      end;
    3:
      begin
        pagetic := 200;
        gamestate := GS_DEMOSCREEN;
        pagename := pg_CREDIT;
      end;
    4:
      begin
        G_DeferedPlayDemo('2');
      end;
    5:
      begin
        pagetic := 200;
        gamestate := GS_DEMOSCREEN;
        if gamemode = shareware then
          pagename := pg_ORDER
        else
          pagename := pg_CREDIT;
      end;
    6:
      begin
        G_DeferedPlayDemo('3');
      end;
  end;
end;

//
// D_StartTitle
//
procedure D_StartTitle;
begin
  gameaction := ga_nothing;
  demosequence := -1;
  D_AdvanceDemo;
end;

var
  wadfiles: TDStringList;

//
// D_AddFile
//
procedure D_AddFile(const fname: string);
{$IFDEF OPENGL}
var
  ext: string;
  len: integer;
  gwafname: string;
{$ENDIF}
begin
  if fname <> '' then
  begin
    if wadfiles.IndexOf(fname) >= 0 then
      exit;
    try
      wadfiles.Add(fname);
    {$IFDEF OPENGL}
    // JVAL: If exists automatically loads GWA file
      if autoloadgwafiles then
      begin
        ext := strupper(fext(fname));
        if ext = '.WAD' then
        begin
          gwafname := fname;
          len := Length(gwafname);
          gwafname[len - 2] := 'G';
          gwafname[len - 1] := 'W';
          gwafname[len] := 'A';
          if fexists(gwafname) then
            wadfiles.Add(gwafname)
          else
          begin
            gwafname := M_SaveFileName(gwafname);
            if fexists(gwafname) then
              wadfiles.Add(gwafname)
            else if gld_BuildNodes(fname, gwafname) then
              wadfiles.Add(gwafname);
          end;
        end;
      end;
    {$ENDIF}
    except
      printf('D_AddFile(): Can not add %s'#13#10, [fname]);
    end;
  end;
end;

const
  SYSWAD = 'Heretic32.swd';

procedure D_AddSystemWAD;
var
  ddsyswad: string;
  hereticwaddir: string;
begin
  hereticwaddir := getenv('hereticwaddir');
  if hereticwaddir = '' then
    hereticwaddir := '.';

  sprintf(ddsyswad, '%s\%s', [hereticwaddir, SYSWAD]);
  if fexists(ddsyswad) then
    D_AddFile(ddsyswad)
  else
    I_Warning('D_AddSystemWAD(): System WAD %s not found.'#13#10, [ddsyswad]);
end;


procedure D_WadsAutoLoad(fnames: string);
var
  s1, s2: string;
begin
  fnames := strtrim(fnames);
  if fnames = '' then
    exit;

  splitstring(fnames, s1, s2, [',', ' ']);
  D_AddFile(s1);
  D_WadsAutoLoad(s2);
end;

procedure D_PaksAutoload(fnames: string);
var
  s1, s2: string;
begin
  fnames := strtrim(fnames);
  if fnames = '' then
    exit;

  splitstring(fnames, s1, s2, [',', ' ']);
  PAK_AddFile(s1);
  D_PaksAutoload(s2);
end;

//
// IdentifyVersion
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features
// should be executed (notably loading PWAD's).
//
var
  custiwad: string = ''; // Custom main WAD

procedure IdentifyVersion;
var
  heretic1wad: string;
  hereticwad: string;

  hereticwaddir: string;

  p: integer;
begin
  hereticwaddir := getenv('HERETICWADDIR');
  if hereticwaddir = '' then
    hereticwaddir := '.';

  // Shareware
  sprintf(heretic1wad, '%s\heretic1.wad', [hereticwaddir]);

  // Registered / extendedwad
  sprintf(hereticwad, '%s\heretic.wad', [hereticwaddir]);

  basedefault := 'Heretic32.ini';

  p := M_CheckParm('-mainwad');
  if p = 0 then
    p := M_CheckParm('-iwad');
  if (p > 0) and (p < myargc - 1) then
  begin
    inc(p);
    custiwad := myargv[p];
    if fexists(custiwad) then
    begin
      printf(' External main wad in use: %s'#13#10, [custiwad]);
      gamemode := indetermined;
      D_AddFile(custiwad);
      exit;
    end
    else
      custiwad := '';
  end;

  if fexists(hereticwad) then
  begin
    gamemode := indetermined; // Will check if register or extended wad later
    D_AddFile(hereticwad);
    exit;
  end;

  if fexists(heretic1wad) then
  begin
    gamemode := shareware;
    D_AddFile(heretic1wad);
    exit;
  end;

  printf('Game mode indeterminate.'#13#10);
  gamemode := indetermined;

end;

//
// Find a Response File
//
// JVAL: Changed to handle more than 1 response files
procedure FindResponseFile;
var
  i: integer;
  handle: file;
  size: integer;
  index: integer;
  myargv1: string;
  infile: string;
  filename: string;
  s: TDStringList;
begin
  s := TDStringList.Create;
  try
    s.Add(myargv[0]);

    for i := 1 to myargc - 1 do
    begin
      if myargv[i][1] = '@' then
      begin
        // READ THE RESPONSE FILE INTO MEMORY
        myargv1 := Copy(myargv[i], 2, length(myargv[i]) - 1);
        if fopen(handle, myargv1, fOpenReadOnly) then
        begin
          printf('Found response file %s!'#13#10, [myargv1]);

          size := FileSize(handle);
          seek(handle, 0);
          SetLength(filename, size);
          BlockRead(handle, (@filename[1])^, size);
          close(handle);

          infile := '';
          for index := 1 to Length(filename) do
            if filename[index] = ' ' then
              infile := infile + #13#10
            else
              infile := infile + filename[i];

          s.Text := s.Text + infile;
        end
        else
          printf(#13#10'No such response file: %s!'#13#10, [myargv1]);
      end
      else
        s.Add(myargv[i])
    end;

    index := 0;
    for i := 0 to s.Count - 1 do
      if s[i] <> '' then
      begin
        myargv[index] := s[i];
        inc(index);
        if index = MAXARGS then
          break;
      end;
    myargc := index;
  finally
    s.Free;
  end;
end;

function D_Version: string;
begin
  sprintf(result, Apptitle + ' version %d.%d', [VERSION div 100, VERSION mod 100]);
end;

function D_VersionBuilt: string;
begin
  sprintf(result, ' built %s', [I_VersionBuilt]);
end;

procedure D_CmdVersion;
begin
  printf('%s,%s'#13#10, [D_Version, D_VersionBuilt]);
end;

procedure D_CmdAddPakFile(const parm: string);
var
  files: TDStringList;
  i: integer;
begin
  if parm = '' then
  begin
    printf('Please specify the pak file or directory to load'#13#10);
    exit;
  end;

  // JVAL
  // If a shareware game do not allow external files
  if gamemode = shareware then
  begin
    I_Warning('You cannot use external files with the shareware version. Register!'#13#10);
    exit;
  end;

  if (Pos('*', parm) > 0) or (Pos('?', parm) > 0) then // It's a mask
    files := findfiles(parm)
  else
  begin
    files := TDStringList.Create;
    files.Add(parm)
  end;

  try

    for i := 0 to files.Count - 1 do
      if not PAK_AddFile(files[i]) then
        I_Warning('PAK_AddFile(): %s could not be added to PAK file system.'#13#10, [files[i]]);

  finally
    files.Free;
  end;

end;

procedure D_StartThinkers;
begin
  Info_Init(true);
  printf('Thinkers initialized'#13#10);
end;

procedure D_StopThinkers;
begin
  if demoplayback then
  begin
    I_Warning('Thinkers can not be disabled during demo playback.'#13#10);
    exit;
  end;

  if demorecording then
  begin
    I_Warning('Thinkers can not be disabled during demo recording.'#13#10);
    exit;
  end;

  Info_Init(false);
  printf('Thinkers disabled'#13#10);
end;

procedure D_AddWADFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
  // the parms after p are wadfile/lump names,
  // until end of parms or another - preceded parm
    modifiedgame := true; // homebrew levels
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      D_AddFile(myargv[p]);
      inc(p);
    end;
  end;
end;

procedure D_AddPAKFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
  // the parms after p are wadfile/lump names,
  // until end of parms or another - preceded parm
    modifiedgame := true; // homebrew levels
    externalpakspresent := true;
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      PAK_AddFile(myargv[p]);
      inc(p);
    end;
  end;
end;

procedure D_AddDEHFiles(const parm: string);
var
  p: integer;
begin
  p := M_CheckParm(parm);
  if p <> 0 then
  begin
  // the parms after p are wadfile/lump names,
  // until end of parms or another - preceded parm
    modifiedgame := true; // homebrew levels
    externaldehspresent := true;
    inc(p);
    while (p < myargc) and (myargv[p][1] <> '-') do
    begin
      DEH_ParseFile(myargv[p]);
      inc(p);
    end;
  end;
end;

procedure D_IdentifyGameDirectories;
var
  gamedirectorystring: string;
  i: integer;
  wad: string;
begin
  if gamemode = shareware then
    gamedirectorystring := 'HERETIC1,HERETIC'
  else
  begin
    gamedirectorystring := 'HERETIC,HERETIC1';
    if gamemode = extendedwad then
      gamedirectorystring := 'EXTENDED,HERETIC-EXT,' + gamedirectorystring;
  end;
  for i := wadfiles.Count - 1 downto 0 do
  begin
    wad := strupper(fname(wadfiles[0]));
    if Pos('.', wad) > 0 then
      wad := Copy(wad, 1, Pos('.', wad) - 1);
    if Pos(wad + ',', gamedirectorystring + ',') = 0 then
      gamedirectorystring := wad + ',' + gamedirectorystring;
  end;

  gamedirectories := PAK_GetDirectoryListFromString(gamedirectorystring);
  for i := 0 to gamedirectories.Count - 1 do
  begin
    wad := gamedirectories[i];
    if wad <> '' then
      if wad[length(wad)] = '\' then
        printf(' %s'#13#10, [wad]);
  end;
end;

//
// D_DoomMain
//
procedure D_DoomMain;
var
  p: integer;
  filename: string;
  scale: integer;
  _time: integer;
  s_error: string;
  i: integer;
  j: integer;
  oldoutproc: TOutProc;
  mb_min: integer; // minimum zone size
begin
  SUC_Open;
  outproc := @SUC_Outproc;
  wadfiles := TDSTringList.Create;

  printf('Starting %s, %s'#13#10, [D_Version, D_VersionBuilt]);
  C_AddCmd('ver, version', @D_CmdVersion);
  C_AddCmd('addpakfile, loadpakfile, addpak, loadpak', @D_CmdAddPakFile);
  C_AddCmd('startthinkers', @D_StartThinkers);
  C_AddCmd('stopthinkers', @D_StopThinkers);

  SUC_Progress(1);

  printf('M_InitArgv: Initializing command line parameters.'#13#10);
  M_InitArgv;

  SUC_Progress(2);

  FindResponseFile;

  printf('I_InitializeIO: Initializing input/output streams.'#13#10);
  I_InitializeIO;

  printf('I_InitTempFiles: Initializing temporary file managment.'#13#10);
  I_InitTempFiles;

  SUC_Progress(3);

  D_AddSystemWAD; // Add system wad first

  SUC_Progress(5);

  IdentifyVersion;

  modifiedgame := false;

  nomonsters := M_CheckParm('-nomonsters') > 0;
  respawnparm := M_CheckParm('-respawn') > 0;
  fastparm := M_CheckParm('-fast') > 0;
  devparm := M_CheckParm('-devparm') > 0;

  SUC_Progress(6);

  if M_CheckParm('-altdeath') > 0 then
    deathmatch := 2
  else if M_CheckParm('-deathmatch') > 0 then
    deathmatch := 1;

  if gamemode = shareware then
    printf(
           '                           ' +
           'Heretic Shareware Startup v%d.%d' +
           '                         '#13#10,
            [VERSION div 100, VERSION mod 100])
  else
    printf(
           '                            ' +
           '   Heretic Startup v%d.%d' +
           '                           '#13#10,
            [VERSION div 100, VERSION mod 100]);

  if devparm then
    printf(D_DEVSTR);

  if M_CheckParmCDROM then
  begin
    printf(D_CDROM);
    basedefault := CD_WORKDIR + 'Heretic32.ini';
  end;

  // turbo option
  p := M_CheckParm('-turbo');
  if p <> 0 then
  begin
    if p < myargc - 1 then
    begin
      scale := atoi(myargv[p + 1]);
      if scale < 10 then
        scale := 10
      else if scale > 200 then
        scale := 200;
    end
    else
      scale := 200;
    printf(' turbo scale: %d'#13#10, [scale]);
    forwardmove[0] := forwardmove[0] * scale div 100;
    forwardmove[1] := forwardmove[1] * scale div 100;
    sidemove[0] := sidemove[0] * scale div 100;
    sidemove[1] := sidemove[1] * scale div 100;
  end;


  SUC_Progress(7);

  // add any files specified on the command line with -file wadfile
  // to the wad list
  //
  // convenience hack to allow -wart e m to add a wad file
  // prepend a tilde to the filename so wadfile will be reloadable
  p := M_CheckParm('-wart');
  if (p <> 0) and (p < myargc - 2) then
  begin
    myargv[p][5] := 'p';     // big hack, change to -warp

  // Map name handling.
    if p < myargc - 2 then
    begin
      sprintf(filename, '~' + DEVMAPS + 'E%sM%s.wad',
        [myargv[p + 1][1], myargv[p + 2][1]]);
      printf('Warping to Episode %s, Map %s.'#13#10,
      [myargv[p + 1], myargv[p + 2]]);
    end;

    D_AddFile(filename);
  end;

  SUC_Progress(8);

  D_AddWADFiles('-file');
  for p := 1 to 9 do
    D_AddWADFiles('-file' + itoa(p));
  D_AddWADFiles('-lfile');  // JVAL launcher specific

  SUC_Progress(9);

  printf('PAK_InitFileSystem: Init PAK/ZIP/PK3/PK4 files.'#13#10);
  PAK_InitFileSystem;

  SUC_Progress(15);

  D_AddPAKFiles('-pakfile');
  for p := 1 to 9 do
    D_AddPAKFiles('-pakfile' + itoa(p));
  D_AddPAKFiles('-lpakfile'); // JVAL launcher specific

  SUC_Progress(16);

  p := M_CheckParm('-playdemo');

  if p = 0 then
    p := M_CheckParm('-timedemo');

  if (p <> 0) and (p < myargc - 1) then
  begin
    inc(p);
    if Pos('.', myargv[p]) > 0 then
      filename := myargv[p]
    else
      sprintf(filename,'%s.lmp', [myargv[p]]);
    D_AddFile(filename);
    printf('Playing demo %s.'#13#10, [filename]);
  end;

  // get skill / episode / map from parms
  startskill := sk_medium;
  startepisode := 1;
  startmap := 1;
  autostart := false;

  p := M_CheckParm('-skill');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startskill := skill_t(Ord(myargv[p + 1][1]) - Ord('1'));
    autostart := true;
  end;

  p := M_CheckParm('-episode');
  if (p <> 0) and (p < myargc - 1) then
  begin
    startepisode := atoi(myargv[p + 1]);
    startmap := 1;
    autostart := true;
  end;

  p := M_CheckParm('-timer');
  if (p <> 0) and (p < myargc - 1) and (deathmatch <> 0) then
  begin
    _time := atoi(myargv[p + 1]);
    printf('Levels will end after %d minute' + decide(_time > 1, 's', '') + #13#10, [_time]);
  end;

  p := M_CheckParm('-avg');
  if (p <> 0) and (p <= myargc - 1) and (deathmatch <> 0) then
    printf('Austin Virtual Gaming: Levels will end after 20 minutes'#13#10);

  printf('M_LoadDefaults: Load system defaults.'#13#10);
  M_LoadDefaults;              // load before initing other systems

  D_WadsAutoLoad(wads_autoload);
  D_PaksAutoload(paks_autoload);

  SUC_Progress(20);

  p := M_CheckParm('-fullscreen');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := true;

  p := M_CheckParm('-nofullscreen');
  if p = 0 then
    p := M_CheckParm('-windowed');
  if (p <> 0) and (p <= myargc - 1) then
    fullscreen := false;

  p := M_CheckParm('-zaxisshift');
  if (p <> 0) and (p <= myargc - 1) then
    zaxisshift := true;

  p := M_CheckParm('-nozaxisshift');
  if (p <> 0) and (p <= myargc - 1) then
    zaxisshift := false;

{$IFNDEF OPENGL}
  p := M_CheckParm('-fake3d');
  if (p <> 0) and (p <= myargc - 1) then
    usefake3d := true;

  p := M_CheckParm('-nofake3d');
  if (p <> 0) and (p <= myargc - 1) then
    usefake3d := false;
{$ENDIF}

  if M_Checkparm('-ultrares') <> 0 then
    detailLevel := DL_ULTRARES;

  if M_Checkparm('-hires') <> 0 then
    detailLevel := DL_HIRES;

  if M_Checkparm('-normalres') <> 0 then
    detailLevel := DL_NORMAL;

  if M_Checkparm('-mediumres') <> 0 then
    detailLevel := DL_MEDIUM;

  if M_Checkparm('-lowres') <> 0 then
    detailLevel := DL_LOW;

  if M_Checkparm('-lowestres') <> 0 then
    detailLevel := DL_LOWEST;

  if M_Checkparm('-interpolate') <> 0 then
    interpolate := true;

  if M_Checkparm('-nointerpolate') <> 0 then
    interpolate := false;

  p := M_CheckParm('-compatibilitymode');
  if (p <> 0) and (p <= myargc - 1) then
    compatibilitymode := true;

  p := M_CheckParm('-nocompatibilitymode');
  if (p <> 0) and (p <= myargc - 1) then
    compatibilitymode := false;

  oldcompatibilitymode := compatibilitymode;

  p := M_CheckParm('-spawnrandommonsters');
  if (p <> 0) and (p <= myargc - 1) then
    spawnrandommonsters := true;

  p := M_CheckParm('-nospawnrandommonsters');
  if (p <> 0) and (p <= myargc - 1) then
    spawnrandommonsters := false;

  p := M_CheckParm('-mouse');
  if (p <> 0) and (p <= myargc - 1) then
    usemouse := true;

  p := M_CheckParm('-nomouse');
  if (p <> 0) and (p <= myargc - 1) then
    usemouse := false;

  p := M_CheckParm('-invertmouselook');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouselook := true;

  p := M_CheckParm('-noinvertmouselook');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouselook := false;

  p := M_CheckParm('-invertmouseturn');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouseturn := true;

  p := M_CheckParm('-noinvertmouseturn');
  if (p <> 0) and (p <= myargc - 1) then
    invertmouseturn := false;

  p := M_CheckParm('-nojoystick');
  if (p <> 0) and (p <= myargc - 1) then
    usejoystick := false;

  p := M_CheckParm('-joystick');
  if (p <> 0) and (p <= myargc - 1) then
    usejoystick := true;

  {$IFNDEF OPENGL}
  SCREENWIDTH := WINDOWWIDTH;
  {$ENDIF}
  p := M_CheckParm('-screenwidth');
  if (p <> 0) and (p < myargc - 1) then
    SCREENWIDTH := atoi(myargv[p + 1]);
  if SCREENWIDTH > MAXWIDTH then
    SCREENWIDTH := MAXWIDTH;

  {$IFNDEF OPENGL}
  SCREENHEIGHT := WINDOWHEIGHT;
  {$ENDIF}
  p := M_CheckParm('-screenheight');
  if (p <> 0) and (p < myargc - 1) then
    SCREENHEIGHT := atoi(myargv[p + 1]);
  if SCREENHEIGHT > MAXHEIGHT then
    SCREENHEIGHT := MAXHEIGHT;

  p := M_CheckParm('-fullhd');
  if (p <> 0) and (p < myargc - 1) then
  begin
    SCREENWIDTH := 1920;
    if SCREENWIDTH > MAXWIDTH then
      SCREENWIDTH := MAXWIDTH;
    SCREENHEIGHT := 1080;
    if SCREENHEIGHT > MAXHEIGHT then
      SCREENHEIGHT := MAXHEIGHT;
  end;

  p := M_CheckParm('-vga');
  if (p <> 0) and (p < myargc - 1) then
  begin
    SCREENWIDTH := 640;
    if SCREENWIDTH > MAXWIDTH then
      SCREENWIDTH := MAXWIDTH;
    SCREENHEIGHT := 480;
    if SCREENHEIGHT > MAXHEIGHT then
      SCREENHEIGHT := MAXHEIGHT;
  end;

  p := M_CheckParm('-svga');
  if (p <> 0) and (p < myargc - 1) then
  begin
    SCREENWIDTH := 800;
    if SCREENWIDTH > MAXWIDTH then
      SCREENWIDTH := MAXWIDTH;
    SCREENHEIGHT := 600;
    if SCREENHEIGHT > MAXHEIGHT then
      SCREENHEIGHT := MAXHEIGHT;
  end;

  p := M_CheckParm('-cga');
  if (p <> 0) and (p < myargc - 1) then
  begin
    SCREENWIDTH := 320;
    if SCREENWIDTH > MAXWIDTH then
      SCREENWIDTH := MAXWIDTH;
    SCREENHEIGHT := 200;
    if SCREENHEIGHT > MAXHEIGHT then
      SCREENHEIGHT := MAXHEIGHT;
  end;

  singletics := M_CheckParm('-singletics') > 0;
  noartiskip := M_CheckParm('-noartiskip') > 0;

  p := M_CheckParm('-autoscreenshot');
  autoscreenshot := p > 0;

//  I_RestoreWindowPos;

  SUC_Progress(25);

  nodrawers := M_CheckParm('-nodraw') <> 0;
  noblit := M_CheckParm('-noblit') <> 0;
  norender := M_CheckParm('-norender') <> 0;
{$IFNDEF OPENGL}
  blancbeforerender := M_CheckParm('-blancbeforerender') <> 0;
{$ENDIF}

  if M_CheckParm('-usetransparentsprites') <> 0 then
    usetransparentsprites := true;
  if M_CheckParm('-dontusetransparentsprites') <> 0 then
    usetransparentsprites := false;
  if M_CheckParm('-uselightboost') <> 0 then
    uselightboost := true;
  if M_CheckParm('-dontuselightboost') <> 0 then
    uselightboost := false;
  p := M_CheckParm('-lightboostfactor');
  if (p <> 0) and (p < myargc - 1) then
  begin
    p := atoi(myargv[p + 1], -1);
    if (p >= LFACTORMIN) and (p <= LFACTORMAX) then
      lightboostfactor := p
    else
      I_Warning('Invalid lightboostfactor specified from command line %d. Specify a value in range (%d..%d)'#13#10, [p, LFACTORMIN, LFACTORMAX]);
  end;
  if M_CheckParm('-chasecamera') <> 0 then
    chasecamera := true;
  if M_CheckParm('-nochasecamera') <> 0 then
    chasecamera := false;

// Try to guess minimum zone memory to allocate
  mb_min := 6 + V_ScreensSize(SCN_FG) div (1024 * 1024);
  if zonesize < mb_min then
    zonesize := mb_min;

  mb_used := zonesize;

  p := M_CheckParm('-zone');
  if (p <> 0) and (p < myargc - 1) then
  begin
    mb_used := atoi(myargv[p + 1]);
    if mb_used < mb_min then
    begin
      printf('Zone memory allocation needs at least %d MB (%d).'#13#10, [mb_min, mb_used]);
      mb_used := mb_min;
    end;
    zonesize := mb_used;
  end;

  // init subsystems
  printf('Z_Init: Init zone memory allocation daemon, allocation %d MB.'#13#10, [mb_used]);
  Z_Init;

  SUC_Progress(30);

  p := M_CheckParm('-nothinkers');
  if p = 0 then
  begin
    printf('I_InitInfo: Initialize information tables.'#13#10);
    Info_Init(true);
  end
  else
  begin
    I_Warning('Thinkers not initialized.'#13#10);
    Info_Init(false);
  end;

  SUC_Progress(31);

  for p := 1 to myargc do
    if strupper(fext(myargv[p])) = '.WAD' then
      D_AddFile(myargv[p]);

  for p := 1 to myargc do
    if (strupper(fext(myargv[p])) = '.PK3') or
       (strupper(fext(myargv[p])) = '.PK4') or
       (strupper(fext(myargv[p])) = '.ZIP') or
       (strupper(fext(myargv[p])) = '.PAK') then
    begin
      modifiedgame := true;
      externalpakspresent := true;
      PAK_AddFile(myargv[p]);
    end;

  printf('W_Init: Init WADfiles.'#13#10);
  if (W_InitMultipleFiles(wadfiles) = 0) or (W_CheckNumForName('playpal') = -1) then
  begin
  // JVAL
  //  If none wadfile has found as far,
  //  we search the current directory
  //  and we use the first WAD we find
    filename := findfile('*.wad');
    if filename <> '' then
      I_Warning('Loading unspecified wad file: %s'#13#10, [filename]);
    D_AddFile(filename);
    if W_InitMultipleFiles(wadfiles) = 0 then
      I_Error('W_InitMultipleFiles(): no files found');
  end;

  printf('W_AutoLoadPakFiles: Autoload required pak files.'#13#10);
  W_AutoLoadPakFiles;

  SUC_Progress(40);

  printf('DEH_Init: Initializing dehacked subsystem.'#13#10);
  DEH_Init;

  if M_CheckParm('-internalgamedef') = 0 then
    if not DEH_ParseLumpName('GAMEDEF') then
      I_Warning('DEH_ParseLumpName(): GAMEDEF lump not found, using defaults.'#13#10);

  SUC_Progress(41);

  printf('SC_Init: Initializing script engine.'#13#10);
  SC_Init;
  printf('SC_ParseDecorateLumps(): Parsing DECORATE lumps.'#13#10);
  SC_ParseDecorateLumps;

  SUC_Progress(45);

  if M_CheckParm('-nowaddehacked') = 0 then
    if not DEH_ParseLumpName('DEHACKED') then
      printf('DEH_ParseLumpName(): DEHACKED lump not found.'#13#10);

  // JVAL Adding dehached files
  D_AddDEHFiles('-deh');
  D_AddDEHFiles('-bex');

  SUC_Progress(50);

  for i := 0 to NUM_STARTUPMESSAGES - 1 do
    if startmsg[i] <> '' then
      printf('%s'#13#10, [startmsg[i]]);

  SUC_Progress(51);

  printf('T_Init: Initializing texture manager.'#13#10);
  T_Init;

  SUC_Progress(55);

  printf('V_Init: allocate screens.'#13#10);
  V_Init;

  SUC_Progress(56);

  printf('AM_Init: initializing automap.'#13#10);
  AM_Init;

  SUC_Progress(57);

  p := M_CheckParm('-autoexec');
  if (p <> 0) and (p < myargc - 1) then
    autoexecfile := myargv[p + 1]
  else
    autoexecfile := DEFAUTOEXEC;

  printf('M_InitMenus: Initializing menus.'#13#10);
  M_InitMenus;

  SUC_Progress(58);

  if gamemode = indetermined then
  begin
    if W_CheckNumForName('e5m1') <> -1 then
    begin
      gamemode := extendedwad;
    end
    else if W_CheckNumForName('e3m1') <> -1 then
    begin
      gamemode := registered;
    end
    else
    begin
      gamemode := shareware;
    end
  end;

  if W_CheckNumForName('e1m4') = -1 then
  begin
    gamemode := shareware;
    customgame := cg_beta;
  end;

  case gamemode of
    extendedwad: SUC_SetGameMode('Heretic: Extented Version');
    registered: SUC_SetGameMode('Registered Heretic');
    shareware: if customgame = cg_beta then SUC_SetGameMode('HERETIC - WIDE AREA BETA') else SUC_SetGameMode('Shareware Heretic');
  end;

  if customgame = cg_beta then
    if not DEH_ParseLumpName('BETA.DEH') then
      I_Warning('DEH_ParseLumpName(): BETA.DEH lump not found.'#13#10);

  SUC_Progress(59);

  printf('D_IdentifyGameDirectories: Identify game directories.'#13#10, [mb_used]);
  D_IdentifyGameDirectories;

  SUC_Progress(60);

  p := M_CheckParm('-warp');
  if (p <> 0) and (p < myargc - 2) then
  begin
    startepisode := atoi(myargv[p + 1]);
    startmap := atoi(myargv[p + 2]);
    autostart := true;
  end;

  SUC_Progress(61);

  // Check for -file in shareware
  // JVAL
  // Allow modified games if -devparm is specified, for debuging reasons
  if modifiedgame and (not devparm) then
  begin
    if gamemode = shareware then
      I_DevError(#13#10 + 'D_DoomMain(): You cannot use external files with the shareware version. Register!')
  // Check for fake IWAD with right name,
  // but w/o all the lumps of the registered version.
    else
    begin
  // These are the lumps that will be checked in IWAD,
  // if any one is not present, execution will be aborted.
      s_error := #13#10 + 'D_DoomMain(): This is not the registered version.';
      i := 2;
      while i <= 3 do
      begin
        j := 1;
        while j <= 9 do
        begin
          if W_CheckNumForName('e' + itoa(i) + 'm' + itoa(j)) < 0 then
          begin
            I_DevError(s_error);
            j := 9;
            i := 3;
          end;
          inc(j);
        end;
        inc(i);
      end;
    end;

  // If additonal PWAD files are used, print modified banner
    printf(MSG_MODIFIEDGAME);
    oldoutproc := outproc;
    I_IOSetWindowHandle(SUC_GetHandle);
    outproc := @I_IOMessageBox; // Print the message again to messagebox
    printf(MSG_MODIFIEDGAME);
    outproc := oldoutproc;
  end;

  SUC_Progress(65);

  case gamemode of
    shareware:
      printf(MSG_SHAREWARE);
    registered,
    extendedwad:
      printf(MSG_COMMERCIAL);
  else
    begin
      printf(MSG_UNDETERMINED);
    end;
  end;

  SUC_Progress(66);

  printf('Info_InitRandom: Initializing randomizers.'#13#10);
  Info_InitRandom;

  SUC_Progress(67);

  printf('M_Init: Init miscellaneous info.'#13#10);
  M_Init;

  SUC_Progress(68);

  p := M_CheckParm('-mmx');
  if p > 0 then
    usemmx := true;

  p := M_CheckParm('-nommx');
  if p > 0 then
    usemmx := false;

  if usemmx then
  begin
    printf('I_DetectCPU: Detecting CPU extensions.'#13#10);
    I_DetectCPU;
  end;

  SUC_Progress(69);

  printf('R_Init: Init HERETIC refresh daemon.');
  R_Init;

  SUC_Progress(80);

  printf(#13#10 + 'P_Init: Init Playloop state.'#13#10);
  P_Init;

  SUC_Progress(81);

  printf('D_CheckNetGame: Checking network game status.'#13#10);
  D_CheckNetGame;

  SUC_Progress(87);

  printf('S_Init: Setting up sound.'#13#10);
  S_Init(snd_SfxVolume, snd_MusicVolume);

  SUC_Progress(90);

  printf('HU_Init: Setting up heads up display.'#13#10);
  HU_Init;

  SUC_Progress(91);

  printf('SB_Init: Init status bar.'#13#10);
  SB_Init;

  SUC_Progress(92);

{$IFDEF OPENGL}
  GL_InitGraphics;
{$ELSE}
  I_InitGraphics;
{$ENDIF}

  SUC_Progress(95);

  printf('I_Init: Setting up machine state.'#13#10);
  I_Init;

//    // check for a driver that wants intermission stats
  p := M_CheckParm('-statcopy');
  if (p > 0) and (p < myargc - 1) then
  begin
  // for statistics driver
    statcopy := pointer(atoi(myargv[p + 1]));
    printf('External statistics registered.'#13#10);
  end;

  // start the apropriate game based on parms
  p := M_CheckParm('-record');

  if (p <> 0) and (p < myargc - 1) then
  begin
    G_RecordDemo(myargv[p + 1]);
    autostart := true;
  end;

  printf('C_Init: Initializing console.'#13#10);
  C_Init;

  SUC_Progress(100);

  SUC_Close;

  p := M_CheckParm('-playdemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
  // JVAL
  /// if -nosingledemo param exists does not
  // quit after one demo
    singledemo := M_CheckParm('-nosingledemo') = 0;
    G_DeferedPlayDemo(myargv[p + 1]);
    D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-timedemo');
  if (p <> 0) and (p < myargc - 1) then
  begin
    G_TimeDemo(myargv[p + 1]);
    D_DoomLoop;  // never returns
  end;

  p := M_CheckParm('-loadgame');
  if (p <> 0) and (p < myargc - 1) then
  begin
    sprintf(filename, M_SaveFileName(SAVEGAMENAME) + '%s.dsg', [myargv[p + 1][1]]);
    G_LoadGame(filename);
  end;

  if gameaction <> ga_loadgame then
  begin
    if autostart or netgame then
    begin
      G_InitNew(startskill, startepisode, startmap);
    end
    else
      D_StartTitle; // start up intro loop
  end;

  D_DoomLoop;  // never returns
end;

function D_IsPaused: boolean;
begin
  result := paused;
end;

procedure D_ShutDown;
var
  i: integer;
begin
  printf('C_ShutDown: Shut down console.'#13#10);
  C_ShutDown;
  printf('R_ShutDown: Shut down DOOM refresh daemon.');
  R_ShutDown;
  printf('Info_ShutDownRandom: Shut down randomizers.'#13#10);
  Info_ShutDownRandom;
  printf('T_ShutDown: Shut down texture manager.'#13#10);
  T_ShutDown;
  printf('SC_ShutDown: Shut down script engine.'#13#10);
  SC_ShutDown;
  printf('DEH_ShutDown: Shut down dehacked subsystem.'#13#10);
  DEH_ShutDown;
  printf('Info_ShutDown: Shut down game definition.'#13#10);
  Info_ShutDown;
  printf('PAK_ShutDown: Shut down PAK/ZIP/PK3/PK4 file system.'#13#10);
  PAK_ShutDown;
  printf('W_ShutDown: Shut down WAD file system.'#13#10);
  W_ShutDown;
{$IFNDEF OPENGL}
  printf('E_ShutDown: Shut down ENDOOM screen.'#13#10, [mb_used]);
  E_ShutDown;
{$ENDIF}
  printf('Z_ShutDown: Shut down zone memory allocation daemon.'#13#10, [mb_used]);
  Z_ShutDown;
  printf('V_ShutDown: Shut down screens.'#13#10, [mb_used]);
  V_ShutDown;

  gamedirectories.Free;

  if wadfiles <> nil then
  begin
    for i := 0 to wadfiles.Count - 1 do
      if wadfiles.Objects[i] <> nil then
        wadfiles.Objects[i].Free;

    wadfiles.Free;
  end;

end;

end.

