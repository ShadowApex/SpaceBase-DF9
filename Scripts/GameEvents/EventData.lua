------------------------------------------------------------------------
-- The contents of this file are subject to the Common Public
-- Attribution License Version 1.0. (the "License"); you may not use
-- this file except in compliance with this License.  You may obtain a
-- copy of the License from the COPYING file included in this code
-- base. The License is based on the Mozilla Public License Version 1.1,
-- but Sections 14 and 15 have been added to cover use of software over
-- a computer network and provide for limited attribution for the
-- Original Developer. In addition, Exhibit A has been modified to be
-- consistent with Exhibit B.
--
-- Software distributed under the License is distributed on an "AS IS"
-- basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
-- the License for the specific language governing rights and
-- limitations under the License.
--
-- The Original Code is Spacebase DF-9.
--
-- The Original Developer is not the Initial Developer and is Bryce
-- Harrington of Derelict Games.

-- The Initial Developer of the Original Code is Double Fine
-- Productions, Inc.
--
-- The code in this file is the original work of Derelict Games,
-- authored by Bryce Harrington.
--
-- Copyright (c) 2015  Bryce Harrington <bryce@bryceharrington.org>
-- All Rights Reserved.
------------------------------------------------------------------------


local tEvents =
{
    CompoundEvent =
    {
    },

    -- Brings 1-2 new crew members to the station unless population cap
    -- has been reached.  Occurs more frequently in early portion of the game.
    immigrationEvents=
    {
    },

    -- Ship drops off 1-2 raiders who attack crew and/or try to board station
    -- if the station has at least 6 crew members.
    hostileImmigrationEvents=
    {
    },

    -- Attempts a dock a derelict to the station
    dockingEvents=
    {
    },

    traderEvents=
    {
    },
}

return t
