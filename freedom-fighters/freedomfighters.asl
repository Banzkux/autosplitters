state("Freedom")
{
    float missionCompleted : 0x3890F0; // Naval/Rebel base not included
    int levelId : 0x388FF8; // Rebel bases have weird ids, works fine regardless
    bool runStart : 0x388508;
    bool isLoading : 0x3A258C;
    bool nonFlagMissionCompleted : 0x38D0B0, 0x4, 0x214, 0x2C, 0x94, 0xFC, 0x12C; // Naval/Rebel base
    float playerX : 0xC0E50, 0x1E8;
    float playerY : 0xC0E50, 0x1EC;
    float playerZ : 0xC0E50, 0x1F0;
    bool tatarin : 0x38D0C8, 0xC70, 0xA3C;
}

startup
{
    settings.Add("Splits", true, "Mission splits");
    settings.CurrentDefaultParent = "Splits";

    // 1: level id, 2: Split name, 3: type(1=comp screen, 2=level change, 3=non flag comp screen)
    vars.splits = new List<Tuple<int, string, int>>
    {
        Tuple.Create(292, "Invasion (Level change)", 2),
        Tuple.Create(371, "Police Station", 1),
        Tuple.Create(374, "Post Office", 1),
        Tuple.Create(396, "Fire Station", 1),
        Tuple.Create(388, "Hotel", 1),
        Tuple.Create(375, "Harbor", 1),
        Tuple.Create(393, "Warehouse District", 1),
        Tuple.Create(369, "Movie Theatre", 1),
        Tuple.Create(372, "Power Plant", 1),
        Tuple.Create(351, "Naval Base", 3),
        Tuple.Create(352, "Rebel Base", 3),
        Tuple.Create(344, "TV Station", 1),
        Tuple.Create(366, "High School", 1),
        Tuple.Create(354, "Boat Landing (Level change)", 2),
        Tuple.Create(350, "Fort Jay", 1)
    };

    foreach(var entry in vars.splits)
    {
        settings.Add(entry.Item1.ToString(), true, entry.Item2);
    }

    settings.CurrentDefaultParent = null;

    settings.Add("Extra", false, "Extra");
    settings.CurrentDefaultParent = "Extra";

    settings.Add("tatarin", false, "Naval Base - Eliminated Tatarin");

    settings.Add("PosSplits", false, "Position based splits");
    // 1 int: level id, 2 string: split name, 3 tuple: pos1, 4 tuple: pos2
    vars.posSplits = new List<Tuple<int, string, Tuple<int, int, int>, Tuple<int, int, int>>>
    {
        Tuple.Create(292, "Invasion - Heal wounded fighter", Tuple.Create(200, 0, 8323), Tuple.Create(-245, 500, 8323)),
        Tuple.Create(371, "Police Station - Past snipers", Tuple.Create(3452, 0, 732), Tuple.Create(1015, 500, 1974)),
        Tuple.Create(374, "Post Office - Out of Isabella speech building", Tuple.Create(-7900, 0, 1719), Tuple.Create(-8100, 500, 1719)),
        Tuple.Create(396, "Fire Station - Past the bridge", Tuple.Create(3425, 0, -1800), Tuple.Create(3425, 500, 500)),
        Tuple.Create(388, "Hotel - Hotel street corner", Tuple.Create(3750, 0, 2231), Tuple.Create(5834, 500, 4159)),
        Tuple.Create(375, "Harbor - Made inside warehouse", Tuple.Create(-9700, 0, -4969), Tuple.Create(-10000, 500, -4969)),
        Tuple.Create(393, "Warehouse District - Bridge fall off area", Tuple.Create(-1985, 0, 5877), Tuple.Create(1605, 1700, 2326)),
        Tuple.Create(369, "Movie Theatre - Made inside movie theatre", Tuple.Create(7250, 150, -4247), Tuple.Create(7550, 650, -4247)),
        Tuple.Create(372, "Power Plant - Made the barbed wire skip", Tuple.Create(2035, 500, 6595), Tuple.Create(2035, 1000, 8729)),
        Tuple.Create(352, "Rebel Base - Made it to the cave", Tuple.Create(-10700, -500, 16905), Tuple.Create(-10200, -1000, 16905)),
        Tuple.Create(344, "TV Station - Stair skips done", Tuple.Create(4117, 1800, -2600), Tuple.Create(4117, 2500, -1900)),
        Tuple.Create(366, "High School - School back enterance", Tuple.Create(5600, 0, -5056), Tuple.Create(5850, 500, -5056)),
        Tuple.Create(354, "Boat Landing - Got up the pipes", Tuple.Create(449, 100, -8), Tuple.Create(-459, 500, -8)),
        Tuple.Create(350, "Fort Jay - 1st skip", Tuple.Create(5641, 650, -18205), Tuple.Create(4958, 1200, -18191)),
        Tuple.Create(350, "Fort Jay - 2nd skip", Tuple.Create(-3905, 1800, -17345), Tuple.Create(-3905, 2350, -17937))
    };
    settings.CurrentDefaultParent = "PosSplits";

    foreach(var entry in vars.posSplits)
    {
        settings.Add("pos" + entry.Item2, false, entry.Item2);
    }

    // Line Segment Intersection
    vars.intersect = (Func<float, float, float, float, float, float, float, float, bool>)((Ax, Ay, Bx, By, Cx, Cy, Dx, Dy) => 
    {
        float dx0 = Bx - Ax;
        float dx1 = Dx - Cx;
        float dy0 = By - Ay;
        float dy1 = Dy - Cy;
        float p0 = dy1 * (Dx - Ax) - dx1 * (Dy - Ay);
        float p1 = dy1 * (Dx - Bx) - dx1 * (Dy - By);
        float p2 = dy0 * (Bx - Cx) - dx0 * (By - Cy);
        float p3 = dy0 * (Bx - Dx) - dx0 * (By - Dy);
        return (p0 * p1 <= 0) && (p2 * p3 <= 0);
    });

    vars.distance = (Func<float, float, float, float, float, float, float>)((Ax, Ay, Az, Bx, By, Bz) => 
    {
        float deltaX = Bx - Ax;
        float deltaY = By - Ay;
        float deltaZ = Bz - Az;
        return (float) Math.Sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
    });

    vars.splittedPosSplits = new HashSet<string>();
}

