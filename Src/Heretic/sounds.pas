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
//  Created by the sound utility written by Dave Taylor.
//  Kept as a sample, DOOM2  sounds. Frozen.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit sounds;

interface

uses
  d_delphi;

//
// SoundFX struct.
//

type
  Psfxinfo_t = ^sfxinfo_t;

  sfxinfo_t = record
    // up to 6-character name
    name: string;

    // Sfx singularity (only one at a time)
    singularity: boolean;

    // Sfx priority
    priority: integer;

    // referenced sound if a link
    link: Psfxinfo_t;

    // pitch if a link
    pitch: integer;

    // volume if a link
    volume: integer;

    // sound data
    data: pointer;

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    usefulness: integer;

    // lump number of sfx
    lumpnum: integer;

    // JVAL: Random list
    randomsoundlist: TDNumberList;
  end;

//
// MusicInfo struct.
//
  musicinfo_t = record
    // up to 6-character name
    name: string;
    mapname: string;

    // lump number of music
    lumpnum: integer;

    // music data
    data: pointer;

    // music handle once registered
    handle: integer;
    // is an mp3?
    mp3stream: TStream;
  end;
  Pmusicinfo_t = ^musicinfo_t;

//
// Identifiers for all music in game.
//

  musicenum_t = (
    mus_None,
    mus_e1m1,
    mus_e1m2,
    mus_e1m3,
    mus_e1m4,
    mus_e1m5,
    mus_e1m6,
    mus_e1m7,
    mus_e1m8,
    mus_e1m9,

    mus_e2m1,
    mus_e2m2,
    mus_e2m3,
    mus_e2m4,
    mus_e2m5,
    mus_e2m6,
    mus_e2m7,
    mus_e2m8,
    mus_e2m9,

    mus_e3m1,
    mus_e3m2,
    mus_e3m3,
    mus_e3m4,
    mus_e3m5,
    mus_e3m6,
    mus_e3m7,
    mus_e3m8,
    mus_e3m9,

    mus_e4m1,
    mus_e4m2,
    mus_e4m3,
    mus_e4m4,
    mus_e4m5,
    mus_e4m6,
    mus_e4m7,
    mus_e4m8,
    mus_e4m9,

    mus_e5m1,
    mus_e5m2,
    mus_e5m3,
    mus_e5m4,
    mus_e5m5,
    mus_e5m6,
    mus_e5m7,
    mus_e5m8,
    mus_e5m9,

    mus_e6m1,
    mus_e6m2,
    mus_e6m3,

    mus_titl,
    mus_intr,
    mus_cptd,
    NUMMUSIC
  );


