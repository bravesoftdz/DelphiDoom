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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------


General
-------
This is the translation of the Linux C source code of the game Doom to the Delphi programming language. Many features have been added to take advantage of modern hardware: External hi-res textures, 32 bit color software renderer, OpenGL support, md2 models, dynamic lightmaps, mp3 music and more... In addition provides accurate demo playback of most Vanilla Doom demos.

Description
-----------
This Application is a WIN32 port of the famous Doom game created by ID Software.

Capabilities
------------
Allow to play Doom and Doom2 WAD files.

Command Line Parameters
-----------------------
See doc\cmdparams.txt file.

Console Commands
----------------
See doc\consolecommands.txt file.

History
-------

Version 1.1.4 build 581 - (May 28, 2013)
-----------------------------------
See Doom_what's new.txt, Heretic_what's new.txt and Hexen_what's new.txt

Version 1.1.4 build 550 - (18/3/2013)
-----------------------------------
Added spawnmobj console command
Added -blancbeforerender command line parameter (software mode only)
Added optimizedcolumnrendering console variable, when true (default) uses optimized method while rendering wall columns and sky.
Fixed ascpect ratio when using widscreen monitors.
Added allowhidetails console variable.
Added widescreen,widescreensupport console variables.
Added forcedaspect console variable to set custom aspect ratio.
Added pngtransparentcolor and pngtransparentcolor2 console variables.
Added optimizedthingsrendering console variable, when true (default) uses optimized method while rendering sprites
Multithreading column rendering.
Added assumecommontranspantcolors console variable, when true assumes x0FFFF, x0FF00FF and x0FFFF00 as transparency indicators in png images.

Version 1.1.4 build 537 - (21/5/2012) (beta)
-----------------------------------
Turbo scale limited to 200%
Added modelmapping console command to determine which models are present. (OpenGL version only)
Speed optimizations in 32 bit color software mode (fps incresed 5-10%).

Version 1.1.3 build 532 - (17/3/2012) (beta)
-----------------------------------
NOTE: This beta version can not guaranty future demo playback compatibility and load/save game compatibility with future official releases.
Added autoadjustmissingtextures console variable, when true try to "guess" and correct missing textures.
Autoloads required pak/pk3 files inside AUTOLOAD wad lump.
Added custom parameters to mobjs ([parameter name(string)] - [value(integer)], eg inventory). 
Added A_SetCustomParam, A_AddCustomParam, A_SubtractCustomParam mobj functions.
Added A_SetTargetCustomParam, A_AddTargetCustomParam, A_SubtractTargetCustomParam mobj functions.
Added A_JumpIfCustomParam, A_JumpIfCustomParamLess, A_JumpIfCustomParamGreater mobj functions.
Added A_JumpIfTargetCustomParam, A_JumpIfTargetCustomParamLess, A_JumpIfTargetCustomParamGreater mobj functions.
Added A_SetShootable and A_UnSetShootable mobj functions.
Added A_PlayerMessage mobj function.
Added allowplayerbreath console variable, when true play player breath sound. (default is false)
Added A_PlayerFaceMe mobj function.
Added MF2_EX_FLOORCLIP mobj flag.
Faster loading when -devparm is defined.
Added A_GoTo, A_GoToIfCloser, A_GoToIfHealthLower mobj functions.
Added A_GoToIfCustomParam, A_GoToIfCustomParamLess, A_GoToIfCustomParamGreater mobj functions.
Added A_GoToIfTargetCustomParam, A_GoToIfTargetCustomParamLess, A_GoToIfTargetCustomParamGreater mobj functions.
Added A_SetFloorClip and A_UnSetFloorClip mobj functions.
DLIGHTSDRAWRANGE and SHADOWSDRAWRANGE increased to 2048 * FRACUNIT.
Fixed disapearing sprites with transparency < 50% in OpenGL mode. 
Doesn't try to spawn DoomBuilder 3D Editing mode camera (doomednum=32000).
Support for Chex Quest and Chex Quest 2.
Support for Hacx (varsion 1.2)
'TEXT' keyword in dehacked files works now with music.
Great speed optimizations in 8 bit color software mode (fps incresed 10-15%).

