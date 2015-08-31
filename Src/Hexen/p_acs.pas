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
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_acs;

interface

uses
  d_delphi,
  d_think,
  p_mobj_h,
  r_defs;

const
  MAX_ACS_SCRIPT_VARS = 10;
  MAX_ACS_MAP_VARS = 32;
  MAX_ACS_WORLD_VARS = 64;
  ACS_STACK_DEPTH = 32;
  MAX_ACS_STORE = 20;

type
  aste_t = (
    ASTE_INACTIVE,
    ASTE_RUNNING,
    ASTE_SUSPENDED,
    ASTE_WAITINGFORTAG,
    ASTE_WAITINGFORPOLY,
    ASTE_WAITINGFORSCRIPT,
    ASTE_TERMINATING
  );
  Paste_t = ^aste_t;

  acsInfo_t = record
    number: integer;
    address: PInteger;
    argCount: integer;
    state: aste_t;
    waitValue: integer;
  end;
  acsInfo_tArray = array[0..$FFF] of acsInfo_t;
  PacsInfo_tArray = ^acsInfo_tArray;
  PacsInfo_t = ^acsInfo_t;

  acs_t = record
    thinker: thinker_t;
    activator: Pmobj_t;
    line: Pline_t;
    side: integer;
    number: integer;
    infoIndex: integer;
    delayCount: integer;
    stack: array[0..ACS_STACK_DEPTH - 1] of integer;
    stackPtr: integer;
    vars: array[0..MAX_ACS_SCRIPT_VARS - 1] of integer;
    ip: PInteger;
  end;
  Pacs_t = ^acs_t;

  acsstore_t = record
    map: integer;               // Target map
    script: integer;            // Script number on target map
    args: array[0..3] of byte;  // Padded to 4 for alignment
  end;
  Pacsstore_t = ^acsstore_t;

procedure P_PolyobjFinished(po: integer);

procedure P_TagFinished(tag: integer);

function P_StartACS(number: integer; map: integer; args: PByteArray;
  activator: Pmobj_t; line: Pline_t; side: integer): boolean;

function P_SuspendACS(number: integer; map: integer): boolean;

function P_TerminateACS(number: integer; map: integer): boolean;

function P_StartLockedACS(line: Pline_t; args: PByteArray; mo: Pmobj_t;
  side: integer): boolean;

procedure P_LoadACScripts(const lump: integer);

var
  ACScriptCount: integer;
  ActionCodeBase: PByteArray;
  ACSInfo: PacsInfo_tArray;
  MapVars: array[0..MAX_ACS_MAP_VARS - 1] of integer;
  WorldVars: array[0..MAX_ACS_WORLD_VARS - 1] of integer;
  ACSStore: array[0..MAX_ACS_STORE] of acsstore_t; // +1 for termination marker

procedure T_InterpretACS(script: Pacs_t);

procedure P_CheckACSStore;

procedure P_ACSInitNewGame;

procedure P_ACSInit;

procedure P_ACSShutDown;

implementation

uses
  doomdata,
  d_player,
  i_system,
  g_game,
  info_h,
  m_rnd,
  p_tick, p_inter, p_spec, p_setup, p_mobj, p_things,
  po_man,
  r_data,
  s_sound, sounds, s_sndseq,
  doomdef, xn_strings,
  w_wad,
  z_zone;

// MACROS ------------------------------------------------------------------

const
  SCRIPT_CONTINUE = 0;
  SCRIPT_STOP = 1;
  SCRIPT_TERMINATE = 2;
  OPEN_SCRIPTS_BASE = 1000;
  PRINT_BUFFER_SIZE = 256;
  GAME_SINGLE_PLAYER = 0;
  GAME_NET_COOPERATIVE = 1;
  GAME_NET_DEATHMATCH = 2;
  TEXTURE_TOP = 0;
  TEXTURE_MIDDLE = 1;
  TEXTURE_BOTTOM = 2;

var
  ACScript: Pacs_t;

// TYPES -------------------------------------------------------------------

type
  acsHeader_t = record
    marker: integer;
    infoOffset: integer;
    code: integer;
  end;
  PacsHeader_t = ^acsHeader_t;

// PRIVATE DATA DEFINITIONS ------------------------------------------------

var
  PCodePtr: PInteger;
  SpecArgs: array[0..7] of byte;
  ACStringCount: integer;
  ACStrings: TDStringList;
  PrintBuffer: string;
  NewScript: Pacs_t;

var
  PCodeCmds: array[0..101] of PIntFunction;

// CODE --------------------------------------------------------------------

//==========================================================================
//
// ScriptFinished
//
//==========================================================================

procedure ACS_ScriptFinished(number: integer);
var
  i: integer;
begin
  for i := 0 to ACScriptCount - 1 do
    if (ACSInfo[i].state = ASTE_WAITINGFORSCRIPT) and (ACSInfo[i].waitValue = number) then
      ACSInfo[i].state := ASTE_RUNNING;
end;


//==========================================================================
//
// T_InterpretACS
//
//==========================================================================

procedure T_InterpretACS(script: Pacs_t);
var
  cmd: integer;
  action: integer;
begin
  if ACSInfo[script.infoIndex].state = ASTE_TERMINATING then
  begin
    ACSInfo[script.infoIndex].state := ASTE_INACTIVE;
    ACS_ScriptFinished(ACScript.number);
    P_RemoveThinker(@ACScript.thinker);
    exit;
  end;

  if ACSInfo[script.infoIndex].state <> ASTE_RUNNING then
  begin
    exit;
  end;

  if script.delayCount <> 0 then
  begin
    dec(script.delayCount);
    exit;
  end;
                  
  ACScript := script;
  PCodePtr := ACScript.ip;
  repeat
    cmd := PCodePtr^;
    inc(PCodePtr);
    action := PCodeCmds[cmd];
  until action <> SCRIPT_CONTINUE;
  ACScript.ip := PCodePtr;
  if action = SCRIPT_TERMINATE then
  begin
    ACSInfo[script.infoIndex].state := ASTE_INACTIVE;
    ACS_ScriptFinished(ACScript.number);
    P_RemoveThinker(@ACScript.thinker);
  end;
