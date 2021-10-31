myFolder = '/Users/gianghale/Desktop/ProsodyPro/m-3-q/channel1';
myFiles = dir(fullfile(myFolder,'*.wav')); %gets all wav files

for k = 1:length(myFiles)
  baseFileName = myFiles(k).name;
  fullFileName = fullfile(myFolder, baseFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
  [y, Fs] = audioread(fullFileName);
  [f0, ~] = pitchRocco(y, Fs);
  fid= fopen(fullfile(myFolder, 'F0.mat'),'a');
  fprintf(fid, '%s ', baseFileName);
  fprintf(fid, '%f ', f0);
  fprintf(fid,'\n');
  fclose(fid);
end