Version 1.1.3 build 510 - (7/3/2012) (beta)
-----------------------------------
Zlib updated to version 1.2.5.
OpenGL version for DelphiHexen (There is still work to do but besides some rendering issues seems stable for gameplay).

Version 1.1.3 build 509 - (3/3/2012) (beta)
-----------------------------------
This release contains an experimental build with Free Pascal Compiler (Doom - OpenGL mode only)
Added interact state for mobjs.
Added A_SpawnSmokeUp, A_SpawnSmokeDown and A_SpawnSmokeHorz mobj functions
Added MF2_EX_INTERACTIVE mobj flag.
Added A_SetInteractive and A_UnSetInteractive mobj functions
Fixed wav chunks reading bug.
Added MF2_EX_DONTINFIGHTMONSTERS mobj flag, suppress monster infight for mobjs of the same inheritance.
Added A_SetMonsterInfight and A_UnSetMonsterInfight mobj functions.
Added A_RemoveSelf mobj function.
Added A_NoiseAlert mobj function.
Added A_ConsoleCommand mobj function.
Chase camera positioning improvements.
FastMM memory manager upgrated to version 4.99.
Corrected stencil sky rendering in OpenGL mode.

Version 1.1.3 build 500 - (20/1/2012)
-----------------------------------
Displays Disk Buzy icon for 4 ticks instead of 4 frames.
WAD lumps hash indexing for better performance. (using djb2 hash function)
Fixed ENDOOM bug witch causing menu to respond during ending game while playing a demo. 
Added A_SpawnItemEx mobj function
Fixed bug that didn't recornized mf2_ex flags inside ACTORDEF lumps
Added Green blood and Blue blood flags.
Added MF2_EX_NOTELEPORT flag.
Added A_RandomMissile mobj function.
Default zone size increased from 8 MB to 32 MB.
Show demo playback progress.
Added showdemoplaybackprogress console variable.
Transparency in 8 bit rendering using euclidian square distance to aproximate palette indexes.
Added diher8bittransparency console variable.
Added displayresolution alias for "detaillevel" console variable.
Fixed Medusa Effect Bug.
Added engage console command, alias for start and playgame.
Precalculate floating point parameters of custom mobj functions as fixed_t.
Boom compatible friction effect.
Boom compatible pushers. (linedef special 224/wind, 225/current, 226/push-pull)
Suspends interpolation for teleporting objects, that eliminates some drawing gliches.
Fixed transparency HUD in OpenGL mode.
Added support for GL_FRIENDLY nodes (OpenGL version). 
Automatically loads *.GWA files if autoloadgwafiles console variable is set to true. (OpenGL version). 
Fixed background flat in finale text drawing (F_TextWrite) 
Added giveallkeys, idkeys console commands, give all keys (idkeys cheat).
Fixed sprite clipping bug in OpenGL mode when looking up/down.
Removed limit on lines hit.
Hash Indexing of external PAK/PK3/ZIP files.
FastMM memory manager upgrated to version 4.94.
Default miditempo changed to 128.
Added MF2_EX_PUSHABLE and MF2_EX_CANNOTPUSH mobj flags, enabled pushable objects.
Added A_HideThing and A_UnHideThing mobj functions.
Added support for dynamic lights, using LIGHTDEF lump.
Added hidedoublicatedbarrels console variable, if there are many barrels at the exact same position draws only one.
Precaclulate OpenGL display lists for floors and ceilings if possible.
Fixed sky rendering problems in OpenGL mode.
Added Crash state in mobjs.
New simplified blocklinks handling mechanism.
Fixed Dehacked bug, now correctly handles POINTER keyword
Added gl_stencilsky conslole variable.
Corrected some issues in OpenGL rendering.
Added support for MD2 models (OpenGL only).
Check for LIGHTDEF lumps inside PAK/PK3 files. (First parse all LIGHTDEF entries and then all LIGHTDEF.txt entries)
Added gl_drawmodels console variable.
Added gl_smoothmodelmovement console variable.
Dynamic lightmap implementation.
Added gl_uselightmaps console variable.
Added gl_precachemodeltextures console variable.
OpenGL UI speed optimizations.
Custom lighttables in OpenGL using GLGAMMA lump.
New external texture format named (using .material extension) to combine at load time with user defined parameters more than one external textures into one.
Added simple shadows.
Added gl_drawshadows console command.
Added ATurn5 and A_Turn10 mobj functions.

