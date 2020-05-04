-------------------------------------------------------------------------------------------
-- 
-- Arcade: Atari Tetris  for MiSTer by MiSTer-X
-- 11 December 2019
-- From: https://github.com/MrX-8B/MiSTer-Arcade-AtariTetris
-- 
-------------------------------------------------------------------------------------------
-- 65xx compatible microprocessor core
----------------------------------------------
-- FPGAARCADE SVN: $Id: T65.vhd 1347 2015-05-27 20:07:34Z wolfgang.scherr $
--
-- Copyright (c) 2002...2015
--               Daniel Wallner (jesus <at> opencores <dot> org)
--               Mike Johnson   (mikej <at> fpgaarcade <dot> com)
--               Wolfgang Scherr (WoS <at> pin4 <dot> at>
--               Morten Leikvoll ()
-------------------------------------------------------------------------------------------
-- Pokey
----------------------------------------------
-- (c) 2013 mark watson
-------------------------------------------------------------------------------------------
-- Diagonal Input
----------------------------------------------
-- (c) 2019 Eniva  https://github.com/eniva/fpga-controls
-------------------------------------------------------------------------------------------
-- Tetris (and cocktail version) MRA files
----------------------------------------------
-- written by Bruno Silva (@eubrunosilvapt)
-------------------------------------------------------------------------------------------
--
-- 
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   DOWN,LEFT,RIGHT arrows : Movements
--   SPACE       : Rotate
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   F,D,G       : Player 2 Movements
--   A           : Player 2 Rotate
--
-- Joystick support.
--
--
-------------------------------------------------------------------------------------------


                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
