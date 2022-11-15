state("Freedom")
{
    float missionCompleted : 0x3890F0; // Naval/Rebel base not included
    int levelId : 0x388FF8; // Rebel bases have weird ids, works fine regardless
    bool runStart : 0x388508;
    bool isLoading : 0x3A258C;
}

startup
{
    settings.Add("Splits", true, "Mission splits");
    settings.CurrentDefaultParent = "Splits";

    // 1: level id, 2: Split name, 3: type(1=comp screen, 2=level change)
    vars.splits = new List<Tuple<int, string, int>>
    {
        Tuple.Create(292, "Tutorial (Level change)", 2),
        Tuple.Create(371, "Police Station", 1),
        Tuple.Create(374, "Post Office", 1),
        Tuple.Create(396, "Fire Station", 1),
        Tuple.Create(388, "Hotel", 1),
        Tuple.Create(375, "Harbor", 1),
        Tuple.Create(393, "Warehouse District", 1),
        Tuple.Create(369, "Movie Theatre", 1),
        Tuple.Create(372, "Power Plant", 1),
        Tuple.Create(351, "Naval Base (Level change)", 2),
        Tuple.Create(352, "Rebel Base (Level change)", 2),
        Tuple.Create(344, "TV Station", 1),
        Tuple.Create(366, "High School", 1),
        Tuple.Create(354, "Boat Landing (Level change)", 2),
        Tuple.Create(350, "Fort Jay", 1)
    };

    foreach(var entry in vars.splits)
    {
        settings.Add(entry.Item1.ToString(), true, entry.Item2);
    }
}

start
{
    return current.runStart && old.isLoading && !current.isLoading && current.levelId == 292;
}

split
{
    foreach(var entry in vars.splits)
    {
        if(!settings[entry.Item1.ToString()]) continue;

        // Mission complete screen
        if(entry.Item3 == 1)
        {
            if(old.missionCompleted == 0 && current.missionCompleted == 1 && current.levelId == entry.Item1)
            {
                return true;
            }
        }
        // Level change
        else if(entry.Item3 == 2)
        {
            if(old.levelId == entry.Item1 && current.levelId != entry.Item1)
            {
                return true;
            }
        }
    }
}

isLoading
{
    return current.isLoading;
}