Version 1.0.2 build 383 - (3/3/2008)
-----------------------------------
Added OpenGL rendering. (gldoom32.exe)
Added displaydiskbuzyicon console variable.
Added jpeg external textures support.
Fixed zip library memory leak.
Speed optimization for V_ReadPalette function.
Added A_FadeIn10, A_FadeIn20 and A_FadeIn30 mobj functions.
Added A_FadeOut10, A_FadeOut20 and A_FadeOut30 mobj functions.
The idmypos cheats now shows also the z position (height) of the player.
Added idmypos console command.
Added menu_optionsdisplayopengl, menu_optionsopengl, menu_opengl console commands.
Fixed very rare bug that coused crashes when statusbar drawned.
Added OpenGL support for Hi-resolution flats inside WADs.
Added default_transparent_filter_percent, use_fog, fog_density, gl_nearclip console variables.
Added gl_tex_filter, gl_texture_filter_anisotropic console variables.
Added gl_drawsky and gl_linear_hud console variables.
Enabled external texture support for OpenGL rendering.
Fixed lighting effect glitches in OpenGL rendering.
External hi-resolution sprite support (OpenGL version only).

Version 0.8.5 build 343 - (5/1/2008)
-----------------------------------
Fixed endoom screen problem.

Version 0.8.5 build 342 - (4/1/2008)
-----------------------------------
The source code can be compiled with FPC (tested with version 2.2.0) (Some features are not present like PNG textures and PK3/PK4 files support)
Added massacre console command.
Added terrain types.
Added allowterrainsplashes variable.
Added MF2_EX_NOHITFLOOR flag.
Added continueafterplayerdeath variable, allows monsters to fight each other after player death.
Plays random pain sound when MF_EX_RANDOMPAINSOUND flag is set.
Don't spawn blood when a sector crashes an invulnerable thing or player.
DDSYSTEM.WAD renamed to Doom32.swd.
Added -internalgamedef command line parameter to ignore GAMEDEF lump inside Doom32.swd.
Allows ';' for comment in SNDINFO lumps.
Automap zoom in and screenblocks change can also work with the '+' key in numeric keyboard.
Added listcmds console command.
Chace camera view.
Added chasecamera console variable.
Added chasecamera_viewxy console variable.
Added chasecamera_viewz console variable.
Corrected small sky bug in Ultra Detail with zaxisshift.
Added criticalcpupriority console variable.
Added usetransparentsprites, dontusetransparentsprites, uselightboost and dontuselightboost command line parameters.
Added lightboostfactor command line parameter.
Added chasecamera and nochasecamera command line parameters.
Maximum display resolution increased to 2048x1536.
Added ENDOOM support.
Corrected menu flashes.
Fixed network support.


Version 0.8.4 build 317 - (18/11/2007)
-----------------------------------
Small changes to external texture cache system.
Fixed bug with old 1.1 and 1.2 version WADs.
Added option for automap rotation.

