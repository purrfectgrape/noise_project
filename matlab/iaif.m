function [g,a,ag] = iaif(x,p_vt,p_gl,d,hpfilt)
%IAIF Glottal Inverse Filtering
%   [G,A,AG] = IAIF(X,P_VT,P_GL,D,HPFILT) estimates the glottal volume
%   velocity waveform from a speech signal using Iterative Adaptive Inverse
%   Filtering (IAIF).
%
%   x      - Speech signal
%   p_vt   - Order of the LPC analysis for vocal tract
%   p_gl   - Order of the LPC analysis for glottal source
%   d      - Leaky integration ceofficient (e.g. 0.99)
%   hpfilt - High-pass filter flag (0: do not apply, 1...N: apply N times)
%
%   g      - Glottal volume velocity waveform
%   a      - LPC coefficients of vocal tract
%   ag     - LPC coefficients of source spectrum
%
% Reference:
%
% P. Alku, "Glottal wave analysis with pitch synchronous iterative adaptive
% inverse filtering", Speech Commun., vol. 11, no. 2-3, pp. 109–118, 1992.
%
% Tuomo Raitio, 20.9.2011
% Revised 20.6.2012


% Set default order of the LPC analysis to 20 for vocal tract
if nargin < 2
    disp('LPC order for vocal tract set to 20.');
    p_vt = 20;
end

% Set default order of the LPC analysis to 20 for glottal source
if nargin < 3
    disp('LPC order for glottal source set to 8.');
    p_gl = 8;
end

% Set default leaky integration ceofficient
if nargin < 4
    disp('Leaky integration ceofficient set to 0.99.');
    d = 0.99;
end

% Set default hpfilt to 1 (filter only once)
if nargin < 5
    disp('Apply high-pass filtering once.');
    hpfilt = 1;
end

% High-pass filter (Linear-phase FIR, Fc = 77 Hz, Fs = 16 kHz)
% Filter N times
if hpfilt > 0
    load 'hp.txt'
    for i = 1:hpfilt
        x = filter(hp,1,x);
    end
end

% Estimate the combined effect of the glottal flow and the lip radiation
% (Hg1) and cancel it out through inverse filtering.
Hg1 = lpc(x.*hanning(length(x)),1);
y = filter(Hg1,1,x);

% Estimate the effect of the vocal tract (Hvt1) and cancel it out through
% inverse filtering. The effect of the lip radiation is canceled through
% intergration. Signal g1 is the first estimate of the glottal flow.
Hvt1 = lpc(y.*hanning(length(x)),p_vt);
g1 = filter(Hvt1,1,x);
g1 = filter(1,[1 -d],g1);

% Re-estimate the effect of the glottal flow (Hg2). Cancel the contribution
% of the glottis and the lip radiation through inverse filtering and
% integration, respectively.
Hg2 = lpc(g1.*hanning(length(x)),p_gl);
y = filter(Hg2,1,x);
y = filter(1,[1 -d],y);

% Estimate the model for the vocal tract (Hvt2) and cancel it out through
% inverse filtering. The final estimate of the glottal flow is obtained
% through canceling the effect of the lip radiation.
Hvt2 = lpc(y.*hanning(length(x)),p_vt);
g = filter(Hvt2,1,x);
g = filter(1,[1 -d],g);

% Set vocal tract model to a and glottal source spectral model to ag
a = Hvt2;
ag = Hg2;