//
// Identifiers for all sfx in game.
//

  sfxenum_t = (
    sfx_None,
    sfx_gldhit,
    sfx_gntful,
    sfx_gnthit,
    sfx_gntpow,
    sfx_gntact,
    sfx_gntuse,
    sfx_phosht,
    sfx_phohit,
    sfx_phopow,
    sfx_lobsht,
    sfx_lobhit,
    sfx_lobpow,
    sfx_hrnsht,
    sfx_hrnhit,
    sfx_hrnpow,
    sfx_ramphit,
    sfx_ramrain,
    sfx_bowsht,
    sfx_stfhit,
    sfx_stfpow,
    sfx_stfcrk,
    sfx_impsit,
    sfx_impat1,
    sfx_impat2,
    sfx_impdth,
    sfx_impact,
    sfx_imppai,
    sfx_mumsit,
    sfx_mumat1,
    sfx_mumat2,
    sfx_mumdth,
    sfx_mumact,
    sfx_mumpai,
    sfx_mumhed,
    sfx_bstsit,
    sfx_bstatk,
    sfx_bstdth,
    sfx_bstact,
    sfx_bstpai,
    sfx_clksit,
    sfx_clkatk,
    sfx_clkdth,
    sfx_clkact,
    sfx_clkpai,
    sfx_snksit,
    sfx_snkatk,
    sfx_snkdth,
    sfx_snkact,
    sfx_snkpai,
    sfx_kgtsit,
    sfx_kgtatk,
    sfx_kgtat2,
    sfx_kgtdth,
    sfx_kgtact,
    sfx_kgtpai,
    sfx_wizsit,
    sfx_wizatk,
    sfx_wizdth,
    sfx_wizact,
    sfx_wizpai,
    sfx_minsit,
    sfx_minat1,
    sfx_minat2,
    sfx_minat3,
    sfx_mindth,
    sfx_minact,
    sfx_minpai,
    sfx_hedsit,
    sfx_hedat1,
    sfx_hedat2,
    sfx_hedat3,
    sfx_heddth,
    sfx_hedact,
    sfx_hedpai,
    sfx_sorzap,
    sfx_sorrise,
    sfx_sorsit,
    sfx_soratk,
    sfx_soract,
    sfx_sorpai,
    sfx_sordsph,
    sfx_sordexp,
    sfx_sordbon,
    sfx_sbtsit,
    sfx_sbtatk,
    sfx_sbtdth,
    sfx_sbtact,
    sfx_sbtpai,
    sfx_plroof,
    sfx_plrpai,
    sfx_plrdth,        // Normal
    sfx_gibdth,        // Extreme
    sfx_plrwdth,    // Wimpy
    sfx_plrcdth,    // Crazy
    sfx_itemup,
    sfx_wpnup,
    sfx_telept,
    sfx_doropn,
    sfx_dorcls,
    sfx_dormov,
    sfx_artiup,
    sfx_switch,
    sfx_pstart,
    sfx_pstop,
    sfx_stnmov,
    sfx_chicpai,
    sfx_chicatk,
    sfx_chicdth,
    sfx_chicact,
    sfx_chicpk1,
    sfx_chicpk2,
    sfx_chicpk3,
    sfx_keyup,
    sfx_ripslop,
    sfx_newpod,
    sfx_podexp,
    sfx_bounce,
    sfx_volsht,
    sfx_volhit,
    sfx_burn,
    sfx_splash,
    sfx_gloop,
    sfx_respawn,
    sfx_blssht,
    sfx_blshit,
    sfx_chat,
    sfx_artiuse,
    sfx_gfrag,
    sfx_waterfl,

    // Monophonic sounds

    sfx_wind,
    sfx_amb1,
    sfx_amb2,
    sfx_amb3,
    sfx_amb4,
    sfx_amb5,
    sfx_amb6,
    sfx_amb7,
    sfx_amb8,
    sfx_amb9,
    sfx_amb10,
    sfx_amb11,
    DO_NUMSFX
  );

const
  MAX_NUMSFX = Ord(DO_NUMSFX) + 1024; // JVAL 1024 extra sounds