Version 0.8.4 build 313 - (11/10/2007)
-----------------------------------
Added mp3 music support.
Added usemp3 and preferemp3namesingamedirectory defaults.
Added defaults and setdefaults console commands for resetting all variables to default values.
Added default console command to set the default value for a specified variable. Use default * to reset variables to defaults.
More efficient palette change emulation for hi-resolution textures.
Better search algorythm inside PK3 directory stucture. 
Corrected sound clipping distance.
Corrected choppers cheat bug.
Added iddt console command.
Added idspispopd and idclip console commands.
Fixed bug with shareware 0.99 IWAD.
Modified games with shareware are allowed when in development mode.
Added cmdline console command.
Added miditempo default and console command for setting the mus lumps conversion tempo.
Added lowest resolution mode.
Added lowestres, lowestresolution console commands.
Added -lowestres command line parameter.
Added use32bittexturepaletteeffects console command, alias for 32bittexturepaletteeffects.
More readable menus, when in the menus the background turns darker.
Added shademenubackground variable.
Added compatibility menu. 
Added allowplayerjumps variable.
Zone size can be specified in default.cfg.
Added menu_main console command.
Added menu_newgame, menu_new console commands.
Added menu_options console command.
Added menu_optionsgeneral, menu_generaloptions console commands.
Added menu_optionsdisplay, menu_displayoptions, menu_display console commands.
Added menu_optionsdisplaydetail, menu_displaydetailoptions console commands.
Added menu_optionsdisplayappearence, menu_displayappearenceoptions, menu_displayappearence console commands.
Added menu_optionsdisplayadvanced, menu_displayadvancedoptions, menu_displayadvanced console commands.
Added menu_optionsdisplay32bit, menu_display32bitoptions, menu_display32bit console commands.
Added menu_optionssound, menu_soundoptions, menu_sound console commands.
Added menu_optionssoundvol, menu_soundvoloptions, menu_soundvol console commands.
Added menu_optionscompatibility, menu_compatibilityoptions, menu_compatibility console commands.
Added menu_optionscontrols, menu_controlsoptions, menu_controls console commands.
Added menu_optionssystem, menu_systemoptions, menu_system console commands.
Added menu_load, menu_loadgame console commands.
Added menu_save, menu_savegame console commands.
Corrected bug: Don't keep cheats in demo playback when keepcheatsinplayerreborn variable is set.
Added lumpsize, lumplength console commands.
Added lumpnum console command.
Added numlumps console command.
Added -autoscreenshot command line parameter.
Support for dehacked DEH and BEX files, to use them use -deh or -bex command line parameter.
Added DEH_ParseFile and BEX_ParseFile console commands.
Added DEH_ParseLump and BEX_ParseLump console commands.
Added DEH_PrintCurrentSettings, DEH_PrintSettings, BEX_PrintCurrentSettings and BEX_PrintSettings console command.
Added DEH_SaveCurrentSettings, DEH_SaveToFile, BEX_SaveCurrentSettings and BEX_SaveToFile console command.
Added -nowaddehacked command line parameter to prevent loading 'DEHACKED' lump inside wad.
Due to internal string manipulation are allowed DEHACKED strings bigger than original strings.
Music lumps does not require the 'D_' prefix.
Sound lumps does not require the 'DS' prefix.
Corrected bug: Cyberdeamon death in E4M2 will no longer trigger G_ExitLevel().
Added badbossdeathendsdoom1level varyable to end Doom1 levels if Cyberdeamon or Spider Die.
Added type and cat console commands.
Added -file1, -file2 .. -file9 command line parameters to specify priority PWADs.
Added -pakfile1, -pakfile2 .. -pakfile9 command line parameters to specify priority PAK files.
Maximum command line arguments increased from 256 to 1024 (mostly for usage with default.cmd or response files).
Added sfx support for external wav files inside pak/pk3 files.
Added sfx support for wav files inside WAD as lumps.
Added useexternalwav console command.
The minimum number of sound channels is set to 8.
Added MF_EX_FLOATBOB flag.
Added MF_EX_NORADIUSDMG flag.
Added MF_EX_FIRERESIST flag.
Added random sound selector subsystem, sound lumps with last character numeric can be in range '0' to '9' to define them.
Added MF_EX_RANDOMSEESOUND flag.
Added MF_EX_RANDOMPAINSOUND flag.
Added MF_EX_RANDOMATTACKSOUND flag.
Added MF_EX_RANDOMDEATHSOUND flag.
Added MF_EX_RANDOMACTIVESOUND flag.
Added MF_EX_RANDOMCUSTOMSOUND1 flag.
Added MF_EX_RANDOMCUSTOMSOUND2 flag.
Added MF_EX_RANDOMCUSTOMSOUND3 flag.
Added A_RandomPainSound mobj function.
Added A_RandomSeeSound mobj function.
Added A_RandomAttackSound mobj function.
Added A_RandomDeathSound mobj function.
Added A_RandomActiveSound mobj function.
Added A_RandomCustomSound1 mobj function.
Added A_RandomCustomSound2 mobj function.
Added A_RandomCustomSound3 mobj function.
Added A_RandomCustomSound mobj function.
Number of external wad files can exceed 64 now.
Added MF_EX_CUSTOMEXPLODE flag.
Added ExplosionDamage and ExplosionRadius mobj fields to use with A_Explode when MF_EX_CUSTOMEXPLODE flag is set.
Added MF_EX_BOSS flag.
Replaced original memory manager with FastMM.
Added lowgravity cheat (available trhu console only).
Added -singletics command line parameter to prevent adaptiveness of internal clock.
Added support for SNDINFO lump (sound aliases).
Added support for functions with custom parameters inside DECORATE lump.
Added A_Stop function.
Added A_Jump function.
Added MF_EX_FLOORHUGGER flag.
Added MF_EX_CEILINGHUGGER flag.
Added MF_EX_SEEKERMISSILE flag.
Added meleedamage mobj field.
Added A_CustomMissile, A_NoGravity, A_Gravity, A_NoBlocking, A_MeleeAttack mobj functions.
Added MF_EX_SPAWNFLOAT flag.
Added forum and forums console command, go to DelphiDoom forums.
Changed switcing fullscreen code to keep non-standard windowed modes.
Added MF_EX_DONTHURTSPECIES flag.
Added A_SpawnItem, A_SeekerMissile, A_CStaffMissileSlither and A_SetTranslucent mobj functions.
Transparency can be controlled with A_SetTranslucent() function.
Added suport for custom dropped items.
Added A_CustomBulletAttack, A_FadeOut, A_FadeIn and A_MissileAttack mobj functions.
Added MF_EX_LOWGRAVITY flag.
Added A_LowGravity, A_AdjustSideSpot, A_Countdown, A_FastChase mobj functions.
Added A_ThrustXY, A_ThrustZ, A_Turn mobj functions.
Added A_JumpIfCloser and A_JumpIfHealthLower mobj functions.
Added A_ScreamAndUnblock mobj function.
Added MF_EX_INVULNERABLE and MF_EX_RANDOMMELEESOUND flags.
Added A_PlayWeaponsound, A_SetInvulnerable, A_UnSetInvulnerable, A_RandomMeleeSound mobj functions.
Added A_FloatBob and A_NoFloatBob mobj functions.
Added A_Missile and A_NoMissile mobj functions.
Added MF_EX_DONOTREMOVE mobj flag.
Added MF_EX_DONTHURTSHOOTER mobj flag.
Added DEFAULTMISSILE and DEFAULTTRANSPARENT decorate keywords.
Added A_ComboAttack and A_BulletAttack mobj functions.
Added MF_EX_LOOKALLAROUND, MF_EX_GHOST, MF_EX_THRUGHOST and MF2_EX_MEDIUMGRAVITY mobj flags.
Added A_MediumGravity mobj function.
Added heal state for actors.
Added A_Wander mobj function.
Added random monster spawning option, use spawnrandommonsters console command to set.
Added -spawnrandommonsters and -nospawnrandommonsters command line parameters.
Added DEH_PrintActions, DEH_ShowActions, BEX_PrintActions and BEX_ShowActions console commands.
Added dehacked support for misc section.
Support for hi-res full screen texture replacements (TITLEPIC, HELP1, HELP2, CREDIT).