end;

//==========================================================================
//
// StartOpenACS
//
//==========================================================================

procedure ACS_StartOpenACS(number: integer; infoIndex: integer; address: PInteger);
var
  script: Pacs_t;
begin
  script := Z_Malloc(sizeof(acs_t), PU_LEVSPEC, nil);
  memset(script, 0, SizeOf(acs_t));
  script.number := number;

  // World objects are allotted 1 second for initialization
  script.delayCount := TICRATE;

  script.infoIndex := infoIndex;
  script.ip := address;
  script.thinker._function.acp1 := @T_InterpretACS;
  P_AddThinker(@script.thinker);
end;


//==========================================================================
//
// P_LoadACScripts
//
//==========================================================================

procedure P_LoadACScripts(const lump: integer);
var
  i, j: integer;
  buffer: PInteger;
  header: PacsHeader_t;
  info: PacsInfo_t;
  b: PByteArray;
  stmp: string;
begin
  if W_LumpLength(lump) = 0 then
  begin
    ACScriptCount := 0;
    exit;
  end;
  header := W_CacheLumpNum(lump, PU_LEVEL);
  ActionCodeBase := PByteArray(header);
  buffer := PInteger(integer(header) + header.infoOffset);
  ACScriptCount := buffer^;
  inc(buffer);

  if ACScriptCount = 0 then
    exit; // Empty behavior lump

  ACSInfo := Z_Malloc(ACScriptCount * SizeOf(acsInfo_t), PU_LEVEL, nil);
  memset(ACSInfo, 0, ACScriptCount * SizeOf(acsInfo_t));

  i := 0;
  info := @ACSInfo[0];
  while i < ACScriptCount do
  begin
    info.number := buffer^;
    inc(buffer);
    info.address := PInteger(@ActionCodeBase[buffer^]); // jval sos
    inc(buffer);
    info.argCount := buffer^;
    inc(buffer);
    if info.number >= OPEN_SCRIPTS_BASE then
    begin // Auto-activate
      info.number := info.number - OPEN_SCRIPTS_BASE;
      ACS_StartOpenACS(info.number, i, info.address);
      info.state := ASTE_RUNNING;
    end
    else
    begin
      info.state := ASTE_INACTIVE;
    end;
    inc(i);
    inc(info);
  end;
  ACStringCount := buffer^;
  inc(buffer);
  ACStrings.Clear;
  for i := 0 to ACStringCount - 1 do
  begin
//    b := PByteArray(buffer^ + integer(ActionCodeBase));
    b := @ActionCodeBase[buffer^];
    j := 0;
    stmp := '';
    while b[j] <> 0 do
    begin
      stmp := stmp + Chr(b[j]);
      inc(j);
    end;
    ACStrings.Add(stmp);
    inc(buffer);
  end;
  ZeroMemory(@MapVars, SizeOf(MapVars));
end;

//==========================================================================
//
// AddToACSStore
//
//==========================================================================

function ACS_AddToACSStore(map: integer; number: integer; args: PByteArray): boolean;
var
  i: integer;
  index: integer;
begin

  index := -1;
  i := 0;
  while ACSStore[i].map <> 0 do
  begin
    if (ACSStore[i].script = number) and (ACSStore[i].map = map) then
    begin // Don't allow duplicates
      result := false;
      exit;
    end;
    if (index = -1) and (ACSStore[i].map = -1) then
    begin // Remember first empty slot
      index := i;
    end;
    inc(i);
  end;
  if index = -1 then
  begin // Append required
    if i = MAX_ACS_STORE then
    begin
      I_Error('ACS_AddToACSStore(): MAX_ACS_STORE (%d) exceeded.', [MAX_ACS_STORE]);
    end;
    index := i;
    ACSStore[index + 1].map := 0;
  end;
  ACSStore[index].map := map;
  ACSStore[index].script := number;
  PInteger(@ACSStore[index].args)^ := PInteger(args)^;
  result := true;
end;


//==========================================================================
//
// GetACSIndex
//
// Returns the index of a script number.  Returns -1 if the script number
// is not found.
//
//==========================================================================

function GetACSIndex(number: integer): integer;
var
  i: integer;
begin
  for i := 0 to ACScriptCount - 1 do
  begin
    if ACSInfo[i].number = number then
    begin
      result := i;
      exit;
    end;
  end;
  result := -1;
end;


//==========================================================================
//
// P_StartACS
//
//==========================================================================


function P_StartACS(number: integer; map: integer; args: PByteArray;
  activator: Pmobj_t; line: Pline_t; side: integer): boolean;
var
  ErrorMsg: string;
  i: integer;
  script: Pacs_t;
  infoIndex: integer;
  statePtr: Paste_t;