onStart
{
    vars.splittedPosSplits.Clear();
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
        else if(entry.Item3 == 3)
        {
            if(!old.nonFlagMissionCompleted && current.nonFlagMissionCompleted && current.levelId == entry.Item1)
            {
                return true;
            }
        }
    }

    // Extras
    // Position based splits
    float distance = vars.distance(old.playerX, old.playerY, old.playerZ, current.playerX, current.playerY, current.playerZ);
    foreach(var entry in vars.posSplits)
    {
        // Player 'travels' massive distance when level loads in, ignore them just in case
        if(current.isLoading || distance > 80f) break;

        if(current.levelId != entry.Item1 || !settings["pos"+entry.Item2] || vars.splittedPosSplits.Contains(entry.Item2)) continue;

        if(vars.intersect(old.playerX, old.playerZ, current.playerX, current.playerZ, entry.Item3.Item1, entry.Item3.Item3, entry.Item4.Item1, entry.Item4.Item3))
        {
            int lowerY = 0;
            int higherY = 0;
            if(entry.Item3.Item2 > entry.Item4.Item2)
            {
                lowerY = entry.Item4.Item2;
                higherY = entry.Item3.Item2;
            }
            else
            {
                lowerY = entry.Item3.Item2;
                higherY = entry.Item4.Item2;
            }

            if(current.playerY > lowerY && current.playerY < higherY)
            {
                vars.splittedPosSplits.Add(entry.Item2);
                return true;
            }
        }
    }

    // Tatarin
    if(current.levelId == 351 && !current.isLoading && !old.tatarin && current.tatarin && settings["tatarin"])
    {
        return true;
    }
}

isLoading
{
    return current.isLoading;
}