Version 0.8 build 311 - (12/9/2007)
-----------
Corrected external demo bug.
Controls Options menu added.
Added -invertmouselook, -noinvertmouselook, -invertmouseturn and -noinvertmouseturn command line parameters.
Added invertmouselook and invertmouseturn console commands.
Displays the correct intermission texts in Plutonia and TNT.
Improved hash function for column cache.
Added cachehit console command to display 32 bit texture cache hit factor.
Added resetcachehit console command to reset 32 bit texture cache hit counter.
Scales correctly external textures with wrong aspect.
More accurate scaling drawing menus (M_Drawer).
Added addpakfile, loadpakfile, addpak, loadpak console commands for adding at runtime PAK/PK3files. Also work with directories and wildcards. (zip files will be excluded).
Added cleartexturecache alias for clearcache console command.
Added resetcache and resettexturecache console command.
The 'exec' console command does not allow recursive calls of con files.
Improved column cache managment, increase cache hit propability.
MMX inline assembly optimization.
Added -nommx command line parameter to disable MMX and 3DNow extensions.
Added -iwad command line parameter alias for -mainwad.
Added -windowed command line parameter alias for -nofullscreen.
Added typeof console command.
Fuzz table optimization.
Added use32bitfuzzeffect console command, use old fuzz effect in 32 bit mode.
Added fullscreen console command.
Display menu options divided into submenus.
Added true 3d emulation.
Added fake3d and usefake3d console command.
Added -fake3d and -nofake3d command line parameters.
Added safemode console command. Type 'safemode true' if you have any problems like crashes.
More readable default.cfg file.
Added usemmx, mmx console commands.
Experimental multithreading support, disabled by default.
Added usemultithread console command.
Added preferetexturesnamesingamedirectory console command, prefer pk3 textures inside path containing the game name (DOOM, DOOM2, PLUTONIA, TNT).
Plays external demos with filenames bigger than 8 chars.
Changed sound pan to be more accurate.
Added ls console command, alias for dir.
Added pwd console command, alias for cd.
Added gotowebpage console command.
Added homepage console command.
Added help and documentation console command.
Added getlatestversion and downloadlatestversion console command.

