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
//  Rendering of moving objects, sprites.
//  Refresh of things, i.e. objects represented by sprites.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_things;

interface

uses
  d_delphi,
  doomdef,
  m_fixed,
  r_defs;

//const
// JVAL Note about visprites
// Now visprites allocated dinamycally using Zone memory
// (Original MAXVISSPRITES was 128)

var
  maxvissprite: integer;

{$IFNDEF OPENGL}
procedure R_DrawMaskedColumn(column: Pcolumn_t; baseclip: integer = -1);
procedure R_DrawMaskedColumn2(const mc2h: integer); // Use dc_source32

procedure R_SortVisSprites;
{$ENDIF}

procedure R_AddSprites(sec: Psector_t);
procedure R_InitSprites(namelist: PIntegerArray);
procedure R_ClearSprites;
{$IFNDEF OPENGL}
procedure R_DrawMasked;
{$ENDIF}
procedure R_DrawPlayer;

var
  pspritescale: fixed_t;
  pspriteiscale: fixed_t;
  pspritescalep: fixed_t;
  pspriteiscalep: fixed_t;
  pspriteyscale: fixed_t;

var
  mfloorclip: PSmallIntArray;
  mceilingclip: PSmallIntArray;
  spryscale: fixed_t;
  sprtopscreen: fixed_t;

// constant arrays             
//  used for psprite clipping and initializing clipping
  negonearray: packed array[0..MAXWIDTH - 1] of smallint;
  screenheightarray: packed array[0..MAXWIDTH - 1] of smallint;

// variables used to look up
//  and range check thing_t sprites patches
  sprites: Pspritedef_tArray;
  numspritespresent: integer;

procedure R_ShutDownSprites;

const
  MINZ = FRACUNIT * 4;
  BASEYCENTER = 100;

function R_NewVisSprite: Pvissprite_t;

var
  spritelights: PBytePArray;

var
  clipbot: packed array[0..MAXWIDTH - 1] of smallint;
  cliptop: packed array[0..MAXWIDTH - 1] of smallint;

implementation

uses
  tables,
  g_game,
  info_h,
  i_system,
{$IFDEF OPENGL}
  gl_render, // JVAL OPENGL
{$ENDIF}
  p_mobj_h,
  p_pspr,
  p_pspr_h,
  r_data,
  r_draw,
  r_main,
{$IFNDEF OPENGL}
  p_setup,
  r_segs,
  r_column,
  r_batchcolumn,
  r_trans8,
  r_hires,
  r_lights,
  r_bsp,
  r_voxels, // JVAL voxel support
  r_fake3d,
{$ENDIF}
  z_zone,
  w_wad,
  doomstat;

type
  maskdraw_t = record
    x1: integer;
    x2: integer;
    column: integer;
    topclip: integer;
    bottomclip: integer;
  end;
  Pmaskdraw_t = ^maskdraw_t;

//
// Sprite rotation 0 is facing the viewer,
//  rotation 1 is one angle turn CLOCKWISE around the axis.
// This is not the same as the angle,
//  which increases counter clockwise (protractor).
// There was a lot of stuff grabbed wrong, so I changed it...
//

//
// INITIALIZATION FUNCTIONS
//
const
  MAXFRAMES = 29; // Maximun number of frames in sprite

var
  sprtemp: array[0..MAXFRAMES - 1] of spriteframe_t;
  maxframe: integer;
  spritename: string;

//
// R_InstallSpriteLump
// Local function for R_InitSprites.
//
procedure R_InstallSpriteLump(lump: integer;
  frame: LongWord; rotation: LongWord; flipped: boolean);
var
  r: integer;
