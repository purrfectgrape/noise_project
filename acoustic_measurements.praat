# set form -----------------------------------------------------------------
form voice report
	optionmenu Pitch_analysis_mode: 3
		option ac method, costs = standard
		option ac method, costs = 0
		option cc method, costs = standard
		option cc method, costs = 0
		option Leave settings as they are
	optionmenu F0_range: 1
		option MDVP 70-625
		option MDVP 200-1000
		option User specified
	real left_User_specified_F0_range 60
	real right_User_specified_F0_range 625
	real Maximum_period_factor 2
	real Maximum_amplitude_factor 9
	word file f-1-q
	sentence Save_directory /Users/gianghale/Desktop/ProsodyPro/
	word User_specified_file_name f-1-q/channel1/acoustic_measurements_unique.csv
endform


# set pitch range -----------------------------------------------------------------
if f0_range = 1
	minimum_pitch = 70
	maximum_pitch = 625
elsif f0_range = 2
	minimum_pitch = 200
	maximum_pitch = 1000
elsif f0_range = 3
	minimum_pitch = left_User_specified_F0_range
	maximum_pitch = right_User_specified_F0_range
endif
#echo 'minimum_pitch' 'maximum_pitch'


# write to file -----------------------------------------------------------------
filedelete 'save_directory$''user_specified_file_name$'
header_row$ = "sound name" + tab$ + "total duration" + tab$ + "intensity" + tab$ + "spectraltilt" + tab$ + "median F0"  + tab$ + "mean F0" + tab$ + "sd F0" + tab$ + "min F0"  + tab$ + "max F0"
...+ tab$ + "number pulses" + tab$ +"number periods" + tab$ + "mean periods"  + tab$ +"sd period"  + tab$ + "fraction of locally unvoiced frames"  + tab$ + "fraction"  + tab$ + "number of voice breaks"
... + tab$ + "degree of voice breaks"  + tab$ + "degree"  + tab$ + "jitter local"  + tab$ + "jitter local abs"  + tab$ + "jitter rap"  + tab$ + "jitter ppq5"
... + tab$ + "shimmer local"  + tab$ + "shimmer local db"  + tab$ + "shimmer apq3"  + tab$ + "shimmer apq5"  + tab$ + "shimmer apq11"  + tab$ + "mean autocorr"  + tab$ + "mean NHR"  + tab$ + "mean HNR"
... + tab$ + "F1" + tab$ + "F2" + tab$ + "F3" + tab$ + "F4" + newline$
header_row$ > 'save_directory$''user_specified_file_name$'