Version 0.8 build 308 - (3/9/2007)
-----------
Memory allocated for flats, textures and sprites is now displayed correctly to stdout.
Now precache level in demos.
Launcher specified PWADs and PAKs do not conflict with default.cmd file.
Added useexternaltextures console command to enable/disable usage of external textures. 
Memory usage optimization when using PNG images.
PNG loading speed optimization.
Gamma correction table now affects also 32 bit textures.

-----------
Version 0.8 build 307 - (31/8/2007)
-----------
Added 32bittexturepaletteeffects console command, to enable/disable palette effects.
Display fps while playing.
Added suicide console command.
Added keepcheatsinplayerreborn default.
Added playermessage console command.
Corrected animated flats bug outside F_START and F_END lumps.
Restarting midi files inside PWADS does not freeze the game.
Better smoke spawning in lower textures (random spreading). 
Added support for PNG images.
Added support for hi resolution textures (walls). 
Added a launcher for easy start.

Version 0.8 build 303 - (27/8/2007)
-----------
Determine hi-resolution flats (raw format) inside wad.
Use flats from PWADS even if not inside F_START, F_END lumps.
Increased flat cache size limit.
In ultra resolution increased flat filtering level.
In high resolution does not make anymore 1-D wall filtering, instead use 2-D filtering in lower scale than ultra resolution.
Corrected multiline player messages display.
Added clearcache console command.
32 bit texture cache is now dynamically resized.
You can't disable thinkers during demo recording and playback.
Added execcommandfile console command alias for exec.
Added clearscreen console command alias for cls.
Added iddqd console command alias.
Added idfa console command alias.
Added idkfa console command alias.
Corrected again interpolation bug.
Fixed automap display bug.
Fixed screenshot bug while running from CD-ROM.
Playdemo console command plays also external demos stored in files. 
Added extremeflatfiltering console command.

Version 0.8 build 302 - (23/8/2007)
-----------------------------------
Due to a lot of changes in 3D Engine the source code is not compatible with Free Pascal Compiler. The source will compile but rendering problems will occur.
Fixed interpolation bug. Interpolation runs smoother.
Fixed jump problem that was occuring in some sectors with sky ceiling.
Better compatibility with old game demos.
Inline span and column drawing, gives about 5% faster rendering.
Memory stall crazy hack fixed performance problems in resolutions 1024x768 or higher.
Fixed problem in hi resolution modes while running in 16 bit color desktop.
More accurate fps counter.
Wipe screen works in 32 bit color mode.
Added line specials for right, down and up texture scrolling (142, 143, 144).
Added line specials for fast left, right, down and up texture scrolling (145, 146, 147, 148).
Corrected smoke spawning in lower textures. 
Added fixstallhack variable to avoid blanc line in the right side of the screen.
Multiline player messages.
Rendering engine now is configurable within the menus.
Added support for 512x512 hi-resolution flats.
Double scale for standard 64x64 flats in Hi and Ultra resolution.
Added -nosingledemo command line parameter to avoid exiting after playing an external demo.
Added 'playgame' and 'start' console commands, warping to level from console.
Appends command line parameters from file 'default.cmd'.
Added commandlineparams console command.

Version 0.7 build 286 - (19/7/2007)
-----------------------------------
Fixed masked columns light level in 32 bit color modes.
Fixed vision flats drawing bug in 32 bit color modes.
Fixed bug with doors that were not closing.
Blood spawns red light effect.