begin
  if (frame >= MAXFRAMES) or (rotation > 8) then
    I_DevError('R_InstallSpriteLump(): Bad frame characters in lump %d (frame = %d, rotation = %d)'#13#10, [lump, frame, rotation]);

  if integer(frame) > maxframe then
    maxframe := frame;

  if rotation = 0 then
  begin
    // the lump should be used for all rotations
    if sprtemp[frame].rotate = 0 then
      I_Warning('R_InitSprites(): Sprite %s frame %s has multip rot=0 lump'#13#10,
        [spritename, Chr(Ord('A') + frame)]);

    if sprtemp[frame].rotate = 1 then
      I_Warning('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump'#13#10,
        [spritename, Chr(Ord('A') + frame)]);

    sprtemp[frame].rotate := 0;
    for r := 0 to 7 do
    begin
      sprtemp[frame].lump[r] := lump - firstspritelump;
      sprtemp[frame].flip[r] := flipped;
    end;
    exit;
  end;

  // the lump is only used for one rotation
  if sprtemp[frame].rotate = 0 then
    I_Warning('R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump'#13#10,
      [spritename, Chr(Ord('A') + frame)]);

  sprtemp[frame].rotate := 1;

  // make 0 based
  dec(rotation);
  if sprtemp[frame].lump[rotation] <> -1 then
    I_DevWarning('R_InitSprites(): Sprite %s : %s : %s has two lumps mapped to it'#13#10,
      [spritename, Chr(Ord('A') + frame), Chr(Ord('1') + rotation)]);

  sprtemp[frame].lump[rotation] := lump - firstspritelump;
  sprtemp[frame].flip[rotation] := flipped;
end;

//
// R_InitSpriteDefs
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant.
// Only called at startup.
//
// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
//
procedure R_InitSpriteDefs(namelist: PIntegerArray);

  procedure sprtempreset;
  var
    i: integer;
    j: integer;
  begin
    for i := 0 to MAXFRAMES - 1 do
    begin
      sprtemp[i].rotate := -1;
      for j := 0 to 7 do
      begin
        sprtemp[i].lump[j] := -1;
        sprtemp[i].flip[j] := false;
      end;
    end;
  end;

var
  i: integer;
  l: integer;
  intname: integer;
  frame: integer;
  rotation: integer;
  start: integer;
  finish: integer;
  patched: integer;
begin
  // count the number of sprite names

  numspritespresent := 0;
  while namelist[numspritespresent] <> 0 do
    inc(numspritespresent);

  if numspritespresent = 0 then
    exit;

  sprites := Z_Malloc(numspritespresent * SizeOf(spritedef_t), PU_STATIC, nil);
  ZeroMemory(sprites, numspritespresent * SizeOf(spritedef_t));

  start := firstspritelump - 1;
  finish := lastspritelump + 1;

  // scan all the lump names for each of the names,
  //  noting the highest frame letter.
  // Just compare 4 characters as ints
  for i := 0 to numspritespresent - 1 do
  begin
    spritename := Chr(namelist[i]) + Chr(namelist[i] shr 8) + Chr(namelist[i] shr 16) + Chr(namelist[i] shr 24);

    sprtempreset;

    maxframe := -1;
    intname := namelist[i];

    // scan the lumps,
    //  filling in the frames for whatever is found
    for l := start + 1 to finish - 1 do
    begin
      if spritepresent[l - firstspritelump] then

      if lumpinfo[l].v1 = intname then // JVAL
      begin
        frame := Ord(lumpinfo[l].name[4]) - Ord('A');
        rotation := Ord(lumpinfo[l].name[5]) - Ord('0');

        if modifiedgame then
          patched := W_GetNumForName(lumpinfo[l].name)
        else
          patched := l;

        R_InstallSpriteLump(patched, frame, rotation, false);

        if lumpinfo[l].name[6] <> #0 then
        begin
          frame := Ord(lumpinfo[l].name[6]) - Ord('A');
          rotation := Ord(lumpinfo[l].name[7]) - Ord('0');
          R_InstallSpriteLump(l, frame, rotation, true);
        end;
      end;
    end;

    // check the frames that were found for completeness
    if maxframe = -1 then
    begin
      sprites[i].numframes := 0;
      continue;
    end;

    inc(maxframe);

    for frame := 0 to maxframe - 1 do
    begin
      case sprtemp[frame].rotate of
        -1:
          begin
            // no rotations were found for that frame at all
            // JVAL: Changed from I_Error to I_Warning
            I_Warning('R_InitSprites(): No patches found for %s frame %s'#13#10,
              [spritename, Chr(frame + Ord('A'))]);
          end;
         0:
          begin
            // only the first rotation is needed
          end;
         1:
          begin
            // must have all 8 frames
            for rotation := 0 to 7 do
              if sprtemp[frame].lump[rotation] = -1 then
                I_Error('R_InitSprites(): Sprite %s frame %s is missing rotations',
                  [spritename, Chr(frame + Ord('A'))]);
          end;
      end;
    end;

    // allocate space for the frames present and copy sprtemp to it
    sprites[i].numframes := maxframe;
    sprites[i].spriteframes :=
      Z_Malloc(maxframe * SizeOf(spriteframe_t), PU_STATIC, nil);
    memcpy(sprites[i].spriteframes, @sprtemp, maxframe * SizeOf(spriteframe_t));
  end;
end;

//
// GAME FUNCTIONS
//
var
  vissprites: visspritebuffer_p;
  vissprite_p: integer;
  visspritessize: Integer = 0;

//
// R_InitSprites
// Called at program start.
//
procedure R_InitSprites(namelist: PIntegerArray);
var
  i: integer;
begin
  for i := 0 to SCREENWIDTH - 1 do
    negonearray[i] := -1;

  R_InitSpriteDefs(namelist);
end;

//
// R_ClearSprites
// Called at frame start.
//
procedure R_ClearSprites;
begin
  vissprite_p := 0;
end;

//
// R_NewVisSprite
//
// JVAL Now we allocate a new visprite dynamically
//
function R_NewVisSprite: Pvissprite_t;
begin
  if vissprite_p = visspritessize then
  begin
    realloc(pointer(vissprites), visspritessize * SizeOf(Pvissprite_t), (128 + visspritessize) * SizeOf(Pvissprite_t));
    visspritessize := visspritessize + 128;
  end;
  if vissprite_p > maxvissprite then
  begin
    maxvissprite := vissprite_p;
    vissprites[vissprite_p] := Z_Malloc(SizeOf(vissprite_t), PU_LEVEL, nil);
  end;
  result := vissprites[vissprite_p];
  inc(vissprite_p);
end;

procedure R_ShutDownSprites;
begin
  realloc(pointer(vissprites), visspritessize * SizeOf(Pvissprite_t), 0);
end;

{$IFNDEF OPENGL}
//
// R_DrawMaskedColumn
// Used for sprites and masked mid textures.
// Masked means: partly transparent, i.e. stored
//  in posts/runs of opaque pixels.
//

procedure R_DrawMaskedColumn(column: Pcolumn_t; baseclip: integer = -1);
var
  topscreen: integer;
  bottomscreen: integer;
  basetexturemid: fixed_t;
  fc_x, cc_x: integer;
begin
  basetexturemid := dc_texturemid;

  fc_x := mfloorclip[dc_x];
  cc_x := mceilingclip[dc_x];

  if baseclip <> -1 then
  begin
    while column.topdelta <> $ff do
    begin
      // calculate unclipped screen coordinates
      // for post
      topscreen := sprtopscreen + spryscale * column.topdelta;
      bottomscreen := topscreen + spryscale * column.length;

      dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
      dc_yh := FixedInt(bottomscreen - 1);

      if dc_yh >= fc_x then
        dc_yh := fc_x - 1;
      if dc_yl <= cc_x then
        dc_yl := cc_x + 1;

      if dc_yh >= baseclip then
        dc_yh := baseclip;

      if dc_yl <= dc_yh then
      begin
        dc_source := PByteArray(integer(column) + 3);
        dc_texturemid := basetexturemid - (column.topdelta * FRACUNIT);
        // Drawn by either R_DrawColumn
        //  or (SHADOW) R_DrawFuzzColumn
        //  or R_DrawColumnAverage
        //  or R_DrawTranslatedColumn
        colfunc;
      end;
      column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end
  else
  begin
    while column.topdelta <> $ff do
    begin
      // calculate unclipped screen coordinates
      // for post
      topscreen := sprtopscreen + spryscale * column.topdelta;
      bottomscreen := topscreen + spryscale * column.length;

      dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
      dc_yh := FixedInt(bottomscreen - 1);

      if dc_yh >= fc_x then
        dc_yh := fc_x - 1;
      if dc_yl <= cc_x then
        dc_yl := cc_x + 1;

      if dc_yl <= dc_yh then
      begin
        dc_source := PByteArray(integer(column) + 3);
        dc_texturemid := basetexturemid - (column.topdelta * FRACUNIT);
        // Drawn by either R_DrawColumn
        //  or (SHADOW) R_DrawFuzzColumn
        //  or R_DrawColumnAverage
        //  or R_DrawTranslatedColumn
        colfunc;
      end;
      column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end;

  dc_texturemid := basetexturemid;
end;

// For Walls only
procedure R_DrawMaskedColumn2(const mc2h: integer); // Use dc_source32
var
  topscreen: integer;
  bottomscreen: integer;
  basetexturemid: fixed_t;
  fc_x, cc_x: integer;
begin
  basetexturemid := dc_texturemid;

  fc_x := mfloorclip[dc_x];
  cc_x := mceilingclip[dc_x];

  topscreen := sprtopscreen;
  bottomscreen := topscreen + spryscale * mc2h;

  dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
  dc_yh := FixedInt(bottomscreen - 1);

  if dc_yh >= fc_x then
    dc_yh := fc_x - 1;
  if dc_yl <= cc_x then
    dc_yl := cc_x + 1;

  if dc_yl <= dc_yh then
  begin
      // Drawn by either R_DrawColumn
      //  or (SHADOW) R_DrawFuzzColumn
      //  or R_DrawColumnAverage
      //  or R_DrawTranslatedColumn
    colfunc;
  end;

  dc_texturemid := basetexturemid;
end;

// JVAL: batch column drawing
procedure R_DrawMaskedColumn_Batch(column: Pcolumn_t; baseclip: integer = -1);
var
  topscreen: integer;
  bottomscreen: integer;
  basetexturemid: fixed_t;
  fc_x, cc_x: integer;
begin
  basetexturemid := dc_texturemid;

  fc_x := mfloorclip[dc_x];
  cc_x := mceilingclip[dc_x];

  if baseclip <> -1 then
  begin
    while column.topdelta <> $ff do
    begin
      // calculate unclipped screen coordinates
      // for post
      topscreen := sprtopscreen + spryscale * column.topdelta;
      bottomscreen := topscreen + spryscale * column.length;

      dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
      dc_yh := FixedInt(bottomscreen - 1);

      if dc_yh >= fc_x then
        dc_yh := fc_x - 1;
      if dc_yl <= cc_x then
        dc_yl := cc_x + 1;

      if dc_yh >= baseclip then
        dc_yh := baseclip;

      if dc_yl <= dc_yh then
      begin
        dc_source := PByteArray(integer(column) + 3);
        dc_texturemid := basetexturemid - (column.topdelta * FRACUNIT);
        // Drawn by either R_DrawColumn
        //  or (SHADOW) R_DrawFuzzColumn
        //  or R_DrawColumnAverage
        //  or R_DrawTranslatedColumn
        batchcolfunc;
      end;
      column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end
  else
  begin
    while column.topdelta <> $ff do
    begin
      // calculate unclipped screen coordinates
      // for post
      topscreen := sprtopscreen + spryscale * column.topdelta;
      bottomscreen := topscreen + spryscale * column.length;

      dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
      dc_yh := FixedInt(bottomscreen - 1);

      if dc_yh >= fc_x then
        dc_yh := fc_x - 1;
      if dc_yl <= cc_x then
        dc_yl := cc_x + 1;

      if dc_yl <= dc_yh then
      begin
        dc_source := PByteArray(integer(column) + 3);
        dc_texturemid := basetexturemid - (column.topdelta * FRACUNIT);
        // Drawn by either R_DrawColumn
        //  or (SHADOW) R_DrawFuzzColumn
        //  or R_DrawColumnAverage
        //  or R_DrawTranslatedColumn
        batchcolfunc;
      end;
      column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end;

  dc_texturemid := basetexturemid;
end;

// R_DrawVisSprite
//  mfloorclip and mceilingclip should also be set.
//
procedure R_DrawVisSprite(vis: Pvissprite_t; const playerweapon: boolean = false);
var
  column: Pcolumn_t;
  texturecolumn: integer;
  checkcolumn: integer;
  frac: fixed_t;
  patch: Ppatch_t;
  xiscale: integer;
  baseclip: fixed_t;
  last_dc_x: integer;
  last_texturecolumn: integer;
  last_fc_x: smallint;
  last_cc_x: smallint;
  save_dc_x: integer;
begin
  patch := W_CacheLumpNum2(vis.patch + firstspritelump, PU_STATIC);

  dc_colormap := vis.colormap;

  if videomode = vm32bit then
  begin
    dc_colormap32 := R_GetColormap32(dc_colormap);
    if fixedcolormapnum = INVERSECOLORMAP then
      dc_lightlevel := -1
    else
      dc_lightlevel := R_GetColormapLightLevel(dc_colormap);
  end;

  if dc_colormap = nil then
  begin
    // NULL colormap = shadow draw
    colfunc := fuzzcolfunc;
    batchcolfunc := batchfuzzcolfunc;
  end
  else if vis.mobjflags and MF_TRANSLATION <> 0 then
  begin
    colfunc := transcolfunc;
    batchcolfunc := batchtranscolfunc;
    dc_translation := PByteArray(integer(translationtables) - 256 +
      (_SHR((vis.mobjflags and MF_TRANSLATION), (MF_TRANSSHIFT - 8))));
  end
  else if usetransparentsprites and (vis.mobjflags_ex and MF_EX_TRANSPARENT <> 0) then
  begin
    colfunc := averagecolfunc;
    batchcolfunc := batchtaveragecolfunc;
  end
  else if usetransparentsprites and (vis.mo <> nil) and (vis.mo.renderstyle = mrs_translucent) then
  begin
    dc_alpha := vis.mo.alpha;
    curtrans8table := R_GetTransparency8table(dc_alpha);
    colfunc := alphacolfunc;
    batchcolfunc := batchtalphacolfunc;
  end
  else
  begin
    colfunc := maskedcolfunc;
    batchcolfunc := basebatchcolfunc;
  end;

  dc_iscale := FixedDivEx(FRACUNIT, vis.scale);
  dc_texturemid := vis.texturemid;
  frac := vis.startfrac;
  spryscale := vis.scale;
  sprtopscreen := centeryfrac - FixedMul(dc_texturemid, spryscale);

  if (vis.footclip <> 0) and (not playerweapon) then
    baseclip := FixedInt((sprtopscreen + FixedMul(patch.height * FRACUNIT, spryscale) - FixedMul(vis.footclip,  spryscale)))
  else
    baseclip := -1;

// JVAL: batch column drawing
  xiscale := vis.xiscale;
  dc_x := vis.x1;

  if (xiscale > FRACUNIT div 2) or (not optimizedthingsrendering) or (not Assigned(batchcolfunc)) then
  begin
    while dc_x <= vis.x2 do
    begin
      texturecolumn := LongWord(frac) shr FRACBITS;

      column := Pcolumn_t(integer(patch) + patch.columnofs[texturecolumn]);
      R_DrawMaskedColumn(column, baseclip);
      frac := frac + xiscale;
      inc(dc_x);
    end;
  end
  else
  begin
    last_dc_x := dc_x;
    last_texturecolumn := LongWord(frac) shr FRACBITS;
    last_fc_x := mfloorclip[last_dc_x];
    last_cc_x := mceilingclip[last_dc_x];
    while dc_x <= vis.x2 do
    begin
      checkcolumn := LongWord(frac) shr FRACBITS;
      if (last_fc_x <> mfloorclip[dc_x]) or
         (last_cc_x <> mceilingclip[dc_x]) or
         (last_texturecolumn <> checkcolumn) then
      begin
        num_batch_columns := dc_x - last_dc_x;
        texturecolumn := last_texturecolumn;
        last_texturecolumn := checkcolumn;
        last_fc_x := mfloorclip[dc_x];
        last_cc_x := mceilingclip[dc_x];
        save_dc_x := last_dc_x;
        last_dc_x := dc_x;
        column := Pcolumn_t(integer(patch) + patch.columnofs[texturecolumn]);
        dc_x := save_dc_x;
        if num_batch_columns > 1 then
        begin
          R_DrawMaskedColumn_Batch(column, baseclip);
        end
        else
          R_DrawMaskedColumn(column, baseclip);
        dc_x := last_dc_x;
      end;
      frac := frac + xiscale;
      inc(dc_x);
    end;
    num_batch_columns := dc_x - last_dc_x;
    if num_batch_columns > 0 then
    begin
      column := Pcolumn_t(integer(patch) + patch.columnofs[last_texturecolumn]);
      dc_x := last_dc_x;
      if num_batch_columns > 1 then
      begin
        R_DrawMaskedColumn_Batch(column, baseclip);
      end
      else
        R_DrawMaskedColumn(column, baseclip);
    end;
  end;

  Z_ChangeTag(patch, PU_CACHE);
end;


var
  ltopdelta: integer;
  llength: integer;

//
// R_DrawVisSpriteLight
// Used for sprites that emits light
//

procedure R_DrawVisSpriteLight(vis: Pvissprite_t; x1: integer; x2: integer);
var
  texturecolumn: integer;
  frac: fixed_t;
  fracstep: fixed_t;
  patch: Ppatch_t;
  topscreen: integer;
  bottomscreen: integer;
  basetexturemid: fixed_t;
  last_dc_x: integer;
  save_dc_x: integer;
  last_texturecolumn: integer;
  last_floorclip, last_ceilingclip: SmallInt;
  checkcolumn: integer;
begin
  patch := W_CacheLumpNum2(vis.patch + firstspritelump, PU_STATIC);

  frac := vis.startfrac * LIGHTBOOSTSIZE div patch.width;
  fracstep := vis.xiscale * (LIGHTBOOSTSIZE shr 1) div patch.width;
  spryscale := vis.scale * patch.height div (LIGHTBOOSTSIZE shr 1);
  dc_iscale := FixedDivEx(FRACUNIT, spryscale);
  sprtopscreen := centeryfrac - FixedMul(vis.texturemid2, vis.scale);

  if fixedcolormapnum = INVERSECOLORMAP then // JVAL: if in invulnerability mode use white color
  begin
    lightcolfunc := whitelightcolfunc;
    batchlightcolfunc := batchwhitelightcolfunc;
  end
  else if vis.mobjflags_ex and MF_EX_LIGHT <> 0 then
  begin
    if vis.mobjflags_ex and MF_EX_REDLIGHT <> 0 then
    begin
      lightcolfunc := redlightcolfunc;
      batchlightcolfunc := batchredlightcolfunc;
    end
    else if vis.mobjflags_ex and MF_EX_GREENLIGHT <> 0 then
    begin
      lightcolfunc := greenlightcolfunc;
      batchlightcolfunc := batchgreenlightcolfunc;
    end
    else if vis.mobjflags_ex and MF_EX_BLUELIGHT <> 0 then
    begin
      lightcolfunc := bluelightcolfunc;
      batchlightcolfunc := batchbluelightcolfunc;
    end
    else if vis.mobjflags_ex and MF_EX_YELLOWLIGHT <> 0 then
    begin
      lightcolfunc := yellowlightcolfunc;
      batchlightcolfunc := batchyellowlightcolfunc;
    end
    else
    begin
      lightcolfunc := whitelightcolfunc;
      batchlightcolfunc := batchwhitelightcolfunc;
    end;
  end
  else
  begin
    lightcolfunc := whitelightcolfunc;
    batchlightcolfunc := batchwhitelightcolfunc;
  end;


  dc_x := x1;
  if (fracstep > FRACUNIT div 2) or (not optimizedthingsrendering) or (not Assigned(batchlightcolfunc)) then
  begin
    while dc_x <= x2 do
    begin
      texturecolumn := LongWord(frac) shr FRACBITS;
      ltopdelta := lighboostlookup[texturecolumn].topdelta;
      llength := lighboostlookup[texturecolumn].length;
      dc_source32 := @lightboost[texturecolumn * LIGHTBOOSTSIZE + ltopdelta];

      basetexturemid := dc_texturemid;

      topscreen := sprtopscreen + spryscale * ltopdelta;
      bottomscreen := topscreen + spryscale * llength;

      dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
      dc_yh := FixedInt(bottomscreen - 1);
      dc_texturemid := (centery - dc_yl) * dc_iscale;

      if dc_yh >= mfloorclip[dc_x] then
        dc_yh := mfloorclip[dc_x] - 1;
      if dc_yl <= mceilingclip[dc_x] then
        dc_yl := mceilingclip[dc_x] + 1;

        if frac < 256 * FRACUNIT then
      if dc_yl <= dc_yh then
        lightcolfunc;

      dc_texturemid := basetexturemid;

      frac := frac + fracstep;
      inc(dc_x);
    end;
  end
  else
  begin
    last_dc_x := dc_x;
    last_texturecolumn := LongWord(frac) shr FRACBITS;
    last_floorclip := mfloorclip[dc_x];
    last_ceilingclip := mceilingclip[dc_x];
    while dc_x <= x2 do
    begin
      checkcolumn := LongWord(frac) shr FRACBITS;
      if (last_floorclip <> mfloorclip[dc_x]) or
         (last_ceilingclip <> mceilingclip[dc_x]) or
         (last_texturecolumn <> checkcolumn) or
         (dc_x = x2) then
      begin
        num_batch_columns := dc_x - last_dc_x;
        texturecolumn := last_texturecolumn;
        last_texturecolumn := checkcolumn;
        last_floorclip := mfloorclip[dc_x];
        last_ceilingclip := mceilingclip[dc_x];
        save_dc_x := last_dc_x;
        last_dc_x := dc_x;

        ltopdelta := lighboostlookup[texturecolumn].topdelta;
        llength := lighboostlookup[texturecolumn].length;
        dc_source32 := @lightboost[texturecolumn * LIGHTBOOSTSIZE + ltopdelta];

        basetexturemid := dc_texturemid;

        topscreen := sprtopscreen + spryscale * ltopdelta;
        bottomscreen := topscreen + spryscale * llength;

        dc_yl := FixedInt(topscreen + (FRACUNIT - 1));
        dc_yh := FixedInt(bottomscreen - 1);
        dc_texturemid := (centery - dc_yl) * dc_iscale;

        if dc_yh >= mfloorclip[dc_x] then
          dc_yh := mfloorclip[dc_x] - 1;
        if dc_yl <= mceilingclip[dc_x] then
          dc_yl := mceilingclip[dc_x] + 1;

        if frac < 256 * FRACUNIT then
        if dc_yl <= dc_yh then
        begin
          dc_x := save_dc_x;
          if num_batch_columns > 1 then
            batchlightcolfunc
          else
            lightcolfunc;
          dc_x := last_dc_x;
        end;

        dc_texturemid := basetexturemid;
      end;

      frac := frac + fracstep;
      inc(dc_x);
    end;
  end;

  Z_ChangeTag(patch, PU_CACHE);
end;
{$ENDIF}

//
//
// R_ProjectSprite
// Generates a vissprite for a thing
//  if it might be visible.
//
procedure R_ProjectSprite(thing: Pmobj_t);
var
  tr_x: fixed_t;
  tr_y: fixed_t;
  gxt: fixed_t;
  gyt: fixed_t;
  tx: fixed_t;
  tz: fixed_t;
  xscale: fixed_t;
  x1: integer;
  x2: integer;
  sprdef: Pspritedef_t;
  sprframe: Pspriteframe_t;
  lump: integer;
  rot: LongWord;
  flip: boolean;
  index: integer;
  vis: Pvissprite_t;
  ang: angle_t;
{$IFDEF OPENGL}
  checksides: boolean;
{$ELSE}
  iscale: fixed_t;
  heightsec: integer;
  plheightsec: integer;
  gzt: integer;
  voxelflag: integer;
  vx1, vx2: integer;
{$ENDIF}
  soffset, swidth: fixed_t;
begin
  if (thing.player = viewplayer) and not chasecamera then
    exit;

  // Never make a vissprite when MF2_DONTDRAW is flagged.
  if thing.flags2_ex and MF2_EX_DONTDRAW <> 0 then
    exit;

  // transform the origin point
  tr_x := thing.x - viewx;
  tr_y := thing.y - viewy;

  gxt := FixedMul(tr_x, viewcos);
  gyt := -FixedMul(tr_y, viewsin);

  tz := gxt - gyt;

{$IFNDEF OPENGL}
  // JVAL voxel support
  voxelflag := 0;
  if r_drawvoxels then
    if thing.state.voxels <> nil then
      voxelflag := 1;
{$ENDIF}

  // thing is behind view plane?
  {$IFDEF OPENGL}
  checksides := (absviewpitch < 35) and (thing.state.dlights = nil) and (thing.state.models = nil) and (thing.state.voxels = nil);

  if checksides then
  {$ENDIF}
    if tz < MINZ {$IFNDEF OPENGL} - 128 * FRACUNIT * voxelflag {$ENDIF} then
      exit;

  xscale := FixedDiv(projection, tz);
  if xscale <= 0 then
    exit;

  gxt := -FixedMul(tr_x, viewsin);
  gyt := FixedMul(tr_y, viewcos);
  tx := -(gyt + gxt);

  // too far off the side?
  {$IFDEF OPENGL}
  if checksides then
  {$ELSE}
//  if voxelflag = 0 then
  {$ENDIF}
    if abs(tx) > 4 * tz then
      exit;

  // decide which patch to use for sprite relative to player
  sprdef := @sprites[thing.sprite];
  sprframe := @sprdef.spriteframes[thing.frame and FF_FRAMEMASK];

  if sprframe = nil then
  begin
    I_DevError('R_ProjectSprite(): Sprite for "%s" is NULL.'#13#10, [thing.info.name]);
    exit;
  end;

  if sprframe.rotate <> 0 then
  begin
    // choose a different rotation based on player view
    ang := R_PointToAngle(thing.x, thing.y);
    {$IFDEF FPC}
    rot := _SHRW(ang - thing.angle + LongWord(ANG45 div 2) * 9), 29);
    {$ELSE}
    rot := (ang - thing.angle + LongWord(ANG45 div 2) * 9) shr 29;
    {$ENDIF}
    lump := sprframe.lump[rot];
    flip := sprframe.flip[rot];
  end
  else
  begin
    // use single rotation for all views
    lump := sprframe.lump[0];
    flip := sprframe.flip[0];
  end;

  soffset := spriteoffset[lump];
  tx := tx - soffset;
  x1 := FixedInt(centerxfrac + FixedMul(tx, xscale));
  {$IFNDEF OPENGL}
  vx1 := FixedInt(centerxfrac + FixedMul(tx + soffset - thing.state.voxelradius, xscale));
  {$ENDIF}

  // off the right side?
  {$IFDEF OPENGL}
  if checksides then
  {$ELSE}
  if voxelflag = 0 then
  {$ENDIF}
    if x1 > viewwidth then
      exit;

  swidth := spritewidth[lump];
  tx := tx + swidth;
  x2 := FixedInt(centerxfrac + FixedMul(tx, xscale)) - 1;
  {$IFNDEF OPENGL}
  vx2 := FixedInt(centerxfrac + FixedMul(tx - swidth + 2 * thing.state.voxelradius, xscale));
  {$ENDIF}

  // off the left side
  {$IFDEF OPENGL}
  if checksides then
  {$ELSE}
  if voxelflag = 0 then
  {$ENDIF}
    if x2 < 0 then
      exit;

  {$IFNDEF OPENGL}
{  if voxelflag = 1 then
    gzt := thing.z
  else          }
    gzt := thing.z + spritetopoffset[lump];
  heightsec := Psubsector_t(thing.subsector).sector.heightsec;

  if heightsec <> -1 then   // only clip things which are in special sectors
  begin
    plheightsec := Psubsector_t(viewplayer.mo.subsector).sector.heightsec;
    if plheightsec <> -1 then
    begin
      if viewz < sectors[plheightsec].floorheight then
      begin
        if thing.z >= sectors[heightsec].floorheight then
          Exit;
      end
      else
      begin
        if gzt < sectors[heightsec].floorheight then
          Exit;
      end;

      if viewz > sectors[plheightsec].ceilingheight then
      begin
        if (gzt < sectors[heightsec].ceilingheight) and
           (viewz >= sectors[heightsec].ceilingheight) then
           Exit;
      end
      else
      begin
        if thing.z >= sectors[heightsec].ceilingheight then
           Exit;
      end;
    end;
  end;
  {$ENDIF}

  // store information in a vissprite
  vis := R_NewVisSprite;
  vis.mobjflags := thing.flags;
  vis.mobjflags_ex := thing.flags_ex or thing.state.flags_ex; // JVAL: extended flags passed to vis
  vis.mobjflags2_ex := thing.flags2_ex; // JVAL: extended flags passed to vis
  vis.mo := thing;
  vis._type := thing._type;
  vis.scale := FixedDiv(projectiony, tz); // JVAL For correct aspect
  {$IFNDEF OPENGL}
  vis.heightsec := heightsec;
  vis.voxelflag := voxelflag;  // JVAL voxel support
  vis.gx := thing.x;
  vis.gy := thing.y;
  vis.gz := thing.z;
  vis.gzt := gzt;
  // foot clipping
  vis.footclip := thing.floorclip;
  vis.texturemid := vis.gzt - viewz - vis.footclip * FRACUNIT;
  vis.texturemid2 := thing.z + 2 * spritetopoffset[lump] - viewz;
  if x1 <= 0 then
    vis.x1 := 0
  else
    vis.x1 := x1;
  if x2 >= viewwidth then
    vis.x2 := viewwidth - 1
  else
    vis.x2 := x2;
  if vx1 <= 0 then
    vis.vx1 := 0
  else
    vis.vx1:= vx1;
  if vx2 >= viewwidth then
    vis.vx2 := viewwidth - 1
  else
    vis.vx2 := vx2;
  iscale := FixedDiv(FRACUNIT, xscale);

  if flip then
  begin
    vis.startfrac := swidth - 1;
    vis.xiscale := -iscale;
  end
  else
  begin
    vis.startfrac := 0;
    vis.xiscale := iscale;
  end;
{$ENDIF}
{$IFDEF OPENGL}
  vis.flip := flip;
{$ENDIF}

{$IFNDEF OPENGL}
  if vis.x1 > x1 then
    vis.startfrac := vis.startfrac + vis.xiscale * (vis.x1 - x1);
{$ENDIF}
  vis.patch := lump;

  // get light level
  if thing.flags and MF_SHADOW <> 0 then
  begin
    // shadow draw
    vis.colormap := nil;
  end
  else if fixedcolormap <> nil then
  begin
    // fixed map
    vis.colormap := fixedcolormap;
  end
  else if thing.frame and FF_FULLBRIGHT <> 0 then
  begin
    // full bright
    vis.colormap := colormaps;
  end
  else
  begin
    // diminished light
    index := _SHR(xscale, LIGHTSCALESHIFT);

    if index >= MAXLIGHTSCALE then
      index := MAXLIGHTSCALE - 1
    else if index < 0 then
      index := 0;

    vis.colormap := spritelights[index];
  end;

{$IFDEF OPENGL}
  gld_AddSprite(vis); // JVAL: OPENGL
{$ENDIF}
end;

//
// R_AddSprites
// During BSP traversal, this adds sprites by sector.
//
procedure R_AddSprites(sec: Psector_t);
var
  thing: Pmobj_t;
  lightnum: integer;
begin
  // BSP is traversed by subsector.
  // A sector might have been split into several
  // subsectors during BSP building.
  // Thus we check whether its already added.
  if sec.validcount = validcount then
    exit;

  // Well, now it will be done.
  sec.validcount := validcount;

  lightnum := _SHR(sec.lightlevel, LIGHTSEGSHIFT) + extralight;

  if lightnum <= 0 then
    spritelights := @scalelight[0]
  else if lightnum >= LIGHTLEVELS then
    spritelights := @scalelight[LIGHTLEVELS - 1]
  else
    spritelights := @scalelight[lightnum];

  // Handle all things in sector.
  thing := sec.thinglist;
  while thing <> nil do
  begin
    R_ProjectSprite(thing);
    thing := thing.snext;
  end;
end;

//
// R_DrawPSprite
//
procedure R_DrawPSprite(psp: Ppspdef_t);
var
  tx: fixed_t;
  x1: integer;
  x2: integer;
  sprdef: Pspritedef_t;
  sprframe: Pspriteframe_t;
  lump: integer;
{$IFNDEF OPENGL}
  flip: boolean;
{$ENDIF}
  vis: Pvissprite_t;
  avis: vissprite_t;
{$IFDEF OPENGL}
  lightlevel: integer; // JVAL OPENGL
{$ENDIF}
begin
  // decide which patch to use

  sprdef := @sprites[Ord(psp.state.sprite)];

  sprframe := @sprdef.spriteframes[psp.state.frame and FF_FRAMEMASK];

  lump := sprframe.lump[0];
{$IFNDEF OPENGL}
  flip := sprframe.flip[0];
{$ENDIF}
  // calculate edges of the shape
  tx := psp.sx - 160 * FRACUNIT;

  tx := tx - spriteoffset[lump];
  x1 := FixedInt(centerxfrac + centerxshift + FixedMul(tx, pspritescalep));

  // off the right side
  if x1 > viewwidth then
    exit;

  tx := tx + spritewidth[lump];
  x2 := FixedInt(centerxfrac + centerxshift + FixedMul(tx, pspritescalep)) - 1;

  // off the left side
  if x2 < 0 then
    exit;

  // store information in a vissprite
  vis := @avis;
  vis.mobjflags := 0;
  vis.mobjflags_ex := 0;
  vis.mobjflags2_ex := 0;
  vis.mo := viewplayer.mo;
  vis._type := Ord(MT_PLAYER);

  vis.texturemid := (BASEYCENTER * FRACUNIT) + FRACUNIT div 2 - (psp.sy - spritetopoffset[lump]);
  if x1 < 0 then
    vis.x1 := 0
  else
    vis.x1 := x1;
  if x2 >= viewwidth then
    vis.x2 := viewwidth - 1
  else
    vis.x2 := x2;

  vis.scale := pspriteyscale;

{$IFNDEF OPENGL}
  if flip then
  begin
    vis.xiscale := -pspriteiscalep;
    vis.startfrac := spritewidth[lump] - 1;
  end
  else
  begin
    vis.xiscale := pspriteiscalep;
    vis.startfrac := 0;
  end;
  if vis.x1 > x1 then
    vis.startfrac := vis.startfrac + vis.xiscale * (vis.x1 - x1);
{$ENDIF}
  vis.patch := lump;

{$IFNDEF OPENGL}
  if (viewplayer.powers[Ord(pw_invisibility)] > 4 * 32) or
     (viewplayer.powers[Ord(pw_invisibility)] and 8 <> 0) then
  begin
    // shadow draw
    vis.colormap := nil;
  end
  else{$ENDIF} if fixedcolormap <> nil then
  begin
    // fixed color
    vis.colormap := fixedcolormap;
{$IFDEF OPENGL}
    lightlevel := 255;
{$ENDIF}
  end
  else if psp.state.frame and FF_FULLBRIGHT <> 0 then
  begin
    // full bright
    vis.colormap := colormaps;
{$IFDEF OPENGL}
    lightlevel := 255;
{$ENDIF}
  end
  else
  begin
    // local light
    vis.colormap := spritelights[MAXLIGHTSCALE - 1];
{$IFDEF OPENGL}
    lightlevel := Psubsector_t(vis.mo.subsector).sector.lightlevel + extralight shl LIGHTSEGSHIFT
{$ENDIF}
  end;

{$IFDEF OPENGL}
  gld_DrawWeapon(lump, vis, lightlevel); // JVAL OPENGL
{$ELSE}
  R_DrawVisSprite(vis, true); // JVAL OPENGL
{$ENDIF}
end;

//
// R_DrawPlayerSprites
//
procedure R_DrawPlayerSprites;
var
  i: integer;
  lightnum: integer;
begin
  // get light level
  lightnum :=
    _SHR(Psubsector_t(viewplayer.mo.subsector).sector.lightlevel, LIGHTSEGSHIFT) +
      extralight;

  if lightnum <= 0 then
    spritelights := @scalelight[0]
  else if lightnum >= LIGHTLEVELS then
    spritelights := @scalelight[LIGHTLEVELS - 1]
  else
    spritelights := @scalelight[lightnum];

  // clip to screen bounds
  mfloorclip := @screenheightarray;
  mceilingclip := @negonearray;

  // add all active psprites
  if shiftangle < 128 then
    centerxshift := shiftangle * FRACUNIT div 40 * viewwidth
  else
    centerxshift := - (255 - shiftangle) * FRACUNIT div 40 * viewwidth;
  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    if viewplayer.psprites[i].state <> nil then
      R_DrawPSprite(@viewplayer.psprites[i]);
  end;
end;

{$IFNDEF OPENGL}
//
// R_SortVisSprites
//
procedure R_SortVisSprites;

  procedure qsortvs(l, r: Integer);
  var
    i, j: Integer;
    t: Pvissprite_t;
    scale: fixed_t;
  begin
    repeat
      i := l;
      j := r;
      scale := vissprites[(l + r) shr 1].scale;
      repeat
        while vissprites[i].scale < scale do
          inc(i);
        while vissprites[j].scale > scale do
          dec(j);
        if i <= j then
        begin
          t := vissprites[i];
          vissprites[i] := vissprites[j];
          vissprites[j] := t;
          inc(i);
          dec(j);
        end;
      until i > j;
      if l < j then
        qsortvs(l, j);
      l := i;
    until i >= r;
  end;

begin
  if vissprite_p > 0 then
    qsortvs(0, vissprite_p - 1);
end;

//
// R_DrawSprite
//

procedure R_DrawSprite(spr: Pvissprite_t);
var
  ds: Pdrawseg_t;
  x: integer;
  r1: integer;
  r2: integer;
  scale: fixed_t;
  lowscale: fixed_t;
  silhouette: integer;
  i: integer;
  h, mh: fixed_t;
  plheightsec: integer;
begin
  // JVAL voxel support
  if spr.voxelflag <> 0 then
  begin
    R_DrawVoxel(spr);
    exit;
  end;

  for x := spr.x1 to spr.x2 do
  begin
    clipbot[x] := -2;
    cliptop[x] := -2;
  end;

  // Scan drawsegs from end to start for obscuring segs.
  // The first drawseg that has a greater scale
  //  is the clip seg.
  for i := ds_p - 1 downto 0 do
  begin
    ds := drawsegs[i];
    // determine if the drawseg obscures the sprite
    if (ds.x1 > spr.x2) or
       (ds.x2 < spr.x1) or
       ((ds.silhouette = 0) and (ds.maskedtexturecol = nil)) then
    begin
      // does not cover sprite
      continue;
    end;

    if ds.x1 < spr.x1 then
      r1 := spr.x1
    else
      r1 := ds.x1;
    if ds.x2 > spr.x2 then
      r2 := spr.x2
    else
      r2 := ds.x2;

    if ds.scale1 > ds.scale2 then
    begin
      lowscale := ds.scale2;
      scale := ds.scale1;
    end
    else
    begin
      lowscale := ds.scale1;
      scale := ds.scale2;
    end;

    if (scale < spr.scale) or
       ((lowscale < spr.scale) and (not R_PointOnSegSide(spr.gx, spr.gy, ds.curline))) then
    begin
      // masked mid texture?
      if ds.maskedtexturecol <> nil then
        R_RenderMaskedSegRange(ds, r1, r2);
      // seg is behind sprite
      continue;
    end;

    // clip this piece of the sprite
    silhouette := ds.silhouette;

    if spr.gz >= ds.bsilheight then
      silhouette := silhouette and (not SIL_BOTTOM);

    if spr.gzt <= ds.tsilheight then
      silhouette := silhouette and (not SIL_TOP);

    if silhouette = 1 then
    begin
      // bottom sil
      for x := r1 to r2 do
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
    end
    else if silhouette = 2 then
    begin
      // top sil
      for x := r1 to r2 do
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
    end
    else if silhouette = 3 then
    begin
      // both
      for x := r1 to r2 do
      begin
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
      end;
    end;
  end;


  // killough 3/27/98:
  // Clip the sprite against deep water and/or fake ceilings.
  // killough 4/9/98: optimize by adding mh
  // killough 4/11/98: improve sprite clipping for underwater/fake ceilings

  if spr.heightsec <> -1 then  // only things in specially marked sectors
  begin
    plheightsec := Psubsector_t(viewplayer.mo.subsector).sector.heightsec;
    mh := sectors[spr.heightsec].floorheight;
    if mh > spr.gz then
    begin
      mh := mh - viewz;
      h := centeryfrac - FixedMul(mh, spr.scale);
      if h >= 0 then
      begin
        h := h div FRACUNIT;
        if h < viewheight then
        begin
          if (mh <= 0) or ((plheightsec <> -1) and (viewz > sectors[plheightsec].floorheight)) then
          begin
            for x := spr.x1 to spr.x2 do
              if (clipbot[x] = -2) or (h < clipbot[x]) then
                clipbot[x] := h;
          end
          else
          begin
            for x := spr.x1 to spr.x2 do
              if (cliptop[x] = -2) or (h > cliptop[x]) then
                cliptop[x] := h;
          end;
        end;
      end;
    end;

    mh := sectors[spr.heightsec].ceilingheight;
    if mh < spr.gzt then
    begin
      h := centeryfrac - FixedMul(mh - viewz, spr.scale);
      if h >= 0 then
      begin
        h := h div FRACUNIT;
        if h < viewheight then
        begin
          if (plheightsec <> -1) and (viewz >= sectors[plheightsec].ceilingheight) then
          begin
            for x := spr.x1 to spr.x2 do
              if (clipbot[x] = -2) or (h < clipbot[x]) then
                clipbot[x] := h;
          end
          else
          begin
            for x :=spr.x1 to spr.x2 do
              if (cliptop[x] = -2) or (h > cliptop[x]) then
                cliptop[x] := h;
          end;
        end;
      end;
    end;
  end;

  // killough 3/27/98: end special clipping for deep water / fake ceilings

  // all clipping has been performed, so draw the sprite

  // check for unclipped columns
  for x := spr.x1 to spr.x2 do
  begin
    if clipbot[x] = -2 then
      clipbot[x] := fake3dbottomclip // viewheight;
    else if clipbot[x] > fake3dbottomclip then
      clipbot[x] := fake3dbottomclip;

    if cliptop[x] = -2 then
      cliptop[x] := fake3dtopclip // -1;
    else if cliptop[x] < fake3dtopclip then
      cliptop[x] := fake3dtopclip;
{    if clipbot[x] = -2 then
      clipbot[x] := viewheight;

    if cliptop[x] = -2 then
      cliptop[x] := -1;}
  end;

  mfloorclip := @clipbot;
  mceilingclip := @cliptop;

  R_DrawVisSprite(spr)
end;

procedure R_DrawSpriteLight(spr: Pvissprite_t);
var
  ds: Pdrawseg_t;
  x: integer;
  r1: integer;
  r2: integer;
  scale: fixed_t;
  lowscale: fixed_t;
  silhouette: integer;
  i: integer;
  x1, x2: integer;
begin
  x := (spr.x2 - spr.x1) div 2;
  x1 := spr.x1 - x;
  x2 := spr.x2 + x;

  if x1 < 0 then
    x1 := 0;
  if x2 >= viewwidth then
    x2 := viewwidth - 1;

  for x := x1 to x2 do
  begin
    clipbot[x] := -2;
    cliptop[x] := -2;
  end;

  // Scan drawsegs from end to start for obscuring segs.
  // The first drawseg that has a greater scale
  //  is the clip seg.
  for i := ds_p - 1 downto 0 do
  begin
    ds := drawsegs[i];
    // determine if the drawseg obscures the sprite
    if (ds.x1 > x2) or
       (ds.x2 < x1) or
       ((ds.silhouette = 0) and (ds.maskedtexturecol = nil)) then
    begin
      // does not cover sprite
      continue;
    end;

    if ds.x1 <= x1 then
      r1 := x1
    else
      r1 := ds.x1;
    if ds.x2 >= x2 then
      r2 := x2
    else
      r2 := ds.x2;

    if ds.scale1 > ds.scale2 then
    begin
      lowscale := ds.scale2;
      scale := ds.scale1;
    end
    else
    begin
      lowscale := ds.scale1;
      scale := ds.scale2;
    end;

    if (scale < spr.scale) or
       ((lowscale < spr.scale) and (not R_PointOnSegSide(spr.gx, spr.gy, ds.curline))) then
    begin
      // masked mid texture?
      if ds.maskedtexturecol <> nil then
        R_RenderMaskedSegRange(ds, r1, r2);
      // seg is behind sprite
      continue;
    end;

    // clip this piece of the sprite
    silhouette := ds.silhouette;

    if spr.gz >= ds.bsilheight then
      silhouette := silhouette and (not SIL_BOTTOM);

    if spr.gzt <= ds.tsilheight then
      silhouette := silhouette and (not SIL_TOP);

    if silhouette = 1 then
    begin
      // bottom sil
      for x := r1 to r2 do
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
    end
    else if silhouette = 2 then
    begin
      // top sil
      for x := r1 to r2 do
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
    end
    else if silhouette = 3 then
    begin
      // both
      for x := r1 to r2 do
      begin
        if clipbot[x] = -2 then
          clipbot[x] := ds.sprbottomclip[x];
        if cliptop[x] = -2 then
          cliptop[x] := ds.sprtopclip[x];
      end;
    end;
  end;

  // all clipping has been performed, so draw the sprite

  // check for unclipped columns
  for x := x1 to x2 do
  begin
    if clipbot[x] = -2 then
      clipbot[x] := fake3dbottomclip
    else if clipbot[x] > fake3dbottomclip then
      clipbot[x] := fake3dbottomclip;

    if cliptop[x] = -2 then
      cliptop[x] := fake3dtopclip 
    else if cliptop[x] < fake3dtopclip then
      cliptop[x] := fake3dtopclip;
  end;

  mfloorclip := @clipbot;
  mceilingclip := @cliptop;

  R_DrawVisSpriteLight(spr, x1, x2);

end;

//
// R_DrawMasked
//
procedure R_DrawMasked;
var
  ds: Pdrawseg_t;
  i: integer;
begin
  R_SortVisSprites;

  if vissprite_p > 0 then
  begin
    // draw all vissprites back to front
    if uselightboost and (videomode = vm32bit) then
    begin
      for i := 0 to vissprite_p - 1 do
      begin
        if vissprites[i].mobjflags_ex and MF_EX_LIGHT <> 0 then
          R_DrawSpriteLight(vissprites[i]);
        R_DrawSprite(vissprites[i]);
      end;
    end
    else
    begin
      for i := 0 to vissprite_p - 1 do
        R_DrawSprite(vissprites[i]);
    end;
  end;

  // render any remaining masked mid textures
  colfunc := maskedcolfunc;
  for i := ds_p - 1 downto 0 do
  begin
    ds := drawsegs[i];
    if ds.maskedtexturecol <> nil then
      R_RenderMaskedSegRange(ds, ds.x1, ds.x2);
  end;
end;
{$ENDIF}

procedure R_DrawPlayer;
var
  old_centery: fixed_t;
  old_centeryfrac: fixed_t;
begin
  // draw the psprites on top of everything
  //  but does not draw on side views
  if (viewangleoffset = 0) and not chasecamera then
  begin
    // Restore z-axis shift
    if zaxisshift then
    begin
      old_centery := centery;
      old_centeryfrac := centeryfrac;
      centery := viewheight div 2;
      centeryfrac := centery * FRACUNIT;
      R_DrawPlayerSprites;
      centery := old_centery;
      centeryfrac := old_centeryfrac;
    end
    else
      R_DrawPlayerSprites;
  end;
end;

end.


