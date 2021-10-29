function B = hpfilter_fir(Fstop,Fpass,fs,N)
% FIR least-squares Highpass filter design using the FIRLS function
%
% Tuomo Raitio
% 10.7.2012

% Calculate the coefficients using the FIRLS function.
b  = firls(N, [0 Fstop Fpass fs/2]/(fs/2), [0 0 1 1], [1 1]);
Hd = dfilt.dffir(b);

% Save to B
B = Hd.Numerator;