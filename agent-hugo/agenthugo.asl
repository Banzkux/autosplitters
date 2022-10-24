state("AgentHugo")
{
    bool isNotLoading : 0x36A598;
    int drNogoHealth3 : 0x33AF18, 0x20, 0x0, 0x0, 0x4, 0x4, 0x54, 0x10C;
    string4 voiceId : 0x35B718;
    bool onFoot : 0x368D58;
}

/*
*   Voice line Ids are located in: Agent Hugo/Resources/Localiza/lang_(den|fin|nor|swe).txt files
*   If there are multiple lines in a row, it's best to use the last one as mashing can cause missed split.
*   voiceId address holds the id until next line is played.
*   Radio voice lines can be skipped completely, that could be true with cinema voice lines as well...
*   Finding pointers to mission states would be better solution than voice line ids.
*/

startup
{
    settings.Add("voiceId", true, "Voice line ID splits");
    settings.CurrentDefaultParent = "voiceId";

    // Tuple 1:(string) voice line id,   
    // 2:(string) name used in settings
    // 3:(bool) default state in settings
    vars.voiceIdSplits = new List<Tuple<string, string, bool>>
    {
        Tuple.Create("2204", "Sneak 1 end", true),
        Tuple.Create("2417", "Sneak 2 end", true),
        Tuple.Create("2488", "Sneak 3 end", true),
        Tuple.Create("3031", "Chase to Subway end", true),
        Tuple.Create("3050", "Entered Suspectra HQ", true),
        Tuple.Create("3071", "Sneak 4 start", false),
        Tuple.Create("3088", "Sneak 4 Dr Nogo Room", false)
        //Tuple.Create("3236", "Sneak 5 end", true)
    };

    // Voice lines can be repeated if mission is failed for example.
    // Some voice lines are played twice like Sneak 4 Dr Nogo Room for example.
    vars.playedVoiceIds = new HashSet<string>();

    foreach(var entry in vars.voiceIdSplits)
    {
        settings.Add(entry.Item1, entry.Item3, String.Format("{0} ({1})", entry.Item2, entry.Item1));
    }

    settings.CurrentDefaultParent = null;

    // Sneak 4 end doesn't have voice line at the end. Latest voice line id + onfoot going to 0 is used.
    settings.Add("sneak4End", true, "Sneak 4 end");
    vars.isSneak4Active = false;

    // Sneak 5 end uses radio split as the split, radio lines seem like they can be skipped over completely easier(?)
    settings.Add("sneak5End", true, "Sneak 5 end");
    vars.isSneak5Active = false;

    settings.Add("anyFinal", true, "Any% Final split");
    // Avoids incorrectly splitting on garbage.
    vars.finalBattleActive = false;
}

onStart
{
    // Resets states back to original
    vars.finalBattleActive = false;
    vars.isSneak4Active = false;
    vars.isSneak5Active = false;
    vars.playedVoiceIds.Clear();
}

update
{
    if (old.drNogoHealth3 != 5000 && current.drNogoHealth3 == 5000) vars.finalBattleActive = true;
    if (old.voiceId != "3088" && current.voiceId == "3088") vars.isSneak4Active = true;
    if (old.voiceId != "3218" && current.voiceId == "3218") vars.isSneak5Active = true;
}

split
{
    // Voice line splits
    foreach(var entry in vars.voiceIdSplits)
    {
        if(old.voiceId != entry.Item1 && current.voiceId == entry.Item1 && !vars.playedVoiceIds.Contains(entry.Item1))
        {
            vars.playedVoiceIds.Add(entry.Item1);
            if(settings[entry.Item1])
            {
                return true;
            }
        }
    }

    // Not the best solution but it works...
    // Sneak 4 doesn't have voice line at the end.
    if(old.onFoot && !current.onFoot)
    {
        if(vars.isSneak4Active && settings["sneak4End"])
        {
            vars.isSneak4Active = false;
            return true;
        }
        
        if(vars.isSneak5Active && settings["sneak5End"])
        {
            vars.isSneak5Active = false;
            return true;
        }
    }

    // Dr Nogo's 3rd boat destroyed, Any% final split
    if(current.drNogoHealth3 <= 0 && vars.finalBattleActive)
    {
        vars.finalBattleActive = false;
        if(settings["anyFinal"])
        {
            return true;
        }
    }
}

isLoading
{
    return !current.isNotLoading;
}