# get information -----------------------------------------------------------------
selectObject: "Sound f-1-q_ch1", "TextGrid f-1-q_ch1_unique"
# Query the annotated vowels.
Extract non-empty intervals... 1 "yes"
sounds# = selected# ("Sound")
for i from 1 to size (sounds#)
	selectObject: sounds# [i]
	start = Get start time
	end = Get end time
	duration_total = end - start
	intensity = Get intensity (dB)
	name$ = selected$ ("Sound")
	To Pitch: 0.0, 70, 625
	plus Pitch 'name$'
	plus Sound 'name$'
	To PointProcess (cc)
	select PointProcess 'name$'_'name$'
	plus Sound 'name$'
	plus Pitch 'name$'
	#Voice report... 0.0 0.0 minimum_pitch maximum_pitch maximum_period_factor maximum_amplitude_factor 0.03 0.45

	report$ = Voice report... start end minimum_pitch maximum_pitch maximum_period_factor maximum_amplitude_factor 0.03 0.45

	medianPitch = extractNumber (report$, "Median pitch: ")
	meanPitch = extractNumber (report$, "Mean pitch: ")
	sdPitch =extractNumber (report$, "Standard deviation: ")
	minPitch = extractNumber (report$, "Minimum pitch: ")
	maxPitch = extractNumber (report$, "Maximum pitch: ")
	nPulses = extractNumber (report$, "Number of pulses: ")
	nPeriods = extractNumber (report$, "Number of periods: ")
	meanPeriod = extractNumber (report$, "Mean period: ") * 1000
	sdPeriod = extractNumber (report$, "Standard deviation of period: ") * 1000
	pctUnvoiced = extractNumber (report$, "Fraction of locally unvoiced frames: ")*100
	fracUnvoiced$ = extractLine$ (report$, "Fraction ")
	nVoicebreaks = extractNumber (report$, "Number of voice breaks: ")
	pctVoicebreaks = extractNumber (report$, "Degree of voice breaks: ") * 100
	degreeVoicebreaks$ = extractLine$ (report$, "Degree ")
	jitter_loc = extractNumber (report$, "Jitter (local): ") * 100
	jitter_loc_abs = extractNumber (report$, "Jitter (local, absolute): ") * 1000000
	jitter_rap = extractNumber (report$, "Jitter (rap): ") * 100
	jitter_ppq5 = extractNumber (report$, "Jitter (ppq5): ") *100
	shimmer_loc = extractNumber (report$, "Shimmer (local): ") *100
	shimmer_loc_dB = extractNumber (report$, "Shimmer (local, dB): ")
	shimmer_apq3 = extractNumber (report$, "Shimmer (apq3): ") * 100
	shimmer_apq5 = extractNumber (report$, "Shimmer (apq5): ") * 100
	shimmer_apq11 = extractNumber (report$, "Shimmer (apq11): ") * 100
	mean_autocor = extractNumber (report$, "Mean autocorrelation: ")
	mean_nhr = extractNumber (report$, "Mean noise-to-harmonics ratio: ")
	mean_hnr = extractNumber (report$, "Mean harmonics-to-noise ratio: ")

# This part measures formants
    select Sound 'name$'
    To Formant (burg)... 0.01 5 5000 0.025 50
    f1 =  Get mean... 1 0 0  Hertz
    f2 =  Get mean... 2 0 0 Hertz
    f3 = Get mean...  3 0 0 Hertz
    f4 = Get mean... 4 0 0 Hertz

# This part measures the spectral tilt
	select Sound 'name$'
	To Ltas... 100
	spectralTilt = Get slope... 0.0 1000.0 1000.0 4000.0 dB
	
date$ = date$()
echo                                VOICE REPORT          
printline -------------------------------------------------------------------------------------------------------------------------
printline Name of analysed sound: 'name$'        date: 'date$'
printline -------------------------------------------------------------------------------------------------------------------------
printline Analysis settings
if pitch_analysis_mode = 1 or pitch_analysis_mode = 3
	printline     Voice analysis (cc method) from 'minimum_pitch' to 'maximum_pitch' Hz
	method$ = "cc"
else
	printline     Intonation analysis (ac method) from 'minimum_pitch' to 'maximum_pitch' Hz
	method$ = "ac"
endif

printline     Oct cost = 'pitch_octave_cost:2', oct jmp cost = 'pitch_octave_jump_cost:2', voi/unvoi cost = 'pitch_voiced_unvoiced_cost:2'
printline     Max period factor = 'maximum_period_factor:2', max amp factor = 'maximum_amplitude_factor:2'
printline     Total duration: from 'start_of_signal:3' to 'end_of_signal:3' = 'duration_total:3' secs
printline     Duration analysed: from 'start:3' to 'end:3' = 'duration_analysed:3' secs

printline Fundamental frequency
printline     Median F0: 'medianPitch:3' Hz
printline     Mean F0: 'meanPitch:3' Hz
printline     St.dev. F0: 'sdPitch:3' Hz
printline     Minimum F0: 'minPitch:3' Hz
printline     Maximum F0: 'maxPitch:3' Hz
printline Pulses
printline     Number of pulses: 'nPulses'
printline     Number of periods: 'nPeriods'
printline     Mean period: 'meanPeriod:3' millisec.
printline     St.dev. period: 'sdPeriod:3' millisec.
printline Voicing
printline     Fraction 'fracUnvoiced$'
printline     Number of voice breaks: 'nVoicebreaks'
printline     Degree 'degreeVoicebreaks$'
printline Jitter
printline     Jitter (local): 'jitter_loc:3' %
printline     Jitter (local, abs): 'jitter_loc_abs:3' microseconds
printline     Jitter (rap): 'jitter_rap:3' %
printline     Jitter (ppq5): 'jitter_ppq5:3' %
printline Shimmer
printline     Shimmer (local): 'shimmer_loc:3' %
printline     Shimmer (local, dB): 'shimmer_loc_dB:3' dB
printline     Shimmer (apq3): 'shimmer_apq3:3' %
printline     Shimmer (apq5): 'shimmer_apq5:3' %
printline     Shimmer (apq11): 'shimmer_apq11:3' %
printline Harmonicity
printline     Mean autocorrelation: 'mean_autocor:4'
printline     Mean NHR: 'mean_nhr:4'
printline     Mean HNR: 'mean_hnr:3' dB
printline -------------------------------------------------------------------------------------------------------------------------


fileappend "'save_directory$''user_specified_file_name$'" 'name$' 'tab$' 'duration_total:3' 'tab$' 'intensity:3' 'tab$'  'spectralTilt:3' 'tab$' 
...'medianPitch:3' 'tab$' 'meanPitch:3' 'tab$' 'sdPitch:3' 'tab$' 'minPitch:3' 'tab$' 'maxPitch:3' 'tab$' 'nPulses:3' 'tab$' 'nPeriods:3' 'tab$' 'meanPeriod:3' 'tab$' 'sdPeriod:3' 'tab$' 'pctUnvoiced:3'
...'tab$' 'fracUnvoiced$:3' 'tab$' 'nVoicebreaks:3' 'tab$' 'pctVoicebreaks:3' 'tab$' 'degreeVoicebreaks$:3' 'tab$' 'jitter_loc:3' 'tab$' 'jitter_loc_abs:3' 'tab$' 'jitter_rap:3' 'tab$' 'jitter_ppq5:3' 'tab$' 'shimmer_loc:3'
...'tab$' 'shimmer_loc_dB:3' 'tab$' 'shimmer_apq3:3' 'tab$' 'shimmer_apq5:3' 'tab$' 'shimmer_apq11:3' 'tab$' 'mean_autocor:3' 'tab$' 'mean_nhr:3' 'tab$' 'mean_hnr:3' 'tab$' 'f1:3' 'tab$' 'f2:3' 'tab$' 'f3:3' 'tab$' 'f4:3'  'newline$'
printline Info appended as one line with header to 'save_directory$''user_specified_file_name$'

endfor
