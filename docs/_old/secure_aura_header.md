# Auras

## SecureAuraHeader

> contributed by Nevin Flanagan

| Attribute                 | Value                     | Description                                                                                                                                                               |
|:--------------------------|:--------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| filter                    | [STRING]                  | a pipe-separated list of aura filter options ("RAID" will be ignored)                                                                                                     |
| separateOwn               | [NUMBER]                  | indicate whether buffs you cast yourself should be separated before (1) or after (-1) others. If 0 or nil, no separation is done.                                         |
| sortMethod                | ["INDEX", "NAME", "TIME"] | defines how the group is sorted (Default: "INDEX")                                                                                                                        |
| sortDirection             | ["+", "-"]                | defines the sort order (Default: "+")                                                                                                                                     |
| groupBy                   | [nil, auraFilter]         | if present, a series of comma-separated filters, appended to the base filter to separate auras into groups within a single stream                                         |
| includeWeapons            | [nil, NUMBER]             | The aura sub-stream before which to include temporary weapon enchants. If nil or 0, they are ignored.                                                                     |
| consolidateTo             | [nil, NUMBER]             | The aura sub-stream before which to place a proxy for the consolidated header. If nil or 0, consolidation is ignored.                                                     |
| consolidateDuration       | [nil, NUMBER]             | the minimum total duration an aura should have to be considered for consolidation (Default: 30)                                                                           |
| consolidateThreshold      | [nil, NUMBER]             | buffs with less remaining duration than this many seconds should not be consolidated (Default: 10)                                                                        |
| consolidateFraction       | [nil, NUMBER]             | The fraction of remaining duration a buff should still have to be eligible for consolidation (Default: .10)                                                               |
| template                  | [STRING]                  | the XML template to use for the unit buttons. If the created widgets should be something other than Buttons, append the Widget name after a comma.                        |
| weaponTemplate            | [STRING]                  | the XML template to use for temporary enchant buttons. Can be nil if you preset the tempEnchant1 and tempEnchant2 attributes, or if you don't include temporary enchants. |
| consolidateProxy          | [STRING|Frame]            | Either the button which represents consolidated buffs, or the name of the template used to construct one.                                                                 |
| consolidateHeader         | [STRING|Frame]            | Either the aura header which contains consolidated buffs, or the name of the template used to construct one.                                                              |
| point                     | [STRING]                  | a valid XML anchoring point (Default: "TOPRIGHT")                                                                                                                         |
| minWidth                  | [nil, NUMBER]             | the minimum width of the container frame                                                                                                                                  |
| minHeight                 | [nil, NUMBER]             | the minimum height of the container frame                                                                                                                                 |
| xOffset                   | [NUMBER]                  | the x-Offset to use when anchoring the unit buttons. This should typically be set to at least the width of your buff template.                                            |
| yOffset                   | [NUMBER]                  | the y-Offset to use when anchoring the unit buttons. This should typically be set to at least the height of your buff template.                                           |
| wrapAfter                 | [NUMBER]                  | begin a new row or column after this many auras. If 0 or nil, never wrap or limit the first row                                                                           |
| wrapXOffset               | [NUMBER]                  | the x-offset from one row or column to the next                                                                                                                           |
| wrapYOffset               | [NUMBER]                  | the y-offset from one row or column to the next                                                                                                                           |
| maxWraps                  | [NUMBER]                  | limit the number of rows or columns. If 0 or nil, the number of rows or columns will not be limited.                                                                      |
