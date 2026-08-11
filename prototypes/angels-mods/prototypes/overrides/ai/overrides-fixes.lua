TECHNOLOGY('advanced-material-processing'):add_prereq('angels-components-construction-2'):remove_prereq('py-science-pack-1')
    TECHNOLOGY('angels-components-mechanical-2'):remove_pack('logistic-science-pack'):remove_prereq('logistic-science-pack')
    TECHNOLOGY('fluid-processing-machines-1'):add_prereq('angels-components-construction-2'):remove_prereq('py-science-pack-1')
    -- these two techs only exist under pyalienlife, which angelsindustries does not bring along
    if mods['pyalienlife'] then
        TECHNOLOGY('electric-mining-drill'):add_prereq('angels-components-mechanical-2'):remove_prereq('py-science-pack-1')
        TECHNOLOGY('crusher-2'):add_prereq('angels-components-construction-2'):remove_prereq('py-science-pack-1')
    end
    -- py-burner is pyindustry's, likewise
    if mods['pyindustry'] then
        TECHNOLOGY('py-burner'):add_prereq('angels-components-construction-2'):remove_prereq('py-science-pack-1')
    end