begin
  NewScript := nil;

  if (map <> 0) and (map <> gamemap) then
  begin // Add to the script store
    result := ACS_AddToACSStore(map, number, args);
    exit;
  end;

  infoIndex := GetACSIndex(number);
  if infoIndex = -1 then
  begin // Script not found
    //I_Error("P_StartACS: Unknown script number %d", number);
    sprintf(ErrorMsg, 'P_STARTACS ERROR: UNKNOWN SCRIPT %d', [number]);
    P_SetMessage(@players[consoleplayer], ErrorMsg, true);
  end;

  statePtr := @ACSInfo[infoIndex].state;

  if statePtr^ = ASTE_SUSPENDED then
  begin // Resume a suspended script
    statePtr^ := ASTE_RUNNING;
    result := true;
    exit;
  end;

  if statePtr^ <> ASTE_INACTIVE then
  begin // Script is already executing
    result := false;
    exit;
  end;

  script := Z_Malloc(sizeof(acs_t), PU_LEVSPEC, nil);
  memset(script, 0, SizeOf(acs_t));
  script.number := number;
  script.infoIndex := infoIndex;
  script.activator := activator;
  script.line := line;
  script.side := side;
  script.ip := ACSInfo[infoIndex].address;
  script.thinker._function.acp1 := @T_InterpretACS;
  for i := 0 to ACSInfo[infoIndex].argCount - 1 do
    script.vars[i] := args[i];

  statePtr^ := ASTE_RUNNING;
  P_AddThinker(@script.thinker);
  NewScript := script;
  result := true;
end;

//==========================================================================
//
// P_CheckACSStore
//
// Scans the ACS store and executes all scripts belonging to the current
// map.
//
//==========================================================================

procedure P_CheckACSStore;
var
  store: Pacsstore_t;
begin
  store := @ACSStore[0];
  while store.map <> 0 do
  begin
    if store.map = gamemap then
    begin
      P_StartACS(store.script, 0, @store.args, nil, nil, 0);
      if NewScript <> nil then
        NewScript.delayCount := TICRATE;
      store.map := -1;
    end;
    inc(store);
  end;
end;

//==========================================================================
//
// P_StartLockedACS
//
//==========================================================================


function P_StartLockedACS(line: Pline_t; args: PByteArray; mo: Pmobj_t;
  side: integer): boolean;
var
  i: integer;
  lock: integer;
  newArgs: array[0..4] of byte;
  LockedBuffer: string;
begin
  if mo.player = nil then
  begin
    result := false;
    exit;
  end;

  lock := args[4];
  if lock <> 0 then
  begin
    if Pplayer_t(mo.player).keys and _SHL(1, lock - 1) = 0 then
    begin
      sprintf(LockedBuffer, 'YOU NEED THE %s', [TextKeyMessages[lock - 1]]);
      P_SetMessage(mo.player, LockedBuffer, true);
      S_StartSound(mo, Ord(SFX_DOOR_LOCKED));
      result := false;
      exit;
    end;
  end;
  for i := 0 to 3 do
    newArgs[i] := args[i];

  newArgs[4] := 0;
  result := P_StartACS(newArgs[0], newArgs[1], @newArgs[2], mo, line, side);
end;

//==========================================================================
//
// P_TerminateACS
//
//==========================================================================

function P_TerminateACS(number: integer; map: integer): boolean;
var
  infoIndex: integer;
begin
  infoIndex := GetACSIndex(number);
  if infoIndex = -1 then
  begin // Script not found
    result := false;
    exit;
  end;

  if (ACSInfo[infoIndex].state = ASTE_INACTIVE) or
     (ACSInfo[infoIndex].state = ASTE_TERMINATING) then
  begin // States that disallow termination
    result := false;
    exit;
  end;

  ACSInfo[infoIndex].state := ASTE_TERMINATING;
  result := true;
end;

//==========================================================================
//
// P_SuspendACS
//
//==========================================================================

function P_SuspendACS(number: integer; map: integer): boolean;
var
  infoIndex: integer;
begin
  infoIndex := GetACSIndex(number);
  if infoIndex = -1 then
  begin // Script not found
    result := false;
    exit;
  end;

  if (ACSInfo[infoIndex].state = ASTE_INACTIVE) or
     (ACSInfo[infoIndex].state = ASTE_SUSPENDED) or
     (ACSInfo[infoIndex].state = ASTE_TERMINATING) then
  begin // States that disallow suspension
    result := false;
    exit;
  end;
  ACSInfo[infoIndex].state := ASTE_SUSPENDED;
  result := true;
end;

//==========================================================================
//
// P_Init
//
//==========================================================================

procedure P_ACSInitNewGame;
begin
  ZeroMemory(@WorldVars, SizeOf(WorldVars));
  ZeroMemory(@ACSStore, SizeOf(ACSStore));
end;

//==========================================================================
//
// P_TagBusy
//
//==========================================================================
function P_TagBusy(tag: integer): boolean;
var
  sectorIndex: integer;

begin
  sectorIndex := -1;
  while P_FindSectorFromTag2(tag, sectorIndex) >= 0 do
  begin
    if sectors[sectorIndex].specialdata <> nil then
    begin
      result := true;
      exit;
    end;
  end;
  result := false;
end;


//==========================================================================
//
// P_TagFinished
//
//==========================================================================

procedure P_TagFinished(tag: integer);
var
  i: integer;
begin
  if P_TagBusy(tag) then
    exit;

  for i := 0 to ACScriptCount - 1 do
    if (ACSInfo[i].state = ASTE_WAITINGFORTAG) and (ACSInfo[i].waitValue = tag) then
      ACSInfo[i].state := ASTE_RUNNING;
end;

//==========================================================================
//
// P_PolyobjFinished
//
//==========================================================================

procedure P_PolyobjFinished(po: integer);
var
  i: integer;
begin
  if PO_Busy(po) then
    exit;

  for i := 0 to ACScriptCount - 1 do
    if (ACSInfo[i].state = ASTE_WAITINGFORPOLY) and (ACSInfo[i].waitValue = po) then
      ACSInfo[i].state := ASTE_RUNNING;
end;

//==========================================================================
//
// ACS_Push
//
//==========================================================================

procedure ACS_Push(const value: integer);
begin
  ACScript.stack[ACScript.stackPtr] := value;
  inc(ACScript.stackPtr);
