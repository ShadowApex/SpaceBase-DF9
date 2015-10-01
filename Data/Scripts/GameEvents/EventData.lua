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
    CompoundEvent = {
        {
            title='DOCKUI232TEXT', request='DOCKUI233TEXT',
            acceptButton='DOCKUI234TEXT', rejectButton='DOCKUI235TEXT',
            -- can't avoid final siege with dialog, just different responses
            acceptedResponse='DOCKUI236TEXT', acceptedResponseButton='DOCKUI238TEXT',
            rejectedResponse='DOCKUI237TEXT', rejectedResponseButton='DOCKUI238TEXT',
            screwYouResponse='DOCKUI237TEXT', screwYouResponseButton='DOCKUI238TEXT',
        },

        -- FIXME: Duplicate event to take the place of the dropped DF event
        {
            title='DOCKUI232TEXT', request='DOCKUI233TEXT',
            acceptButton='DOCKUI234TEXT', rejectButton='DOCKUI235TEXT',
            -- can't avoid final siege with dialog, just different responses
            acceptedResponse='DOCKUI236TEXT', acceptedResponseButton='DOCKUI238TEXT',
            rejectedResponse='DOCKUI237TEXT', rejectedResponseButton='DOCKUI238TEXT',
            screwYouResponse='DOCKUI237TEXT', screwYouResponseButton='DOCKUI238TEXT',
        },
    },

    -- Brings 1-2 new crew members to the station unless population cap
    -- has been reached.  Occurs more frequently in early portion of the game.
    immigrationEvents = {
        {   -- kessel runner
           title='EVENT002TEXT01', request='EVENT002TEXT02',
           acceptButton='EVENT002TEXT03', rejectButton='EVENT002TEXT04',
           acceptedResponse='EVENT002TEXT05', acceptedResponseButton='EVENT002TEXT06',
           rejectedResponse='EVENT002TEXT07', rejectedResponseButton='EVENT002TEXT08',
           screwYouResponse='EVENT002TEXT09', screwYouResponseButton='EVENT002TEXT10',
        },
        {   -- lister
           title='EVENT003TEXT01', request='EVENT003TEXT02',
           acceptButton='EVENT003TEXT03', rejectButton='EVENT003TEXT04',
           acceptedResponse='EVENT003TEXT05', acceptedResponseButton='EVENT003TEXT06',
           rejectedResponse='EVENT003TEXT07', rejectedResponseButton='EVENT003TEXT08',
           screwYouResponse='EVENT003TEXT09', screwYouResponseButton='EVENT003TEXT10',
        },
        {   --holiday confusion
           title='EVENT004TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT004TEXT03', rejectButton='EVENT004TEXT04',
           acceptedResponse='EVENT004TEXT05', acceptedResponseButton='EVENT004TEXT06',
           rejectedResponse='EVENT004TEXT07', rejectedResponseButton='EVENT004TEXT08',
           screwYouResponse='EVENT004TEXT09', screwYouResponseButton='EVENT004TEXT10',
        },
        {   --Dark Side of the Moon
           title='EVENT005TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT005TEXT03', rejectButton='EVENT005TEXT04',
           acceptedResponse='EVENT005TEXT05', acceptedResponseButton='EVENT005TEXT06',
           rejectedResponse='EVENT005TEXT07', rejectedResponseButton='EVENT005TEXT08',
           screwYouResponse='EVENT005TEXT09', screwYouResponseButton='EVENT005TEXT10',
        },
        {   --Hitchhikers Guide to the galaxy reference
           title='EVENT006TEXT01', request='EVENT006TEXT02',
           acceptButton='EVENT006TEXT03', rejectButton='EVENT006TEXT04',
           acceptedResponse='EVENT006TEXT05', acceptedResponseButton='EVENT006TEXT06',
           rejectedResponse='EVENT006TEXT07', rejectedResponseButton='EVENT006TEXT08',
           screwYouResponse='EVENT006TEXT09', screwYouResponseButton='EVENT006TEXT10',
        },
        {   --Bad thing happened
           title='EVENT007TEXT01', request='EVENT007TEXT02',
           acceptButton='EVENT007TEXT03', rejectButton='EVENT007TEXT04',
           acceptedResponse='EVENT007TEXT05', acceptedResponseButton='EVENT007TEXT06',
           rejectedResponse='EVENT007TEXT07', rejectedResponseButton='EVENT007TEXT08',
           screwYouResponse='EVENT007TEXT09', screwYouResponseButton='EVENT007TEXT10',
        },

        -- FIXME: Duplicate events to take the place of the dropped DF events
        {   -- kessel runner
           title='EVENT002TEXT01', request='EVENT002TEXT02',
           acceptButton='EVENT002TEXT03', rejectButton='EVENT002TEXT04',
           acceptedResponse='EVENT002TEXT05', acceptedResponseButton='EVENT002TEXT06',
           rejectedResponse='EVENT002TEXT07', rejectedResponseButton='EVENT002TEXT08',
           screwYouResponse='EVENT002TEXT09', screwYouResponseButton='EVENT002TEXT10',
        },
        {   -- lister
           title='EVENT003TEXT01', request='EVENT003TEXT02',
           acceptButton='EVENT003TEXT03', rejectButton='EVENT003TEXT04',
           acceptedResponse='EVENT003TEXT05', acceptedResponseButton='EVENT003TEXT06',
           rejectedResponse='EVENT003TEXT07', rejectedResponseButton='EVENT003TEXT08',
           screwYouResponse='EVENT003TEXT09', screwYouResponseButton='EVENT003TEXT10',
        },
        {   --holiday confusion
           title='EVENT004TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT004TEXT03', rejectButton='EVENT004TEXT04',
           acceptedResponse='EVENT004TEXT05', acceptedResponseButton='EVENT004TEXT06',
           rejectedResponse='EVENT004TEXT07', rejectedResponseButton='EVENT004TEXT08',
           screwYouResponse='EVENT004TEXT09', screwYouResponseButton='EVENT004TEXT10',
        },
        {   --Dark Side of the Moon
           title='EVENT005TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT005TEXT03', rejectButton='EVENT005TEXT04',
           acceptedResponse='EVENT005TEXT05', acceptedResponseButton='EVENT005TEXT06',
           rejectedResponse='EVENT005TEXT07', rejectedResponseButton='EVENT005TEXT08',
           screwYouResponse='EVENT005TEXT09', screwYouResponseButton='EVENT005TEXT10',
        },
        {   --Hitchhikers Guide to the galaxy reference
           title='EVENT006TEXT01', request='EVENT006TEXT02',
           acceptButton='EVENT006TEXT03', rejectButton='EVENT006TEXT04',
           acceptedResponse='EVENT006TEXT05', acceptedResponseButton='EVENT006TEXT06',
           rejectedResponse='EVENT006TEXT07', rejectedResponseButton='EVENT006TEXT08',
           screwYouResponse='EVENT006TEXT09', screwYouResponseButton='EVENT006TEXT10',
        },
        {   --Bad thing happened
           title='EVENT007TEXT01', request='EVENT007TEXT02',
           acceptButton='EVENT007TEXT03', rejectButton='EVENT007TEXT04',
           acceptedResponse='EVENT007TEXT05', acceptedResponseButton='EVENT007TEXT06',
           rejectedResponse='EVENT007TEXT07', rejectedResponseButton='EVENT007TEXT08',
           screwYouResponse='EVENT007TEXT09', screwYouResponseButton='EVENT007TEXT10',
        },
        {   -- kessel runner
           title='EVENT002TEXT01', request='EVENT002TEXT02',
           acceptButton='EVENT002TEXT03', rejectButton='EVENT002TEXT04',
           acceptedResponse='EVENT002TEXT05', acceptedResponseButton='EVENT002TEXT06',
           rejectedResponse='EVENT002TEXT07', rejectedResponseButton='EVENT002TEXT08',
           screwYouResponse='EVENT002TEXT09', screwYouResponseButton='EVENT002TEXT10',
        },
        {   -- lister
           title='EVENT003TEXT01', request='EVENT003TEXT02',
           acceptButton='EVENT003TEXT03', rejectButton='EVENT003TEXT04',
           acceptedResponse='EVENT003TEXT05', acceptedResponseButton='EVENT003TEXT06',
           rejectedResponse='EVENT003TEXT07', rejectedResponseButton='EVENT003TEXT08',
           screwYouResponse='EVENT003TEXT09', screwYouResponseButton='EVENT003TEXT10',
        },
        {   --holiday confusion
           title='EVENT004TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT004TEXT03', rejectButton='EVENT004TEXT04',
           acceptedResponse='EVENT004TEXT05', acceptedResponseButton='EVENT004TEXT06',
           rejectedResponse='EVENT004TEXT07', rejectedResponseButton='EVENT004TEXT08',
           screwYouResponse='EVENT004TEXT09', screwYouResponseButton='EVENT004TEXT10',
        },
        {   --Dark Side of the Moon
           title='EVENT005TEXT01', request='EVENT004TEXT02',
           acceptButton='EVENT005TEXT03', rejectButton='EVENT005TEXT04',
           acceptedResponse='EVENT005TEXT05', acceptedResponseButton='EVENT005TEXT06',
           rejectedResponse='EVENT005TEXT07', rejectedResponseButton='EVENT005TEXT08',
           screwYouResponse='EVENT005TEXT09', screwYouResponseButton='EVENT005TEXT10',
        },
    },

    -- Ship drops off 1-2 raiders who attack crew and/or try to board station
    -- if the station has at least 6 crew members.
    hostileImmigrationEvents = {
        {   --hero trap.
           title='EVENT008TEXT01', request='EVENT008TEXT02',
           acceptButton='EVENT008TEXT03', rejectButton='EVENT008TEXT04',
           acceptedResponse='EVENT008TEXT05', acceptedResponseButton='EVENT008TEXT06',
           rejectedResponse='EVENT008TEXT07', rejectedResponseButton='EVENT008TEXT08',
           screwYouResponse='EVENT008TEXT09', screwYouResponseButton='EVENT008TEXT10',
        },

        -- FIXME: Duplicate events to take the place of the dropped DF events
        {   --hero trap.
           title='EVENT008TEXT01', request='EVENT008TEXT02',
           acceptButton='EVENT008TEXT03', rejectButton='EVENT008TEXT04',
           acceptedResponse='EVENT008TEXT05', acceptedResponseButton='EVENT008TEXT06',
           rejectedResponse='EVENT008TEXT07', rejectedResponseButton='EVENT008TEXT08',
           screwYouResponse='EVENT008TEXT09', screwYouResponseButton='EVENT008TEXT10',
        },
        {   --hero trap.
           title='EVENT008TEXT01', request='EVENT008TEXT02',
           acceptButton='EVENT008TEXT03', rejectButton='EVENT008TEXT04',
           acceptedResponse='EVENT008TEXT05', acceptedResponseButton='EVENT008TEXT06',
           rejectedResponse='EVENT008TEXT07', rejectedResponseButton='EVENT008TEXT08',
           screwYouResponse='EVENT008TEXT09', screwYouResponseButton='EVENT008TEXT10',
        },
        {   --hero trap.
           title='EVENT008TEXT01', request='EVENT008TEXT02',
           acceptButton='EVENT008TEXT03', rejectButton='EVENT008TEXT04',
           acceptedResponse='EVENT008TEXT05', acceptedResponseButton='EVENT008TEXT06',
           rejectedResponse='EVENT008TEXT07', rejectedResponseButton='EVENT008TEXT08',
           screwYouResponse='EVENT008TEXT09', screwYouResponseButton='EVENT008TEXT10',
        },
    },

    -- Attempts a dock a derelict to the station
    dockingEvents = {
        ambiguous={
            {
                -- Unknown delivery for Mr. Mumble
                title='EVENT009TEXT01', request='EVENT009TEXT02',
                acceptButton='EVENT009TEXT03', rejectButton='EVENT009TEXT04',
                acceptedResponse='EVENT009TEXT05', acceptedResponseButton='EVENT009TEXT06',
                rejectedResponse='EVENT009TEXT07', rejectedResponseButton='EVENT009TEXT08',
                screwYouResponse='EVENT009TEXT09', screwYouResponseButton='EVENT009TEXT10',
            },

            -- FIXME: Duplicate events to take the place of the dropped DF events
            {
                -- Unknown delivery for Mr. Mumble
                title='EVENT009TEXT01', request='EVENT009TEXT02',
                acceptButton='EVENT009TEXT03', rejectButton='EVENT009TEXT04',
                acceptedResponse='EVENT009TEXT05', acceptedResponseButton='EVENT009TEXT06',
                rejectedResponse='EVENT009TEXT07', rejectedResponseButton='EVENT009TEXT08',
                screwYouResponse='EVENT009TEXT09', screwYouResponseButton='EVENT009TEXT10',
            },
        },
        hostile={
            {
                --In the way of a hostile construction fleet
                title='EVENT010TEXT01', request='EVENT010TEXT02',
                acceptButton='EVENT010TEXT03', rejectButton='EVENT010TEXT04',
                acceptedResponse='EVENT010TEXT05', acceptedResponseButton='EVENT010TEXT06',
                rejectedResponse='EVENT010TEXT07', rejectedResponseButton='EVENT010TEXT08',
                screwYouResponse='EVENT010TEXT09', screwYouResponseButton='EVENT010TEXT10',
            },

            -- FIXME: Duplicate events to take the place of the dropped DF events
            {
                --In the way of a hostile construction fleet
                title='EVENT010TEXT01', request='EVENT010TEXT02',
                acceptButton='EVENT010TEXT03', rejectButton='EVENT010TEXT04',
                acceptedResponse='EVENT010TEXT05', acceptedResponseButton='EVENT010TEXT06',
                rejectedResponse='EVENT010TEXT07', rejectedResponseButton='EVENT010TEXT08',
                screwYouResponse='EVENT010TEXT09', screwYouResponseButton='EVENT010TEXT10',
            },
            {
                --In the way of a hostile construction fleet
                title='EVENT010TEXT01', request='EVENT010TEXT02',
                acceptButton='EVENT010TEXT03', rejectButton='EVENT010TEXT04',
                acceptedResponse='EVENT010TEXT05', acceptedResponseButton='EVENT010TEXT06',
                rejectedResponse='EVENT010TEXT07', rejectedResponseButton='EVENT010TEXT08',
                screwYouResponse='EVENT010TEXT09', screwYouResponseButton='EVENT010TEXT10',
            },
        },
        {
            -- lottery winner
            title='EVENT011TEXT01', request='EVENT011TEXT02',
            acceptButton='EVENT011TEXT03', rejectButton='EVENT011TEXT04',
            acceptedResponse='EVENT011TEXT05', acceptedResponseButton='EVENT011TEXT06',
            rejectedResponse='EVENT011TEXT07', rejectedResponseButton='EVENT011TEXT08',
            screwYouResponse='EVENT011TEXT09', screwYouResponseButton='EVENT011TEXT10',
        },

        -- FIXME: Duplicate events to take the place of the dropped DF events
        {
            -- lottery winner
            title='EVENT011TEXT01', request='EVENT011TEXT02',
            acceptButton='EVENT011TEXT03', rejectButton='EVENT011TEXT04',
            acceptedResponse='EVENT011TEXT05', acceptedResponseButton='EVENT011TEXT06',
            rejectedResponse='EVENT011TEXT07', rejectedResponseButton='EVENT011TEXT08',
            screwYouResponse='EVENT011TEXT09', screwYouResponseButton='EVENT011TEXT10',
        },
    },

    -- Introduces a trader
    traderEvents = {
        {   -- vacuum trader
            title='TRADE001TEXT', request='TRADE002TEXT',
            acceptButton='TRADE003TEXT', rejectButton='TRADE004TEXT',
            acceptedResponse='TRADE005TEXT', acceptedResponseButton='TRADE006TEXT',
            rejectedResponse='TRADE007TEXT', rejectedResponseButton='TRADE008TEXT',
            screwYouResponse='TRADE009TEXT', screwYouResponseButton='TRADE010TEXT',
        },
    },
}

return tEvents