Version 0.7 build 283 - (16/7/2007)
-----------------------------------
Fixes:
-Corrected aspect ratio display. 
-Correted masked columns rendering bug.
-Corrected E4M8 end bug in ultimate Doom.
-Corrected floor filtering for flats.
New Features:
-Added zonefiledump console command.
-Added cmdlist console command.
-Runs about 5% faster in high and ultra resolution.
-General optimizations, runs smoother.
-Added detailLevel console command.
-Add medium resolution, classic Doom's high.
-Normal resolution now uses unfilterer textures with dynamic lighting.
-Programming: Speed optimizations.
-Added 'set usetransparentsprites' console command to enable/disable transparency.
-Added flag for transparent Rocket explosion.
-Added red, green, blue and yellow light flags.
-Added lightboostfactor console command to adjust light level.
-Added uselightboost console command to enable/disable lightboost.
-Added playdemo console command.
-Added loadgame console command.
-Added savegame console command.
-Added -nothinkers command line parameter.
-Added stopthinkers console command to stop all thinker functions.
-Added startthinkers console command to restore thinker functions.
-Added endgame console command.
-Added support for autoexec files.
-Added -autoexec command line parameter.
-Added exec console command to execute an autoexec file.
-Added printf console command.
-Added write console command.
-Added autorunmode in config file.
-Fixed frame interpolation support to exceed 35fps.
-Added interpolate console command.
-Added -interpolate and -nointerpolate command line parameters.
-Added pause_console command.
-Added -defaultvalues command line parameter to use default built-in config.
-Fixed display bug in 16 bit desktop when using windowed modes.
-Dropped items fall down to floor.
-Display automap overlayed with 3d view.
-Added allowautomapoverlay console command.
-Added rambo console command.
-Added givefullammo console command.
-Added givefullammoandkeys console command.
-Added dir console command.
-The commands set, get, list and cmdlist now work with wildcards also.
-Added allowlowdetails console command, if true allow Low and Medium detail level.
-Added Bitmap and Targa external textures support.
-Added PK3 and PAK file filesystem support. Use -pakfile command line to load a PK3/PAK file.
-While dying player turn the face towards ceiling.

Version 0.6 build 253 - (17/6/2007)
-----------------------------------
Added disk busy display
Statusbar now can draw minimum status display in full screen (press again'+' to clear)
Added 'set' console command.
Added 'get' console command.
Added High resolution mode (32 bit color rendering).
Added Ultra resolution mode (32 bit color rendering).
-hires, -normalres and -lowres -ultrares commandline parameters to override default resolution.
Changed screenshot code for TGA images, store a upper-left hand corner image.
Added fps console command to display fps.
Speed optimizations for hires and ultrares modes.
Now determines if runs from a cdrom without -cdrom parameter.
Frame interpolation to exceed the 35 fps game engine limit (still buggy, disabled by default).

Version 0.5 build 232 - (5/6/2007)
-----------------------------------
Programming Issues:
1.	Corrected FPC rendering problems.
2.	Changed network code, but still net support unavailable.
New Features:
1.	Added Quake-style console.
2.	Added console commands.
3.	Display stderr, stdout in console.
4.	Corrected mouse sensivity.
5.	Save game and Load game slots increased from 6 to 8.
6.	In automap is displayed the level time.

Version 0.4 build 225 - (29/5/2007)
-----------------------------------
Programming Issues:
1.	The source code now compiles also with FPC version 2.1.4. Some rendering problems with Free Pascal Compiler are corrected.
2.	Changed cheat code to ate the keypress event if in cheat pending state. Now Allows usage of all keys for gameplay.
Fixes:
1.	Fixed the sky texture bug. Now displays the correct sky texture depending on the episode.
2.	Fixed the change music cheat bug in shareware version, now does not change the music if music number is invalid.
3.	Fixed mouse support.
4.	Fixed joystick support.
5.	Fixed bug with unchanged textures in switches in Retail version.
6.	Fixed status bar drawing from older game versions. Now works with ancient version 0.99 shareware IWAD.
Changes:
1.	Look left and right unsing [HOME] and [PAGE UP] keys. 
2.	You can now jump using the 'a' key.
3.	The god mode cheat after the player's death reborns the player.
4.	No more mono audio, now supports 2 channels STEREO sound.
5.	Increased maximum numbers of visible sprites from 128 to 1024.
6.	Increased MAXDRAWSEGS from 1024 to 2048 (originally 256)
7.	Increased MAXPLATS from 30 to 512.
8.	Increased MAXLINEANIMS from 64 to 1024.
9.	Increased SAVEGAMESIZE from $2C000 to $80000
10.	Added -mouse, -nomouse, -joystick and -nojoystick command line parameters.
11.	Maximum external wad files increased from 20 to 64
12.	If there is not any known wad file in the current path tries to find one and load it. For example can be used with freedoom.wad without specifing -mainwad command line parameter.
13.	Default starting resolution is now 800x600.
14.	Supports up to 12 button joystick. 