end;

//==========================================================================
//
// ACS_Pop
//
//==========================================================================

function ACS_Pop: integer;
begin
  dec(ACScript.stackPtr);
  result := ACScript.stack[ACScript.stackPtr];
end;

//==========================================================================
//
// ACS_Top
//
//==========================================================================

function ACS_Top: integer;
begin
  result := ACScript.stack[ACScript.stackPtr - 1];
end;

//==========================================================================
//
// ACS_Drop
//
//==========================================================================

procedure ACS_Drop;
begin
  dec(ACScript.stackPtr);
end;

//==========================================================================
//
// P-Code Commands
//
//==========================================================================

function CmdNOP: integer;
begin
  result := SCRIPT_CONTINUE;
end;

function CmdTerminate: integer;
begin
  result := SCRIPT_TERMINATE;
end;

function CmdSuspend: integer;
begin
  ACSInfo[ACScript.infoIndex].state := ASTE_SUSPENDED;
  result := SCRIPT_STOP;
end;

function CmdPushNumber: integer;
begin
  ACS_Push(PCodePtr^); inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec1: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := ACS_Pop;
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec2: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[1] := ACS_Pop;
  SpecArgs[0] := ACS_Pop;
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec3: integer;
var
  special: integer;
begin

  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[2] := ACS_Pop;
  SpecArgs[1] := ACS_Pop;
  SpecArgs[0] := ACS_Pop;
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec4: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[3] := ACS_Pop;
  SpecArgs[2] := ACS_Pop;
  SpecArgs[1] := ACS_Pop;
  SpecArgs[0] := ACS_Pop;
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec5: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[4] := ACS_Pop;
  SpecArgs[3] := ACS_Pop;
  SpecArgs[2] := ACS_Pop;
  SpecArgs[1] := ACS_Pop;
  SpecArgs[0] := ACS_Pop;
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec1Direct: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := PCodePtr^; inc(PCodePtr);
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec2Direct: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := PCodePtr^; inc(PCodePtr);
  SpecArgs[1] := PCodePtr^; inc(PCodePtr);
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec3Direct: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := PCodePtr^; inc(PCodePtr);
  SpecArgs[1] := PCodePtr^; inc(PCodePtr);
  SpecArgs[2] := PCodePtr^; inc(PCodePtr);
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec4Direct: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := PCodePtr^; inc(PCodePtr);
  SpecArgs[1] := PCodePtr^; inc(PCodePtr);
  SpecArgs[2] := PCodePtr^; inc(PCodePtr);
  SpecArgs[3] := PCodePtr^; inc(PCodePtr);
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdLSpec5Direct: integer;
var
  special: integer;
begin
  special := PCodePtr^; inc(PCodePtr);
  SpecArgs[0] := PCodePtr^; inc(PCodePtr);
  SpecArgs[1] := PCodePtr^; inc(PCodePtr);
  SpecArgs[2] := PCodePtr^; inc(PCodePtr);
  SpecArgs[3] := PCodePtr^; inc(PCodePtr);
  SpecArgs[4] := PCodePtr^; inc(PCodePtr);
  P_ExecuteLineSpecial(special, @SpecArgs, ACScript.line,
    ACScript.side, ACScript.activator);
  result := SCRIPT_CONTINUE;
end;