const
  S_music: array[0..Ord(NUMMUSIC) - 1] of musicinfo_t = (
    (name: '';       mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m8';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m9';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'e2m1';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m2';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m3';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m4';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e2m5';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m6';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m7';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m8';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m9';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'e1m1';   mapname: 'e3m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m2';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m3';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: 'e3m4';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: 'e3m5';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: 'e3m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e3m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e3m8';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m6';   mapname: 'e3m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'e1m6';   mapname: 'e4m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: 'e4m2';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: 'e4m3';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e4m4';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e4m5';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: 'e4m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e4m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m8';   mapname: 'e4m8';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m9';   mapname: 'e4m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'e2m1';   mapname: 'e5m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m2';   mapname: 'e5m2';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m3';   mapname: 'e5m3';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m4';   mapname: 'e5m4';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e5m5';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m6';   mapname: 'e5m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m7';   mapname: 'e5m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m8';   mapname: 'e5m8';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m9';   mapname: 'e5m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'e3m2';   mapname: 'e6m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m3';   mapname: 'e6m2';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: 'e6m3';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: 'titl';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'intr';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'cptd';   mapname: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil)
  );

  S_sfx: array[0..MAX_NUMSFX - 1] of sfxinfo_t = (
  // S_sfx[0] needs to be a dummy for odd reasons.
    (name: 'none';   singularity: false; priority:   0; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: 'gldhit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gntful';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gnthit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gntpow';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gntact';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gntuse';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'phosht';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'phohit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-phopow'; singularity: false; priority:  32; link: @S_sfx[Ord(sfx_hedat1)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'lobsht';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'lobhit';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'lobpow';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hrnsht';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hrnhit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hrnpow';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ramphit'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ramrain'; singularity: false; priority:  10; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bowsht';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stfhit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stfpow';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stfcrk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'impsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'impat1';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'impat2';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'impdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-impact'; singularity: false; priority:  20; link: @S_sfx[Ord(sfx_impsit)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'imppai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumat1';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumat2';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-mumact'; singularity: false; priority:  20; link: @S_sfx[Ord(sfx_mumsit)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mumhed';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bstsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bstatk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bstdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bstact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bstpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'clksit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'clkatk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'clkdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'clkact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'clkpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'snksit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'snkatk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'snkdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'snkact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'snkpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kgtsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kgtatk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kgtat2';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kgtdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-kgtact'; singularity: false; priority:  20; link: @S_sfx[Ord(sfx_kgtsit)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kgtpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wizsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wizatk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wizdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wizact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wizpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minat1';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minat2';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minat3';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mindth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'minpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedsit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedat1';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedat2';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedat3';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'heddth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hedpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sorzap';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sorrise'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sorsit';  singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'soratk';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'soract';  singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sorpai';  singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sordsph'; singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sordexp'; singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sordbon'; singularity: false; priority: 200; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-sbtsit'; singularity: false; priority:  32; link: @S_sfx[Ord(sfx_bstsit)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-sbtatk'; singularity: false; priority:  32; link: @S_sfx[Ord(sfx_bstatk)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sbtdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sbtact';  singularity: false; priority:  20; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sbtpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plroof';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plrpai';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plrdth';  singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gibdth';  singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plrwdth'; singularity: false; priority:  80; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plrcdth'; singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'itemup';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wpnup';   singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'telept';  singularity: false; priority:  50; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'doropn';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dorcls';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dormov';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'artiup';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'switch';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pstart';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pstop';   singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stnmov';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicpai'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicatk'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicdth'; singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicact'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicpk1'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicpk2'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chicpk3'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'keyup';   singularity: false; priority:  50; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ripslop'; singularity: false; priority:  16; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'newpod';  singularity: false; priority:  16; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'podexp';  singularity: false; priority:  40; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bounce';  singularity: false; priority:  16; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-volsht'; singularity: false; priority:  16; link: @S_sfx[Ord(sfx_bstatk)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: '-volhit'; singularity: false; priority:  16; link: @S_sfx[Ord(sfx_lobhit)]; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'burn';    singularity: false; priority:  10; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'splash';  singularity: false; priority:  10; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gloop';   singularity: false; priority:  10; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'respawn'; singularity: false; priority:  10; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'blssht';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'blshit';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chat';    singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'artiuse'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gfrag';   singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'waterfl'; singularity: false; priority:  16; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    // Monophonic sounds

    (name: 'wind'; singularity: false; priority:  16; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb1'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb2'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb3'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb4'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb5'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb6'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb7'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb8'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb9'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb10'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'amb11'; singularity: false; priority:  1; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),

    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),

    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: ''),
    (name: '')
  );


var
  numsfx: integer = Ord(DO_NUMSFX);

function S_GetSoundNumForName(const sfx_name: string): integer;

function S_GetSoundNameForNum(const sfx_num: integer): string;

function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;

procedure S_FreeRandomSoundLists;

procedure S_FreeMP3Streams;

implementation

uses
  i_system,
  sc_decorate,
  w_wad;

function S_GetSoundNumForName(const sfx_name: string): integer;
var
  i: integer;
  name: string;
  check: string;
  sfx: Psfxinfo_t;
begin
  result := atoi(sfx_name, -1);
  if (result >= 0) and (result < numsfx) and (itoa(result) = sfx_name) then
    exit;

  if sfx_name = '' then
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := Ord(sfx_gldhit);
    exit;
  end;

  name := strupper(SC_SoundAlias(sfx_name));
  for i := 1 to numsfx - 1 do
  begin
    check := strupper(S_sfx[i].name);
    if (check = name) or ('DS' + check = name) then
    begin
      result := i;
      exit;
    end;
  end;

  // JVAL: Not found, we will add a new sound

  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default sound :(
  begin
    I_Warning('S_GetSoundNumForName(): Can not add %s sound, limit of %d sounds exceeded'#13#10, [sfx_name, numsfx]);
    result := Ord(sfx_gldhit);
    exit;
  end;

  // JVAL: Register the new sound

  if Pos('DS', name) = 1 then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := Ord(sfx_gldhit);
    exit;
  end;

  result := numsfx;
  sfx := @S_sfx[result];
  sfx.name := name;
  sfx.singularity := false;
  sfx.priority := 72;
  sfx.link := nil;
  sfx.pitch := -1;
  sfx.volume := -1;
  sfx.data := nil;
  sfx.usefulness := 0;
  sfx.lumpnum :=  -1; // jval: was = 0;
  sfx.randomsoundlist := nil;
  inc(numsfx);

end;

function S_GetSoundNameForNum(const sfx_num: integer): string;
begin
  if (sfx_num < 0) or (sfx_num >= numsfx) then
  begin
    result := '';
    exit;
  end;

  // JVAL: strupper -> for safety
  result := strupper(S_sfx[sfx_num].name);
end;

//
// JVAL
// Retrieve the random sound list for a sfx number
// Note
//  Random list is in range of '0'..'9', of the last char of sound name eg
//    dsxxx0
//    dsxxx1
//    dsxxx2
//    dsxxx3
//    dsxxx7
//    dsxxx9
// It is not required to be all the numbers in last char
// Random sound list is saved not only to the sfx_num, but also to other sounds numbers
// of the same 'random' group
// Check WAD for presence of lumps
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;
var
  sfxname: string;
  sfxname1: string;
  sfxname2: string;
  sfxname3: string;
  sfxnum: integer;
  check: integer;
  c: char;
begin
  sfxname := S_GetSoundNameForNum(sfx_num);
  if sfxname = '' then
  begin
    result := nil;
    exit;
  end;

  if S_sfx[sfx_num].randomsoundlist = nil then
    S_sfx[sfx_num].randomsoundlist := TDNumberList.Create;

  result := S_sfx[sfx_num].randomsoundlist;

  if result.Count > 0 then
    exit;

  check := Ord(sfxname[Length(sfxname)]);
  if (check < Ord('0')) or (check > Ord('9')) then
  begin
    result.Add(sfx_num);  // This sound for sure!
    exit;
  end;

  // JVAL: look first for 'ds....' sound names
  if Pos('DS', sfxname) = 1 then
  begin
    sfxname1 := sfxname;
    sfxname2 := Copy(sfxname, 3, Length(sfxname) - 2)
  end
  else
  begin
    sfxname1 := 'DS' + sfxname;
    sfxname2 := sfxname;
  end;
  sfxname3 := '';
  if Length(sfxname1) > 8 then
    SetLength(sfxname1, 8);
  if Length(sfxname2) > 8 then
    SetLength(sfxname2, 8);
  for c := '0' to '9' do
  begin
    sfxname1[Length(sfxname1)] := c;
    check := W_CheckNumForName(sfxname1);
    if check = -1 then
    begin
      sfxname2[Length(sfxname2)] := c;
      check := W_CheckNumForName(sfxname2);
      if check >= 0 then
        sfxname3 := sfxname2;
    end
    else
      sfxname3 := sfxname1;

    if check >= 0 then
    begin
      sfxnum := S_GetSoundNumForName(sfxname3);
      result.Add(sfxnum);
      S_sfx[sfxnum].lumpnum := check; // Save the lump number
      if S_sfx[sfxnum].randomsoundlist = nil then
        S_sfx[sfxnum].randomsoundlist := result;
    end;
  end;
end;

procedure S_FreeRandomSoundLists;
var
  i, j: integer;
  l: TDNumberList;
begin
  for i := 1 to numsfx - 1 do
  begin
    if S_sfx[i].randomsoundlist <> nil then
    begin
      l := S_sfx[i].randomsoundlist;
      for j := i + 1 to numsfx - 1 do
        if S_sfx[j].randomsoundlist = l then
          S_sfx[i].randomsoundlist := nil;
      FreeAndNil(S_sfx[i].randomsoundlist);
    end;
  end;
end;

procedure S_FreeMP3Streams;
var
  i, j: integer;
  s: TStream;
begin
  for i := 0 to Ord(NUMMUSIC) - 1 do
    if S_music[i].mp3stream <> nil then
    begin
      s := S_music[i].mp3stream;
      for j := i + 1 to Ord(NUMMUSIC) - 1 do
        if S_music[j].mp3stream = s then
          S_music[j].mp3stream := nil;
      FreeAndNil(S_music[i].mp3stream);
    end;
end;


end.

