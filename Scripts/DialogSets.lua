local Character=require('CharacterConstants')
local MiscUtil=require('MiscUtil')

local t=
{
    CompoundEvent=
    {
        {
            title='DOCKUI145TEXT',request='DOCKUI146TEXT',acceptButton='DOCKUI147TEXT',rejectButton='DOCKUI148TEXT',
			-- can't avoid final siege with dialog, just different responses
            acceptedResponse='DOCKUI150TEXT',acceptedResponseButton='DOCKUI149TEXT',
            rejectedResponse='DOCKUI151TEXT',rejectedResponseButton='DOCKUI149TEXT',
            screwYouResponse='DOCKUI151TEXT',screwYouResponseButton='DOCKUI149TEXT',
        },
    },

    -- Brings 1-2 new crew members to the station unless population cap
    -- has been reached.  Occurs more frequently in early portion of the game.
    immigrationEvents=
    {
        {   -- lost in space         
            title='DOCKUI006TEXT',request='DOCKUI007TEXT',acceptButton='DOCKUI028TEXT',rejectButton='DOCKUI029TEXT',
            acceptedResponse='DOCKUI030TEXT',acceptedResponseButton='DOCKUI035TEXT',
            rejectedResponse='DOCKUI031TEXT',rejectedResponseButton='DOCKUI034TEXT',
            screwYouResponse='DOCKUI033TEXT',screwYouResponseButton='DOCKUI033TEXT',
        },
        {   -- just out of cryogenesis         
            title='DOCKUI052TEXT',request='DOCKUI047TEXT',acceptButton='DOCKUI048TEXT',rejectButton='DOCKUI049TEXT',
            acceptedResponse='DOCKUI050TEXT',acceptedResponseButton='DOCKUI054TEXT',
            rejectedResponse='DOCKUI051TEXT',rejectedResponseButton='DOCKUI055TEXT',
            screwYouResponse='DOCKUI053TEXT',screwYouResponseButton='DOCKUI056TEXT',
        },
        {   -- apt seekers         
            title='DOCKUI057TEXT',request='DOCKUI058TEXT',acceptButton='DOCKUI061TEXT',rejectButton='DOCKUI059TEXT',
            acceptedResponse='DOCKUI062TEXT',acceptedResponseButton='DOCKUI064TEXT',
            rejectedResponse='DOCKUI060TEXT',rejectedResponseButton='DOCKUI063TEXT',
            screwYouResponse='DOCKUI065TEXT',screwYouResponseButton='DOCKUI066TEXT',
        },
        {   -- cruisin' around         
            title='DOCKUI068TEXT',request='DOCKUI067TEXT',acceptButton='DOCKUI069TEXT',rejectButton='DOCKUI070TEXT',
            acceptedResponse='DOCKUI071TEXT',acceptedResponseButton='DOCKUI074TEXT',
            rejectedResponse='DOCKUI072TEXT',rejectedResponseButton='DOCKUI075TEXT',
            screwYouResponse='DOCKUI073TEXT',screwYouResponseButton='DOCKUI076TEXT',
        },
        {   -- ambiguous request         
            title='DOCKUI079TEXT',request='DOCKUI012TEXT',acceptButton='DOCKUI077TEXT',rejectButton='DOCKUI008TEXT',
            acceptedResponse='DOCKUI009TEXT',acceptedResponseButton='DOCKUI078TEXT',
            rejectedResponse='DOCKUI080TEXT',rejectedResponseButton='DOCKUI081TEXT',
            screwYouResponse='DOCKUI010TEXT',screwYouResponseButton='DOCKUI082TEXT',
        },
        {   -- robot sounding request        
            title='DOCKUI083TEXT',request='DOCKUI084TEXT',acceptButton='DOCKUI085TEXT',rejectButton='DOCKUI086TEXT',
            acceptedResponse='DOCKUI087TEXT',acceptedResponseButton='DOCKUI088TEXT',
            rejectedResponse='DOCKUI089TEXT',rejectedResponseButton='DOCKUI090TEXT',
            screwYouResponse='DOCKUI091TEXT',screwYouResponseButton='DOCKUI092TEXT',
        },
        {   -- creepily enthusiastic request
            title='DOCKUI124TEXT',request='DOCKUI125TEXT',acceptButton='DOCKUI127TEXT',rejectButton='DOCKUI126TEXT',
            acceptedResponse='DOCKUI128TEXT',acceptedResponseButton='DOCKUI130TEXT',
            rejectedResponse='DOCKUI129TEXT',rejectedResponseButton='DOCKUI131TEXT',
            screwYouResponse='DOCKUI132TEXT',screwYouResponseButton='DOCKUI133TEXT',
        },
        {   -- too cool 4 skool request
            title='DOCKUI134TEXT',request='DOCKUI135TEXT',acceptButton='DOCKUI136TEXT',rejectButton='DOCKUI139TEXT',
            acceptedResponse='DOCKUI137TEXT',acceptedResponseButton='DOCKUI138TEXT',
            rejectedResponse='DOCKUI140TEXT',rejectedResponseButton='DOCKUI141TEXT',
            screwYouResponse='DOCKUI142TEXT',screwYouResponseButton='DOCKUI143TEXT',
        },

	{   --
           title='DOCKUI152TEXT',request='DOCKUI153TEXT',acceptButton='DOCKUI154TEXT',rejectButton='DOCKUI155TEXT',
           acceptedResponse='DOCKUI156TEXT',acceptedResponseButton='DOCKUI157TEXT',
           rejectedResponse='DOCKUI158TEXT',rejectedResponseButton='DOCKUI159TEXT',
           screwYouResponse='DOCKUI160TEXT',screwYouResponseButton='DOCKUI161TEXT',
	},
	{   --
           title='DOCKUI162TEXT',request='DOCKUI163TEXT',acceptButton='DOCKUI164TEXT',rejectButton='DOCKUI165TEXT',
           acceptedResponse='DOCKUI166TEXT',acceptedResponseButton='DOCKUI167TEXT',
           rejectedResponse='DOCKUI168TEXT',rejectedResponseButton='DOCKUI169TEXT',
           screwYouResponse='DOCKUI170TEXT',screwYouResponseButton='DOCKUI171TEXT',
	},
	{   --
           title='DOCKUI172TEXT',request='DOCKUI173TEXT',acceptButton='DOCKUI174TEXT',rejectButton='DOCKUI175TEXT',
           acceptedResponse='DOCKUI176TEXT',acceptedResponseButton='DOCKUI177TEXT',
           rejectedResponse='DOCKUI178TEXT',rejectedResponseButton='DOCKUI179TEXT',
           screwYouResponse='DOCKUI180TEXT',screwYouResponseButton='DOCKUI181TEXT',
	},
	{   --
           title='DOCKUI182TEXT',request='DOCKUI183TEXT',acceptButton='DOCKUI184TEXT',rejectButton='DOCKUI185TEXT',
           acceptedResponse='DOCKUI186TEXT',acceptedResponseButton='DOCKUI187TEXT',
           rejectedResponse='DOCKUI188TEXT',rejectedResponseButton='DOCKUI189TEXT',
           screwYouResponse='DOCKUI190TEXT',screwYouResponseButton='DOCKUI191TEXT',
	},
	{   --Hitchhikers Guide to the galaxy reference
           title='DOCKUI192TEXT',request='DOCKUI193TEXT',acceptButton='DOCKUI194TEXT',rejectButton='DOCKUI195TEXT',
           acceptedResponse='DOCKUI196TEXT',acceptedResponseButton='DOCKUI197TEXT',
           rejectedResponse='DOCKUI198TEXT',rejectedResponseButton='DOCKUI199TEXT',
           screwYouResponse='DOCKUI200TEXT',screwYouResponseButton='DOCKUI201TEXT',
	},
	{   --Bad thing happened
           title='DOCKUI212TEXT',request='DOCKUI213TEXT',acceptButton='DOCKUI214TEXT',rejectButton='DOCKUI215TEXT',
           acceptedResponse='DOCKUI216TEXT',acceptedResponseButton='DOCKUI217TEXT',
           rejectedResponse='DOCKUI218TEXT',rejectedResponseButton='DOCKUI219TEXT',
           screwYouResponse='DOCKUI220TEXT',screwYouResponseButton='DOCKUI221TEXT',
	},
    },
	
    -- Ship drops off 1-2 raiders who attack crew and/or try to board station
    -- if the station has at least 6 crew members.
	hostileImmigrationEvents=
    {
        {
            -- fake service call
            title='DOCKUI093TEXT',request='DOCKUI094TEXT',acceptButton='DOCKUI095TEXT',rejectButton='DOCKUI096TEXT',
            acceptedResponse='DOCKUI097TEXT',acceptedResponseButton='DOCKUI101TEXT',
            rejectedResponse='DOCKUI099TEXT',rejectedResponseButton='DOCKUI100TEXT',
            screwYouResponse='DOCKUI098TEXT',screwYouResponseButton='DOCKUI102TEXT',
        },
        {   -- jerks
            title='DOCKUI105TEXT',request='DOCKUI104TEXT',acceptButton='DOCKUI106TEXT',rejectButton='DOCKUI107TEXT',
            acceptedResponse='DOCKUI108TEXT',acceptedResponseButton='DOCKUI109TEXT',
            rejectedResponse='DOCKUI112TEXT',rejectedResponseButton='DOCKUI113TEXT',
            screwYouResponse='DOCKUI110TEXT',screwYouResponseButton='DOCKUI111TEXT',
        },
        {   -- inexperienced raiders
            title='DOCKUI114TEXT',request='DOCKUI115TEXT',acceptButton='DOCKUI116TEXT',rejectButton='DOCKUI117TEXT',
            acceptedResponse='DOCKUI118TEXT',acceptedResponseButton='DOCKUI119TEXT',
            rejectedResponse='DOCKUI120TEXT',rejectedResponseButton='DOCKUI121TEXT',
            screwYouResponse='DOCKUI122TEXT',screwYouResponseButton='DOCKUI123TEXT',
        },
		{   --hero trap.
           title='DOCKUI222TEXT',request='DOCKUI223TEXT',acceptButton='DOCKUI224TEXT',rejectButton='DOCKUI225TEXT',
           acceptedResponse='DOCKUI226TEXT',acceptedResponseButton='DOCKUI227TEXT',
           rejectedResponse='DOCKUI228TEXT',rejectedResponseButton='DOCKUI229TEXT',
           screwYouResponse='DOCKUI230TEXT',screwYouResponseButton='DOCKUI231TEXT',
	},
    },

    -- Attempts a dock a derelict to the station
    dockingEvents=
    {
        ambiguous={
            {   --jake's original ambiguous offering, hostile OR friendly
                title='DOCKUI002TEXT',request='DOCKUI003TEXT',acceptButton='DOCKUI040TEXT',rejectButton='DOCKUI041TEXT',
                acceptedResponse='DOCKUI042TEXT',acceptedResponseButton='DOCKUI046TEXT',
                rejectedResponse='DOCKUI043TEXT',rejectedResponseButton='DOCKUI103TEXT',
                screwYouResponse='DOCKUI044TEXT',screwYouResponseButton='DOCKUI045TEXT',
            },
        },
        hostile={
            {
                --space pirates flexin' nuts, hostile only
                title='DOCKUI017TEXT',request='DOCKUI011TEXT',acceptButton='DOCKUI021TEXT',rejectButton='DOCKUI022TEXT',
                acceptedResponse='DOCKUI019TEXT',acceptedResponseButton='DOCKUI038TEXT',
                rejectedResponse='DOCKUI023TEXT',rejectedResponseButton='DOCKUI039TEXT',
                screwYouResponse='DOCKUI020TEXT',screwYouResponseButton='DOCKUI024TEXT',
            },
            {
                --offended zealots, hostile only
                title='DOCKUI018TEXT',request='DOCKUI013TEXT',acceptButton='DOCKUI025TEXT',rejectButton='DOCKUI026TEXT',
                acceptedResponse='DOCKUI014TEXT',acceptedResponseButton='DOCKUI037TEXT',
                rejectedResponse='DOCKUI016TEXT',rejectedResponseButton='DOCKUI036TEXT',
                screwYouResponse='DOCKUI015TEXT',screwYouResponseButton='DOCKUI027TEXT',
            },
		    {
                --In the way of a hostile construction fleet
                title='DOCKUI202TEXT',request='DOCKUI203TEXT',acceptButton='DOCKUI204TEXT',rejectButton='DOCKUI205TEXT',
                acceptedResponse='DOCKUI206TEXT',acceptedResponseButton='DOCKUI207TEXT',
                rejectedResponse='DOCKUI208TEXT',rejectedResponseButton='DOCKUI209TEXT',
                screwYouResponse='DOCKUI210TEXT',screwYouResponseButton='DOCKUI211TEXT',
            },
        },
        {
            --fake service call
            title='DOCKUI093TEXT',request='DOCKUI094TEXT',acceptButton='DOCKUI095TEXT',rejectButton='DOCKUI096TEXT',
            acceptedResponse='DOCKUI097TEXT',acceptedResponseButton='DOCKUI101TEXT',
            rejectedResponse='DOCKUI099TEXT',rejectedResponseButton='DOCKUI100TEXT',
            screwYouResponse='DOCKUI098TEXT',screwYouResponseButton='DOCKUI102TEXT',
        },
    },

    traderEvents=
    {
        {   -- vacuum trader
            title='TRADE001TEXT',request='TRADE002TEXT',acceptButton='TRADE003TEXT',rejectButton='TRADE004TEXT',
            acceptedResponse='TRADE005TEXT',acceptedResponseButton='TRADE006TEXT',
            rejectedResponse='TRADE007TEXT',rejectedResponseButton='TRADE008TEXT',
            screwYouResponse='TRADE009TEXT',screwYouResponseButton='TRADE010TEXT',
        },   
    },    
}

return t