function CmdAdd: integer;
begin
  ACS_Push(ACS_Pop + ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdSubtract: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(ACS_Pop - operand2);
  result := SCRIPT_CONTINUE;
end;

function CmdMultiply: integer;
begin
  ACS_Push(ACS_Pop * ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdDivide: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(ACS_Pop div operand2);
  result := SCRIPT_CONTINUE;
end;

function CmdModulus: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(ACS_Pop mod operand2);
  result := SCRIPT_CONTINUE;
end;

function CmdEQ: integer;
begin
  ACS_Push(IntVal(ACS_Pop = ACS_Pop));
  result := SCRIPT_CONTINUE;
end;

function CmdNE: integer;
begin
  ACS_Push(IntVal(ACS_Pop <> ACS_Pop));
  result := SCRIPT_CONTINUE;
end;

function CmdLT: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(IntVal(ACS_Pop < operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdGT: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(IntVal(ACS_Pop > operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdLE: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(IntVal(ACS_Pop <= operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdGE: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(IntVal(ACS_Pop >= operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdAssignScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdAssignMapVar: integer;
begin
  MapVars[PCodePtr^] := ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdAssignWorldVar: integer;
begin
  WorldVars[PCodePtr^] := ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdPushScriptVar: integer;
begin
  ACS_Push(ACScript.vars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdPushMapVar: integer;
begin
  ACS_Push(MapVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdPushWorldVar: integer;
begin
  ACS_Push(WorldVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdAddScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACScript.vars[PCodePtr^] + ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdAddMapVar: integer;
begin
  MapVars[PCodePtr^] := MapVars[PCodePtr^] + ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdAddWorldVar: integer;
begin
  WorldVars[PCodePtr^] := WorldVars[PCodePtr^] + ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdSubScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACScript.vars[PCodePtr^] - ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdSubMapVar: integer;
begin
  MapVars[PCodePtr^] := MapVars[PCodePtr^] - ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdSubWorldVar: integer;
begin
  WorldVars[PCodePtr^] := WorldVars[PCodePtr^] - ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdMulScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACScript.vars[PCodePtr^] * ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdMulMapVar: integer;
begin
  MapVars[PCodePtr^] := MapVars[PCodePtr^] * ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdMulWorldVar: integer;
begin
  WorldVars[PCodePtr^] := WorldVars[PCodePtr^] * ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDivScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACScript.vars[PCodePtr^] div ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDivMapVar: integer;
begin
  MapVars[PCodePtr^] := MapVars[PCodePtr^] div ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDivWorldVar: integer;
begin
  WorldVars[PCodePtr^] := WorldVars[PCodePtr^] div ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdModScriptVar: integer;
begin
  ACScript.vars[PCodePtr^] := ACScript.vars[PCodePtr^] mod ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdModMapVar: integer;
begin
  MapVars[PCodePtr^] := MapVars[PCodePtr^] mod ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdModWorldVar: integer;
begin
  WorldVars[PCodePtr^] := WorldVars[PCodePtr^] mod ACS_Pop;
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdIncScriptVar: integer;
begin
  inc(ACScript.vars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdIncMapVar: integer;
begin
  inc(MapVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdIncWorldVar: integer;
begin
  inc(WorldVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDecScriptVar: integer;
begin
  dec(ACScript.vars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDecMapVar: integer;
begin
  dec(MapVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdDecWorldVar: integer;
begin
  dec(WorldVars[PCodePtr^]);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdGoto: integer;
begin
  PCodePtr := @ActionCodeBase[PCodePtr^];
  result := SCRIPT_CONTINUE;
end;

function CmdIfGoto: integer;
begin
  if ACS_Pop <> 0 then
  begin
    PCodePtr := @ActionCodeBase[PCodePtr^];
  end
  else
  begin
    inc(PCodePtr);
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdDrop: integer;
begin
  ACS_Drop;
  result := SCRIPT_CONTINUE;
end;

function CmdDelay: integer;
begin
  ACScript.delayCount := ACS_Pop;
  result := SCRIPT_STOP;
end;

function CmdDelayDirect: integer;
begin
  ACScript.delayCount := PCodePtr^;
  inc(PCodePtr);
  result := SCRIPT_STOP;
end;

function CmdRandom: integer;
var
  low: integer;
  high: integer;
begin
  high := ACS_Pop;
  low := ACS_Pop;
  ACS_Push(low + (P_Random mod (high - low + 1)));
  result := SCRIPT_CONTINUE;
end;

function CmdRandomDirect: integer;
var
  low: integer;
  high: integer;
begin
  low := PCodePtr^;
  inc(PCodePtr);
  high := PCodePtr^;
  inc(PCodePtr);
  ACS_Push(low + (P_Random mod (high - low + 1)));
  result := SCRIPT_CONTINUE;
end;

procedure ThingCount(_type: integer; tid: integer);
var
  count: integer;
  searcher: integer;
  mobj: Pmobj_t;
  moType: mobjtype_t;
  think: Pthinker_t;

  function _FindMobjFromTID: Pmobj_t;
  begin
    result := P_FindMobjFromTID(tid, @searcher);
    mobj := result;
  end;

begin
  if _type + tid = 0 then
  begin // Nothing to count
    exit;
  end;

  moType := TranslateThingType[_type];
  count := 0;
  searcher := -1;
  if tid <> 0 then
  begin // Count TID things
    while _FindMobjFromTID <> nil do
    begin
      if _type = 0 then
      begin // Just count TIDs
        inc(count);
      end
      else if Ord(moType) = mobj._type then
      begin
        if (mobj.flags and MF_COUNTKILL <> 0) and (mobj.health <= 0) then
        begin // Don't count dead monsters
          continue;
        end;
        inc(count);
      end;
    end;
  end
  else
  begin // Count only types

    think := thinkercap.next;
    while think <> @thinkercap do
    begin
      if @think._function.acp1 <> @P_MobjThinker then
      begin // Not a mobj thinker
        think := think.next;
        continue;
      end;

      mobj := Pmobj_t(think);
      if mobj._type <> Ord(moType) then
      begin // Doesn't match
        think := think.next;
        continue;
      end;

      if (mobj.flags and MF_COUNTKILL <> 0) and (mobj.health <= 0) then
      begin // Don't count dead monsters
        think := think.next;
        continue;
      end;
      inc(count);
      think := think.next;
    end;
  end;
  ACS_Push(count);
end;

function CmdThingCount: integer;
var
  tid: integer;
begin
  tid := ACS_Pop;
  ThingCount(ACS_Pop, tid);
  result := SCRIPT_CONTINUE;
end;

function CmdThingCountDirect: integer;
var
  _type: integer;
begin
  _type := PCodePtr^;
  inc(PCodePtr);
  ThingCount(_type, PCodePtr^);
  inc(PCodePtr);
  result := SCRIPT_CONTINUE;
end;

function CmdTagWait: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := ACS_Pop;
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORTAG;
  result := SCRIPT_STOP;
end;

function CmdTagWaitDirect: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := PCodePtr^;
  inc(PCodePtr);
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORTAG;
  result := SCRIPT_STOP;
end;

function CmdPolyWait: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := ACS_Pop;
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORPOLY;
  result := SCRIPT_STOP;
end;

function CmdPolyWaitDirect: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := PCodePtr^;
  inc(PCodePtr);
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORPOLY;
  result := SCRIPT_STOP;
end;

function CmdChangeFloor: integer;
var
  tag: integer;
  flat: integer;
  sectorIndex: integer;
begin
  flat := R_FlatNumForName(ACStrings.Strings[ACS_Pop]);
  tag := ACS_Pop;
  sectorIndex := -1;
  while P_FindSectorFromTag2(tag, sectorIndex) >= 0 do
    sectors[sectorIndex].floorpic := flat;
  result := SCRIPT_CONTINUE;
end;

function CmdChangeFloorDirect: integer;
var
  tag: integer;
  flat: integer;
  sectorIndex: integer;
begin
  tag := PCodePtr^;
  inc(PCodePtr);
  flat := R_FlatNumForName(ACStrings[PCodePtr^]);
  inc(PCodePtr);
  sectorIndex := -1;
  while P_FindSectorFromTag2(tag, sectorIndex) >= 0 do
    sectors[sectorIndex].floorpic := flat;
  result := SCRIPT_CONTINUE;
end;

function CmdChangeCeiling: integer;
var
  tag: integer;
  flat: integer;
  sectorIndex: integer;
begin
  flat := R_FlatNumForName(ACStrings[ACS_Pop]);
  tag := ACS_Pop;
  sectorIndex := -1;
  while P_FindSectorFromTag2(tag, sectorIndex) >= 0 do
    sectors[sectorIndex].ceilingpic := flat;
  result := SCRIPT_CONTINUE;
end;

function CmdChangeCeilingDirect: integer;
var
  tag: integer;
  flat: integer;
  sectorIndex: integer;
begin
  tag := PCodePtr^;
  inc(PCodePtr);
  flat := R_FlatNumForName(ACStrings[PCodePtr^]);
  inc(PCodePtr);
  sectorIndex := -1;
  while P_FindSectorFromTag2(tag, sectorIndex) >= 0 do
    sectors[sectorIndex].ceilingpic := flat;
  result := SCRIPT_CONTINUE;
end;

function CmdRestart: integer;
begin
  PCodePtr := ACSInfo[ACScript.infoIndex].address;
  result := SCRIPT_CONTINUE;
end;

function CmdAndLogical: integer;
begin
  ACS_Push(IntVal((ACS_Pop <> 0) and (ACS_Pop <> 0)));
  result := SCRIPT_CONTINUE;
end;

function CmdOrLogical: integer;
begin
  ACS_Push(IntVal((ACS_Pop <> 0) or (ACS_Pop <> 0)));
  result := SCRIPT_CONTINUE;
end;

function CmdAndBitwise: integer;
begin
  ACS_Push(ACS_Pop and ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdOrBitwise: integer;
begin
  ACS_Push(ACS_Pop or ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdEorBitwise: integer;
begin
  ACS_Push(ACS_Pop xor ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdNegateLogical: integer;
begin
  ACS_Push(IntVal(ACS_Pop = 0));
  result := SCRIPT_CONTINUE;
end;

function CmdLShift: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(_SHL(ACS_Pop, operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdRShift: integer;
var
  operand2: integer;
begin
  operand2 := ACS_Pop;
  ACS_Push(_SHR(ACS_Pop, operand2));
  result := SCRIPT_CONTINUE;
end;

function CmdUnaryMinus: integer;
begin
  ACS_Push(-ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdIfNotGoto: integer;
begin
  if ACS_Pop <> 0 then
  begin
    inc(PCodePtr);
  end
  else
  begin
    PCodePtr := @ActionCodeBase[PCodePtr^];
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdLineSide: integer;
begin
  ACS_Push(ACScript.side);
  result := SCRIPT_CONTINUE;
end;

function CmdScriptWait: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := ACS_Pop;
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORSCRIPT;
  result := SCRIPT_STOP;
end;

function CmdScriptWaitDirect: integer;
begin
  ACSInfo[ACScript.infoIndex].waitValue := PCodePtr^;
  inc(PCodePtr);
  ACSInfo[ACScript.infoIndex].state := ASTE_WAITINGFORSCRIPT;
  result := SCRIPT_STOP;
end;

function CmdClearLineSpecial: integer;
begin
  if ACScript.line <> nil then
    ACScript.line.special := 0;

  result := SCRIPT_CONTINUE;
end;

function CmdCaseGoto: integer;
begin
  if ACS_Top = PCodePtr^ then // JVAL SOS
  begin
    inc(PCodePtr);
    PCodePtr := @ActionCodeBase[PCodePtr^];
    ACS_Drop;
  end
  else
  begin
    inc(PCodePtr); // JVAL SOS
    inc(PCodePtr);
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdBeginPrint: integer;
begin
  PrintBuffer := '';
  result := SCRIPT_CONTINUE;
end;

function CmdEndPrint: integer;
var
  player: Pplayer_t;
begin
  if (ACScript.activator <> nil) and (ACScript.activator.player <> nil) then
  begin
    player := ACScript.activator.player;
  end
  else
  begin
    player := @players[consoleplayer];
  end;
  P_SetMessage(player, PrintBuffer, true);
  result := SCRIPT_CONTINUE;
end;

function CmdEndPrintBold: integer;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if playeringame[i] then
    begin
      P_SetMessage(@players[i], PrintBuffer, true); // P_SetYellowMessage
    end;
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdPrintString: integer;
begin
  PrintBuffer := ACStrings.Strings[ACS_Pop];
  result := SCRIPT_CONTINUE;
end;

function CmdPrintNumber: integer;
begin
  printbuffer := itoa(ACS_Pop);
  result := SCRIPT_CONTINUE;
end;

function CmdPrintCharacter: integer;
begin
  PrintBuffer := PrintBuffer + Chr(ACS_Pop); // JVAL SOS
  result := SCRIPT_CONTINUE;
end;

function CmdPlayerCount: integer;
var
  i: integer;
  count: integer;
begin
  count := 0;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      inc(count);
  ACS_Push(count);
  result := SCRIPT_CONTINUE;
end;

function CmdGameType: integer;
var
  gametype: integer;
begin            // JVAL SOS
  if not netgame then
    gametype := GAME_SINGLE_PLAYER
  else if deathmatch <> 0 then
    gametype := GAME_NET_DEATHMATCH
  else
    gametype := GAME_NET_COOPERATIVE;
  ACS_Push(gametype);
  result := SCRIPT_CONTINUE;
end;

function CmdGameSkill: integer;
begin
  ACS_Push(Ord(gameskill));
  result := SCRIPT_CONTINUE;
end;

function CmdTimer: integer;
begin
  ACS_Push(leveltime);
  result := SCRIPT_CONTINUE;
end;

function CmdSectorSound: integer;
var
  volume: integer;
  mobj: Pmobj_t;
begin
  mobj := nil;
  if ACScript.line <> nil then
  begin
    mobj := Pmobj_t(@ACScript.line.frontsector.soundorg);
  end;
  volume := ACS_Pop;
  S_StartSoundAtVolume(mobj, S_GetSoundNumForName(ACStrings.Strings[ACS_Pop]), volume);
  result := SCRIPT_CONTINUE;
end;

function CmdThingSound: integer;
var
  tid: integer;
  sound: integer;
  volume: integer;
  mobj: Pmobj_t;
  searcher: integer;

  function _FindMobjFromTID: Pmobj_t;
  begin
    result := P_FindMobjFromTID(tid, @searcher);
    mobj := result;
  end;


begin
  volume := ACS_Pop;
  sound := S_GetSoundNumForName(ACStrings.Strings[ACS_Pop]);
  tid := ACS_Pop;
  searcher := -1;

  while _FindMobjFromTID <> nil do
    S_StartSoundAtVolume(mobj, sound, volume);

  result := SCRIPT_CONTINUE;
end;

function CmdAmbientSound: integer;
var
  volume: integer;
begin
  volume := ACS_Pop;
  S_StartSoundAtVolume(nil, S_GetSoundNumForName(ACStrings.Strings[ACS_Pop]), volume);
  result := SCRIPT_CONTINUE;
end;

function CmdSoundSequence: integer;
var
  mobj: Pmobj_t;
begin
  mobj := nil;
  if ACScript.line <> nil then
    mobj := Pmobj_t(@ACScript.line.frontsector.soundorg);
  S_StartSequenceName(mobj, ACStrings.Strings[ACS_Pop]);
  result := SCRIPT_CONTINUE;
end;

function CmdSetLineTexture: integer;
var
  line: Pline_t;
  lineTag: integer;
  side: integer;
  position: integer;
  texture: integer;
  searcher: integer;

  function _FindLine: Pline_t;
  begin
    result := P_FindLine(lineTag, @searcher);
    line := result;
  end;

begin
  texture := R_TextureNumForName(ACStrings.Strings[ACS_Pop]);
  position := ACS_Pop;
  side := ACS_Pop;
  lineTag := ACS_Pop;
  searcher := -1;
  while _FindLine <> nil do
  begin
    if position = TEXTURE_MIDDLE then
    begin
      sides[line.sidenum[side]].midtexture := texture;
    end
    else if position = TEXTURE_BOTTOM then
    begin
      sides[line.sidenum[side]].bottomtexture := texture;
    end
    else
    begin // TEXTURE_TOP
      sides[line.sidenum[side]].toptexture := texture;
    end;
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdSetLineBlocking: integer;
var
  line: Pline_t;
  lineTag: integer;
  blocking: integer;
  searcher: integer;

  function _FindLine: Pline_t;
  begin
    result := P_FindLine(lineTag, @searcher);
    line := result;
  end;

begin
  if ACS_Pop <> 0 then
    blocking := ML_BLOCKING
  else
    blocking := 0;
  lineTag := ACS_Pop;
  searcher := -1;
  while _FindLine <> nil do
  begin
    line.flags := (line.flags and not ML_BLOCKING) or blocking;
  end;
  result := SCRIPT_CONTINUE;
end;

function CmdSetLineSpecial: integer;
var
  line: Pline_t;
  lineTag: integer;
  special, arg1, arg2, arg3, arg4, arg5: integer;
  searcher: integer;

  function _FindLine: Pline_t;
  begin
    result := P_FindLine(lineTag, @searcher);
    line := result;
  end;

begin
  arg5 := ACS_Pop;
  arg4 := ACS_Pop;
  arg3 := ACS_Pop;
  arg2 := ACS_Pop;
  arg1 := ACS_Pop;
  special := ACS_Pop;
  lineTag := ACS_Pop;
  searcher := -1;
  while _FindLine <> nil do
  begin
    line.special := special;
    line.arg1 := arg1;
    line.arg2 := arg2;
    line.arg3 := arg3;
    line.arg4 := arg4;
    line.arg5 := arg5;
  end;
  result := SCRIPT_CONTINUE;
end;

procedure P_ACSInitCodeCmds;
var
  i: integer;
begin
  i := 0;
  PCodeCmds[i] := @CmdNOP;
  inc(i);
  PCodeCmds[i] := @CmdTerminate;
  inc(i);
  PCodeCmds[i] := @CmdSuspend;
  inc(i);
  PCodeCmds[i] := @CmdPushNumber;
  inc(i);
  PCodeCmds[i] := @CmdLSpec1;
  inc(i);
  PCodeCmds[i] := @CmdLSpec2;
  inc(i);
  PCodeCmds[i] := @CmdLSpec3;
  inc(i);
  PCodeCmds[i] := @CmdLSpec4;
  inc(i);
  PCodeCmds[i] := @CmdLSpec5;
  inc(i);
  PCodeCmds[i] := @CmdLSpec1Direct;
  inc(i);
  PCodeCmds[i] := @CmdLSpec2Direct;
  inc(i);
  PCodeCmds[i] := @CmdLSpec3Direct;
  inc(i);
  PCodeCmds[i] := @CmdLSpec4Direct;
  inc(i);
  PCodeCmds[i] := @CmdLSpec5Direct;
  inc(i);
  PCodeCmds[i] := @CmdAdd;
  inc(i);
  PCodeCmds[i] := @CmdSubtract;
  inc(i);
  PCodeCmds[i] := @CmdMultiply;
  inc(i);
  PCodeCmds[i] := @CmdDivide;
  inc(i);
  PCodeCmds[i] := @CmdModulus;
  inc(i);
  PCodeCmds[i] := @CmdEQ;
  inc(i);
  PCodeCmds[i] := @CmdNE;
  inc(i);
  PCodeCmds[i] := @CmdLT;
  inc(i);
  PCodeCmds[i] := @CmdGT;
  inc(i);
  PCodeCmds[i] := @CmdLE;
  inc(i);
  PCodeCmds[i] := @CmdGE;
  inc(i);
  PCodeCmds[i] := @CmdAssignScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdAssignMapVar;
  inc(i);
  PCodeCmds[i] := @CmdAssignWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdPushScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdPushMapVar;
  inc(i);
  PCodeCmds[i] := @CmdPushWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdAddScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdAddMapVar;
  inc(i);
  PCodeCmds[i] := @CmdAddWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdSubScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdSubMapVar;
  inc(i);
  PCodeCmds[i] := @CmdSubWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdMulScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdMulMapVar;
  inc(i);
  PCodeCmds[i] := @CmdMulWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdDivScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdDivMapVar;
  inc(i);
  PCodeCmds[i] := @CmdDivWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdModScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdModMapVar;
  inc(i);
  PCodeCmds[i] := @CmdModWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdIncScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdIncMapVar;
  inc(i);
  PCodeCmds[i] := @CmdIncWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdDecScriptVar;
  inc(i);
  PCodeCmds[i] := @CmdDecMapVar;
  inc(i);
  PCodeCmds[i] := @CmdDecWorldVar;
  inc(i);
  PCodeCmds[i] := @CmdGoto;
  inc(i);
  PCodeCmds[i] := @CmdIfGoto;
  inc(i);
  PCodeCmds[i] := @CmdDrop;
  inc(i);
  PCodeCmds[i] := @CmdDelay;
  inc(i);
  PCodeCmds[i] := @CmdDelayDirect;
  inc(i);
  PCodeCmds[i] := @CmdRandom;
  inc(i);
  PCodeCmds[i] := @CmdRandomDirect;
  inc(i);
  PCodeCmds[i] := @CmdThingCount;
  inc(i);
  PCodeCmds[i] := @CmdThingCountDirect;
  inc(i);
  PCodeCmds[i] := @CmdTagWait;
  inc(i);
  PCodeCmds[i] := @CmdTagWaitDirect;
  inc(i);
  PCodeCmds[i] := @CmdPolyWait;
  inc(i);
  PCodeCmds[i] := @CmdPolyWaitDirect;
  inc(i);
  PCodeCmds[i] := @CmdChangeFloor;
  inc(i);
  PCodeCmds[i] := @CmdChangeFloorDirect;
  inc(i);
  PCodeCmds[i] := @CmdChangeCeiling;
  inc(i);
  PCodeCmds[i] := @CmdChangeCeilingDirect;
  inc(i);
  PCodeCmds[i] := @CmdRestart;
  inc(i);
  PCodeCmds[i] := @CmdAndLogical;
  inc(i);
  PCodeCmds[i] := @CmdOrLogical;
  inc(i);
  PCodeCmds[i] := @CmdAndBitwise;
  inc(i);
  PCodeCmds[i] := @CmdOrBitwise;
  inc(i);
  PCodeCmds[i] := @CmdEorBitwise;
  inc(i);
  PCodeCmds[i] := @CmdNegateLogical;
  inc(i);
  PCodeCmds[i] := @CmdLShift;
  inc(i);
  PCodeCmds[i] := @CmdRShift;
  inc(i);
  PCodeCmds[i] := @CmdUnaryMinus;
  inc(i);
  PCodeCmds[i] := @CmdIfNotGoto;
  inc(i);
  PCodeCmds[i] := @CmdLineSide;
  inc(i);
  PCodeCmds[i] := @CmdScriptWait;
  inc(i);
  PCodeCmds[i] := @CmdScriptWaitDirect;
  inc(i);
  PCodeCmds[i] := @CmdClearLineSpecial;
  inc(i);
  PCodeCmds[i] := @CmdCaseGoto;
  inc(i);
  PCodeCmds[i] := @CmdBeginPrint;
  inc(i);
  PCodeCmds[i] := @CmdEndPrint;
  inc(i);
  PCodeCmds[i] := @CmdPrintString;
  inc(i);
  PCodeCmds[i] := @CmdPrintNumber;
  inc(i);
  PCodeCmds[i] := @CmdPrintCharacter;
  inc(i);
  PCodeCmds[i] := @CmdPlayerCount;
  inc(i);
  PCodeCmds[i] := @CmdGameType;
  inc(i);
  PCodeCmds[i] := @CmdGameSkill;
  inc(i);
  PCodeCmds[i] := @CmdTimer;
  inc(i);
  PCodeCmds[i] := @CmdSectorSound;
  inc(i);
  PCodeCmds[i] := @CmdAmbientSound;
  inc(i);
  PCodeCmds[i] := @CmdSoundSequence;
  inc(i);
  PCodeCmds[i] := @CmdSetLineTexture;
  inc(i);
  PCodeCmds[i] := @CmdSetLineBlocking;
  inc(i);
  PCodeCmds[i] := @CmdSetLineSpecial;
  inc(i);
  PCodeCmds[i] := @CmdThingSound;
  inc(i);
  PCodeCmds[i] := @CmdEndPrintBold;
end;


procedure P_ACSInit;
begin
  ACStrings := TDStringList.Create;
  P_ACSInitCodeCmds;
end;

procedure P_ACSShutDown;
begin
  ACStrings.Free;
end;

end.
