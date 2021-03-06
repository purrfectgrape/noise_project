myFolder = '\\client\h$\Desktop\prelim-data-analysis\f-2-90\channel1';
myFiles = dir(fullfile(myFolder,'*.wav')); %gets all wav files

for k = 1:length(myFiles)
  baseFileName = myFiles(k).name;
  fullFileName = fullfile(myFolder, baseFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
  [y, Fs] = audioread(fullFileName);
  [f0, ~] = pitchRocco(y, Fs);
  i = 1:length(f0);
  i_new =  linspace(min(i), max(i), 22);
  f0_downsampled = interp1(i, f0, i_new, 'linear');  
  fid= fopen(fullfile(myFolder, 'F0.mat'),'a');
  fprintf(fid, '%s ', baseFileName);
  fprintf(fid, '%f ', f0_downsampled);
  fprintf(fid,'\n');
  fclose(fid);
end