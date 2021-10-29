function [f0,prob,e,zcr,gi] = f0det(frame,g,fs,fmin,fmax,voic_th,zcr_th,gi_th,nc,make_vu)
% F0 detection based on glottal inverse filtering and autocorrelation
% method.
%
%   frame   - Speech frame
%   g       - Glottal flow estimate of the frame
%   fs      - Sampling frequency
%   fmin    - Minimum F0 in Hz
%   fmax    - Maximum F0 in Hz
%   voic_th - Voicing threshold
%   zcr_th  - Zero-crossing rate (ZCR) threshold
%   gi_th   - Gradient index threshold
%   nc      - Number of possible F0 contours
%   make_vu - Make rough voiced/unvoiced decision
%
%   f0      - Estimated fundamental frequency
%   prob    - Probability of correct estimate relative to each other
%   e       - Energy of the speech frame
%   zcr     - ZCR (per millisecond)'
%   gi      - Gradient index
%
% This algorithm is a Matlab implementation of the algorith used in the
% following paper (with some minor modifications):
%
% T. Raitio, A. Suni, J. Yamagishi, H. Pulakka, J. Nurminen, M. Vainio,
% and P. Alku, "HMM-Based Speech Synthesis Utilizing Glottal Inverse
% Filtering", in IEEE Transactions on Audio, Speech, and Language
% Processing, vol. 19, no. 1, pp. 153-165, 2011.
%
% Tuomo Raitio
% 18.7.2012

% Internal parameters
ips = 10;
negnum = -0.5;
warning('off','all');

% Evaluate the energy of the frame
e = sqrt(sum(frame.^2));

% Count the number of zero-crossings
zcr = 0;
for i = 1:length(frame)-1
    if (frame(i) > 0 && frame(i+1) < 0) || (frame(i) < 0 && frame(i+1) > 0)
        zcr = zcr + 1;
    end
end
zcr = zcr/(length(g)/fs*1000);

% Evaluate gradient index
a = lpc(frame.*hanning(length(frame)),1);
f = filter(a,1,frame);
ksi = f(2:end)-f(1:end-1);
gi = 0.5*(abs(ksi(2:end)./abs(ksi(2:end))-ksi(1:end-1)./abs(ksi(1:end-1))).*abs(ksi(2:end)));
gi = sum(gi)/e;
if isnan(gi)
    gi = 0;
end

% Autocorrelation
c = xcorr(g);
c = c(round(length(c)/2):end);
cmax = max(c);
cmax = cmax(1);

% Remove samples according to fmin and fmax
c(1:round(fs/fmax)-1) = negnum;
c(round(fs/fmin)+1:end) = negnum;

% Find multiple F0 contours (defined by nc)
t0 = zeros(nc,1);
f0 = zeros(nc,1);
prob = zeros(nc,1);
for i = 1:nc

    % Find max peak, prevent fake peaks around fmin and fmax
    t0tmp = find(c == max(c));
    if length(t0tmp) > 1
        t0tmp = 0;
        t0(i) = 0;
    else
        t0(i) = t0tmp;
    end
    if t0(i) == round(fs/fmax)
        t0(i) = 0;
    end
    if t0(i) == round(fs/fmin)
        t0(i) = 0;
    end

    % Quadratic fitting of the parabola
    if t0(i) == 0
        f0(i) = 0;
        prob(i) = 0;
    else
        t0tmp = t0(i);
        ips_new = ips;
        while t0(i)-ips_new < 1 || t0(i)+ips_new > length(c) || c(t0(i)-ips_new) == negnum || c(t0(i)+ips_new) == negnum
            ips_new = ips_new - 1;
        end
        if ips_new > 0
            p = polyfit(t0(i)-ips_new:t0(i)+ips_new,c(t0(i)-ips_new:t0(i)+ips_new)',2);
            t0(i) = -p(2)/(2*p(1));
            f0(i) = fs/(t0(i)-1);
            prob(i) = c(t0tmp)/cmax;
        else
            f0(i) = fs/(t0(i)-1);
            prob(i) = c(t0(i))/cmax;
        end
    end

    % Remove samples down from the peaks, forward and backward
    c_rem = c;
    if t0tmp > 0
        ind = t0tmp;
        while ind+1 <= length(c) && c(ind) - c(ind+1) >= 0
            c_rem(ind) = negnum;
            ind = ind + 1;
        end
        ind = t0tmp;
        while ind-1 >= 1 && c(ind) - c(ind-1) >= 0
            c_rem(ind) = negnum;
            ind = ind - 1;
        end
    end
    c = c_rem;
end

% Rough voiced/unvoiced decision
if make_vu == 1
    for i = 1:nc
        if e < voic_th
            f0(i) = 0;
            prob(i) = 0;
        end
        if zcr > zcr_th
            f0(i) = 0;
            prob(i) = 0;
        end
        if gi > gi_th
            f0(i) = 0;
            prob(i) = 0;
        end
    end
end


