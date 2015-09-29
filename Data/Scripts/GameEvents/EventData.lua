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
    },

    -- Brings 1-2 new crew members to the station unless population cap
    -- has been reached.  Occurs more frequently in early portion of the game.
    immigrationEvents = {
        {   -- kessel runner
           title='DOCKUI152TEXT', request='DOCKUI153TEXT',
           acceptButton='DOCKUI154TEXT', rejectButton='DOCKUI155TEXT',
           acceptedResponse='DOCKUI156TEXT', acceptedResponseButton='DOCKUI157TEXT',
           rejectedResponse='DOCKUI158TEXT', rejectedResponseButton='DOCKUI159TEXT',
           screwYouResponse='DOCKUI160TEXT', screwYouResponseButton='DOCKUI161TEXT',
        },
        {   -- lister
           title='DOCKUI162TEXT', request='DOCKUI163TEXT',
           acceptButton='DOCKUI164TEXT', rejectButton='DOCKUI165TEXT',
           acceptedResponse='DOCKUI166TEXT', acceptedResponseButton='DOCKUI167TEXT',
           rejectedResponse='DOCKUI168TEXT', rejectedResponseButton='DOCKUI169TEXT',
           screwYouResponse='DOCKUI170TEXT', screwYouResponseButton='DOCKUI171TEXT',
        },
        {   --holiday confusion
           title='DOCKUI172TEXT', request='DOCKUI173TEXT',
           acceptButton='DOCKUI174TEXT', rejectButton='DOCKUI175TEXT',
           acceptedResponse='DOCKUI176TEXT', acceptedResponseButton='DOCKUI177TEXT',
           rejectedResponse='DOCKUI178TEXT', rejectedResponseButton='DOCKUI179TEXT',
           screwYouResponse='DOCKUI180TEXT', screwYouResponseButton='DOCKUI181TEXT',
        },
        {   --Dark Side of the Moon
           title='DOCKUI182TEXT', request='DOCKUI183TEXT',
           acceptButton='DOCKUI184TEXT', rejectButton='DOCKUI185TEXT',
           acceptedResponse='DOCKUI186TEXT', acceptedResponseButton='DOCKUI187TEXT',
           rejectedResponse='DOCKUI188TEXT', rejectedResponseButton='DOCKUI189TEXT',
           screwYouResponse='DOCKUI190TEXT', screwYouResponseButton='DOCKUI191TEXT',
        },
        {   --Hitchhikers Guide to the galaxy reference
           title='DOCKUI192TEXT', request='DOCKUI193TEXT',
           acceptButton='DOCKUI194TEXT', rejectButton='DOCKUI195TEXT',
           acceptedResponse='DOCKUI196TEXT', acceptedResponseButton='DOCKUI197TEXT',
           rejectedResponse='DOCKUI198TEXT', rejectedResponseButton='DOCKUI199TEXT',
           screwYouResponse='DOCKUI200TEXT', screwYouResponseButton='DOCKUI201TEXT',
        },
        {   --Bad thing happened
           title='DOCKUI212TEXT', request='DOCKUI213TEXT',
           acceptButton='DOCKUI214TEXT', rejectButton='DOCKUI215TEXT',
           acceptedResponse='DOCKUI216TEXT', acceptedResponseButton='DOCKUI217TEXT',
           rejectedResponse='DOCKUI218TEXT', rejectedResponseButton='DOCKUI219TEXT',
           screwYouResponse='DOCKUI220TEXT', screwYouResponseButton='DOCKUI221TEXT',
        },
    },

    -- Ship drops off 1-2 raiders who attack crew and/or try to board station
    -- if the station has at least 6 crew members.
    hostileImmigrationEvents = {
        {   --hero trap.
           title='DOCKUI222TEXT', request='DOCKUI223TEXT',
           acceptButton='DOCKUI224TEXT', rejectButton='DOCKUI225TEXT',
           acceptedResponse='DOCKUI226TEXT', acceptedResponseButton='DOCKUI227TEXT',
           rejectedResponse='DOCKUI228TEXT', rejectedResponseButton='DOCKUI229TEXT',
           screwYouResponse='DOCKUI230TEXT', screwYouResponseButton='DOCKUI231TEXT',
        },
    },

    -- Attempts a dock a derelict to the station
    dockingEvents = {
        ambiguous={
            {
                -- Unknown delivery for Mr. Mumble
                title='DOCKUI239TEXT', request='DOCKUI240TEXT',
                acceptButton='DOCKUI241TEXT', rejectButton='DOCKUI242TEXT',
                acceptedResponse='DOCKUI243TEXT', acceptedResponseButton='DOCKUI246TEXT',
                rejectedResponse='DOCKUI244TEXT', rejectedResponseButton='DOCKUI247TEXT',
                screwYouResponse='DOCKUI245TEXT', screwYouResponseButton='DOCKUI248TEXT',
            },
        },
        hostile={
            {
                --In the way of a hostile construction fleet
                title='DOCKUI202TEXT', request='DOCKUI203TEXT',
                acceptButton='DOCKUI204TEXT', rejectButton='DOCKUI205TEXT',
                acceptedResponse='DOCKUI206TEXT', acceptedResponseButton='DOCKUI207TEXT',
                rejectedResponse='DOCKUI208TEXT', rejectedResponseButton='DOCKUI209TEXT',
                screwYouResponse='DOCKUI210TEXT', screwYouResponseButton='DOCKUI211TEXT',
            },
        },
        {
            -- lottery winner
            title='DOCKUI249TEXT', request='DOCKUI250TEXT',
            acceptButton='DOCKUI251TEXT', rejectButton='DOCKUI252TEXT',
            acceptedResponse='DOCKUI253TEXT', acceptedResponseButton='DOCKUI256TEXT',
            rejectedResponse='DOCKUI254TEXT', rejectedResponseButton='DOCKUI257TEXT',
            screwYouResponse='DOCKUI255TEXT', screwYouResponseButton='DOCKUI258TEXT',
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

return t
