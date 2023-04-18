# nanos-vprofiler


### Just start it as a normal package
* It will start monitoring after loading
* Works Serverside and Clientside
* All times displayed are in seconds
* Call times are not 100% precise, they are more precise serverside.
* Precision can be altered (a little bit) if a function is called inside another because the vprofiler hook will be called and time will be added to the parent function call
* Do not use debug.sethook

### Commands
* vp_showdata_imworst <number> - Show VProfiler current worst functions by impact (cumulated call times)
* vp_showdata_avworst <number> - Show VProfiler current worst functions by average time
* vp_showdata_coworst <number> - Show VProfiler current worst functions by count
* vp_showdata_maxworst <number> - Show VProfiler current worst functions by max time
* vp_showdata_minworst <number> - Show VProfiler current worst functions by min time