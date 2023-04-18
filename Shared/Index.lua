

local Profiling_tbl = {
    In_Calls = {},

    Profiling_Data = {},
}


local cur_logged_exectime = math.huge


local function VProfiler_split_str(str,sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local function VProfiler_GetTime()
    if Server then
        return os.clock()
    else
        return Client.GetTime()/1000
    end
end

debug.sethook(function(call_type)
    local info = debug.getinfo(2)

    local curtime = VProfiler_GetTime()

    if info then
        if info.what == "Lua" then
            if info.source then
                if not string.find(info.source, "INTERNAL") then
                    local split_source = VProfiler_split_str(info.source, "/")

                    if (split_source[1] ~= Package.GetName() and info.source ~= "Lua Default Library") then
                        --print(call_type, NanosTable.Dump(info))
                        if call_type ~= "return" then
                            if not Profiling_tbl.In_Calls[info.func] then
                                Profiling_tbl.In_Calls[info.func] = {
                                    nb = 0,
                                    tbl = {},
                                }
                            end
                            Profiling_tbl.In_Calls[info.func].nb = Profiling_tbl.In_Calls[info.func].nb + 1
                            Profiling_tbl.In_Calls[info.func].tbl[Profiling_tbl.In_Calls[info.func].nb] = VProfiler_GetTime()
                        else
                            if Profiling_tbl.In_Calls[info.func] then
                                local start_time = Profiling_tbl.In_Calls[info.func].tbl[Profiling_tbl.In_Calls[info.func].nb]
                                Profiling_tbl.In_Calls[info.func].tbl[Profiling_tbl.In_Calls[info.func].nb] = nil
                                Profiling_tbl.In_Calls[info.func].nb = Profiling_tbl.In_Calls[info.func].nb - 1
                                if Profiling_tbl.In_Calls[info.func].nb <= 0 then
                                    Profiling_tbl.In_Calls[info.func] = nil
                                end
                                local diff = curtime - start_time
                                --print(diff)
                                if not Profiling_tbl.Profiling_Data[info.func] then
                                    Profiling_tbl.Profiling_Data[info.func] = {
                                        count = 0,
                                        min = math.huge,
                                        max = -1,
                                        average = 0,
                                        impact = 0,
                                        source = info.source,
                                        linedefined = info.linedefined,
                                        lastlinedefined = info.lastlinedefined,
                                        name = info.name,
                                    }
                                end
                                Profiling_tbl.Profiling_Data[info.func].count = Profiling_tbl.Profiling_Data[info.func].count + 1
                                local count = Profiling_tbl.Profiling_Data[info.func].count
                                if Profiling_tbl.Profiling_Data[info.func].max < diff then
                                    Profiling_tbl.Profiling_Data[info.func].max = diff
                                end
                                if Profiling_tbl.Profiling_Data[info.func].min > diff then
                                    Profiling_tbl.Profiling_Data[info.func].min = diff
                                end
                                -- (av * (count - 1) + diff) / count = (av*count - av + diff) / count = av + (-av + diff)/count
                                Profiling_tbl.Profiling_Data[info.func].average = Profiling_tbl.Profiling_Data[info.func].average + (-Profiling_tbl.Profiling_Data[info.func].average + diff) / count
                                Profiling_tbl.Profiling_Data[info.func].impact = Profiling_tbl.Profiling_Data[info.func].impact + diff

                                if diff > cur_logged_exectime then
                                    print("ExecTime Log ", diff, NanosTable.Dump(info))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end, "cr")


local function _VProfiler_ShowData_SortByKey(key, text)
    if (text and text ~= "" and type(tonumber(text)) == "number" and tonumber(text) % 1 == 0) then
        local max_nb = tonumber(text)
        local data_displayed = {}
        local data_count = 0
        for k, v in pairs(Profiling_tbl.Profiling_Data) do
            local inserted = false
            for i, v2 in ipairs(data_displayed) do
                if v2[key] < v[key] then
                    if data_count < max_nb then
                        table.insert(data_displayed, i, v)
                        data_count = data_count + 1
                    else
                        data_displayed[i] = v
                    end
                    inserted = true
                    break
                end
            end
            if (not inserted and data_count < max_nb) then
                table.insert(data_displayed, v)
                data_count = data_count + 1
            end
        end

        print(NanosTable.Dump(data_displayed))
    else
        error("Wrong arguments")
    end
end


Console.RegisterCommand("vp_showdata_imworst", function(text)
    _VProfiler_ShowData_SortByKey("impact", text)
end, "Show VProfiler current worst functions by impact (cumulated call times)", {"number"})

Console.RegisterCommand("vp_showdata_avworst", function(text)
    _VProfiler_ShowData_SortByKey("average", text)
end, "Show VProfiler current worst functions by average time", {"number"})

Console.RegisterCommand("vp_showdata_coworst", function(text)
    _VProfiler_ShowData_SortByKey("count", text)
end, "Show VProfiler current worst functions by count", {"number"})

Console.RegisterCommand("vp_showdata_maxworst", function(text)
    _VProfiler_ShowData_SortByKey("max", text)
end, "Show VProfiler current worst functions by max time", {"number"})

Console.RegisterCommand("vp_showdata_minworst", function(text)
    _VProfiler_ShowData_SortByKey("min", text)
end, "Show VProfiler current worst functions by min time", {"number"})


Console.RegisterCommand("vp_logwhen_exectime", function(exectime)
    if (exectime and type(tonumber(exectime)) == "number") then
        cur_logged_exectime = tonumber(exectime)
    else
        error("Wrong arguments")
    end
end, "Log function call when its exectime exceeds the given time", {"time_s"})