Version 0.3 build 213 - (21/5/2007)
-----------------------------------
Lot of fixes: 
1.	Fixed weapon positioning.
2.	Fixed lighttable calculation.
3.	Fixed demo recording and playback.
4.	Fixed doom2 end bug.
5.	Fixed the "endless" ironfeet bug .
New features:
1.	Added -compatibilitymode and -nocompatibilitymode cmd parameters for old compatibility mode
-compatibilitymode -> Behaves as the original Doom (as possible)
-nocompatibilitymode -> Use some new features
2.	If you have the chainsaw you can now change back to fist by pressing "1". Use -compatibilitymode to suspend this.
3.	Option -mainwad from the command line to specify main wad file.
4.	Look up and down with z-axis shift.
5.	Added -nozaxisshift parameter to prevent z-axis shift.
6.	Added -zaxisshift parameter to force z-axis shift.
7.	Added PRINT SCREEN button for screenshot, also creates up to 1000 screenshots.
8.	Code: Now does not depend on Delphi's classes.pas unit, 
TStringList class replaced by TDStringList class in d_delphi.pas unit.

Version 0.2 build 129 - (1/12/2005)
-----------------------------------
Now runs in 16 bit desktop in nofullscreen mode.
You can specify width and height from command line.
Version 0.1 build 97 - (15/10/2005)
Some bug fixes.
Now starts at 1024x768 fullscreen by default, still hardcoded. 

Version 0.09 build 82 - (16/2/2005)
-----------------------------------
Corrected weapon positioning. Support for midi files inside PWADS. Fixed support for high and low resolution.

Version 0.08 build 63 - (14/2/2005)
-----------------------------------

This is to be considered as the first version to be stable enough for gameplay.
Vile bug fixed. Full cheat support. Tested with DOOM2.WAD. Music now works!

Version 0.07 build 34 - (12/2/2005)
-----------------------------------
Lot of bug fixes. 
First implementation of cheats. 
First major successful test with shareware Doom Episode 1, should work with registered Doom and Doom2, as well as TNT and PLUTONIA. 
Added option to type -nofullscreen parameter in command line to prevent full screen. 
Now starts at 640x480 fullscreen by default, still hardcoded. 

Version 0.06 - (9/2/2005)
-----------------------------------
Most stuff for multi resolution support done. Just experiment with SCREENWIDTH and SCREENHEIGHT constants in doomdef.pas. 
Added icon and version info.

Version 0.05 - (8/2/2005)
-----------------------------------
Bug fixes, first step to support higher resolutions.

Version 0.04 - (7/2/2005)
-----------------------------------
First public release of "Doom to Delphi Total Conversion".

Version 0.03 - (6/2/2005)
-----------------------------------
DirectDraw support for "Doom to Delphi Total Conversion".

Version 0.02 - (30/1/2005)
-----------------------------------
DirectSound support for "Doom to Delphi Total Conversion".

Version 0.01 - (28/1/2005)
-----------------------------------
Finished Doom to Delphi initial conversion.

Version 0.0 - (28/12/2004)
-----------------------------------
Started Doom to Delphi initial conversion.


Requirements
Windows operating system with DirectX 7.0.
Minimum Pentium,  32 MB RAM. 
For optimum performance a faster processor and AGP graphics adapter.
For 32 bit color software rendering with lighting effects Pentium 4, 2GHz.
DelphiDoom will take advantage of a Multiprocessor system.
For Hi resolution textures at least 256 MB RAM.

Acknowledgements/Thanks
-------
idSoftware for Doom
TeamTNT for BOOM 
Entryway for PrBoom-Plus
Randy Heit and Graf Zahl for zDoom
Andrew Apted for glbsp