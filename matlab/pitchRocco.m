function [f0,pol] = pitchRocco(s,fs,shift,fmin,fmax,threshold, win)
%GET_PITCH
%   [F0,POL] = pitchRocco(S,FS)
%   F0 countour extraction based on glottal inverse filtering and
%   autocorrelation method. Polarity detection based of negative and
%   positive energy distribution of glottal flow derivative.
%
% Input:
%   s       - Speech signal
%   fs      - Sampling frequency
%
% Optional parameters:
%   shift   - Window shift in milliseconds
%   fmin    - Minimum F0 in Hz
%   fmax    - Maximum F0 in Hz
%   win     - Windown length in milliseconds
%
% Output:
%   f0      - Estimated f0 contour (default at 5 ms intervals)
%   pol     - Polarity of speech signal
%
% This algorithm is a Matlab implementation of the algorith used in the
% following paper (with some modifications):
%
% T. Raitio, A. Suni, J. Yamagishi, H. Pulakka, J. Nurminen, M. Vainio,
% and P. Alku, "HMM-Based Speech Synthesis Utilizing Glottal Inverse
% Filtering", in IEEE Transactions on Audio, Speech, and Language
% Processing, vol. 19, no. 1, pp. 153-165, 2011.
%
% Tuomo Raitio
% 18.7.2012


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize

% Disp
% disp('Pitch tracking with glottal autocorrelation method...')

% Check input, set default parameters
if nargin < 7
    if nargin < 6
        threshold = 0.1;
        if nargin < 5
            fmax = 500;
            if nargin < 4
                fmin = 50;
                if nargin < 3
                    shift = 5;
                    if nargin < 2
                        disp('Error: Not enough input parameters.');
                        return;
                    end
                end
            end
        end
    end
    win = 2*1/fmin*1000;
end

% Set default parameters
voic_th = 0.05;
zcr_th = 140/win;
if fs >= 16000
    gi_th = 4;
else
    gi_th = 20;
end

% Check vector orientation
if size(s,2) > 1
    s = s';
end

% Glottal inverse filtering options
p_vt = round(fs/1000+4);    % LPC analysis order
p_gl = round(fs/2000);      % LPC analysis order for the glottal source

% High-pass filter options
Fstop = 40;                 % Stopband Frequency
Fpass = 70;                 % Passband Frequency
Nfir = round(300/16000*fs); % FIR numerator order

% Number of F0 tracks
nc = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing

% High-pass filter speech in order to remove possible low frequency
% fluctuations. Signal is shifted to compensate the long delay due to
% filtering
if mod(Nfir,2) == 1
    Nfir = Nfir + 1;
end
B = hpfilter_fir(Fstop,Fpass,fs,Nfir);
s = [s ; zeros(round(length(B)/2)-1,1)];
s = filter(B,1,s);
s = s(round(length(B)/2):end);

% Evaluate the number of samples for window and shift
N = round(win/1000*fs);
Nshift = round(shift/1000*fs);
nf0 = ceil(length(s)/Nshift)+1;

% Zero-padding for estimating the beginning and the end of the signal
s_orig = s;
ns = round(N/2);
ne = ceil(length(s)/Nshift)*Nshift-length(s) + ns;
s = [zeros(ns,1) ; s ; zeros(ne,1)];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get rough estimate of F0 range if fmin and fmax are not given
if nargin < 4
    
    %     disp('   Getting rough estimate of F0 range...')
    
    f0 = zeros(nf0,1);
    e = zeros(nf0,1);
    prob = zeros(nf0,1);
    zcr = zeros(nf0,1);
    gi = zeros(nf0,1);
    ind = 1;
    while (ind-1)*Nshift+N <= length(s)
        
        % Get frame, simple inverse filtering
        frame = s((ind-1)*Nshift+1:(ind-1)*Nshift+N);
        a = lpc(frame.*hanning(length(frame)),p_vt);
        dg = filter(a,1,frame);
        g = filter(1,[1 -0.99],dg);
        
        % F0 detection
        [f0(ind) prob(ind) e(ind) zcr(ind) gi(ind)] = f0det(frame,g,fs,fmin,fmax,voic_th,zcr_th,gi_th,1,1);
        
        % Increment index
        ind = ind + 1;
    end
    
    % Estimate rough F0
    f0vm_rough = median(f0(f0 > 0));
    
    % Remove voiced parts that have very low energy
    e_uv = e(f0 == 0);
    if length(e_uv) > 5
        me_uv = mean([median(e_uv) mean(e_uv)]);
        f0(e < me_uv) = 0;
    end
    
    % Remove voiced parts that have very high ZCR
    zcr_uv = zcr(f0 == 0);
    if length(zcr_uv) > 5
        zcr_uv = mean([median(zcr_uv) mean(zcr_uv)]);
        f0(zcr > zcr_uv) = 0;
    end
    
    % Median filtering
    f0 = medfilt1(f0,3);
    
    % Redefine F0 limits
    f0vm = median(f0(f0 > 0));
    if isnan(f0vm) && ~isnan(f0vm_rough)
        f0vm = f0vm_rough;
    end
    if ~isnan(f0vm)
        if nargin < 4
            fmin = f0vm.^1.2/5;
        end
        if nargin < 5
            fmax = 2.2*f0vm;
        end
    end
    
    % Redefine the number of samples for window
    win = 2/fmin*1000;
    N = round(win/1000*fs);
    
    % Redefine s
    ns = round(N/2);
    ne = ceil(length(s_orig)/Nshift)*Nshift-length(s_orig) + ns;
    s = [zeros(ns,1) ; s_orig ; zeros(ne,1)];
    
    % Display estimation results
    %     if isnan(f0vm)
    %         disp('     Median F0: Undefined - using defaults:')
    %     else
    %         disp(['     Median F0: ' num2str(f0vm)])
    %     end
    %     disp(['     Min F0: ' num2str(fmin)])
    %     disp(['     Max F0: ' num2str(fmax)])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actual pitch estimation based of glottal inverse filterign and
% autocorrelation method.

% Start analysis frame by frame
% disp('   Estimating F0...')
f0 = zeros(nf0,nc);
prob = zeros(nf0,nc);
e = zeros(nf0,1);
zcr = zeros(nf0,1);
gi = zeros(nf0,1);
exc = zeros(size(s));
ind = 1;
while (ind-1)*Nshift+N <= length(s)
    
    % Get frame, glottal inverse filtering using IAIF
    frame = s((ind-1)*Nshift+1:(ind-1)*Nshift+N);
    
    % Add noise to prevent problems with all-zero frames
    if sum(abs(frame)) == 0
        frame = 0.00001*(rand(size(frame))-0.5);
    end
    
    % Glottal inverse filtering
    g = iaif(frame,p_vt,p_gl,0.99,0);
    
    % Ovelap-add glottal source
    dg = filter([1 -0.99],1,g);
    exc((ind-1)*Nshift+1:(ind-1)*Nshift+N) = ...
        exc((ind-1)*Nshift+1:(ind-1)*Nshift+N) + dg.*hanning(N);
    
    % F0 detection
    [f0(ind,:) prob(ind,:) e(ind) zcr(ind) gi(ind)] = f0det(frame,g,fs,fmin,fmax,voic_th,zcr_th,gi_th,nc,0);
    
    % Increment index
    ind = ind + 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Post-processing

% Form continuous pitch contour from two F0 tracks
n = 10;
lim1 = 0.2;
f0_new = f0;
for i = 1:size(f0,1)
    if f0(i,1) == 0 && f0(i,2) > 0
        mv = f0(max(i-n,1):min(i+n,size(f0,1)));
        m = median(mv(mv > 0));
        if abs(f0(i,2)-m)/m < lim1
            f0_new(i,1) = f0(i,2);
        end
    end
end
f0 = f0_new;
lim2 = 0.5;
for i = 1:size(f0,1)
    if f0(i,1) > 0 && f0(i,2) > 0
        mv = f0(max(i-n,1):min(i+n,size(f0,1)));
        m = median(mv(mv > 0));
        if abs(f0(i,1)-m)/m > lim2
            f0_new(i,1) = f0(i,2);
        end
    end
end
f0 = f0_new;

% 5-point median filtering
for i = 1:nc
    f0(:,i) = medfilt1(f0(:,i),5);
end

% Remove voiced parts that have very low energy
e_uv = e(f0(:,1) == 0);
if length(e_uv) > 5
    me_uv = mean([median(e_uv) mean(e_uv)]);
    f0(e < me_uv,:) = 0;
end

% Remove voiced parts that have high ZCR, don't apply to high energy parts
if sum(f0(:,1) == 0) > 5
    e_v = e(f0(:,1) > 0);
    me_v = median(e_v);
    zcr_uv = zcr(f0(:,1) == 0);
    mzcr_uv = median(zcr_uv);
    f0(zcr > mzcr_uv & e < me_v,:) = 0;
end

% Remove voiced parts whose voicing probability is low
e_v = e(f0(:,1) > 0);
me_v = median(e_v);
f0((prob(:,1) < threshold) & (e < me_v),:) = 0;

% Remove voiced parts that have high gradient index
f0(gi > gi_th,:) = 0;

% 3-point medial filtering
for i = 1:nc
    f0(:,i) = medfilt1(f0(:,i),3);
end

% Return main contour
f0 = f0(:,1)';

% Polarity detection
f0i = interp1(1:length(f0),f0,linspace(1,length(f0),length(s)),'nearest');
exc = exc(f0i > 0);
exc_p = exc(exc>0);
exc_n = exc(exc<0);
ep = sum(exc_p.^2);
en = sum(exc_n.^2);
negpol = ep/(ep+en);
pospol = en/(ep+en);
if ~isnan(pospol)
    if negpol > pospol
        %         disp(['   Negative polarity with ' num2str(negpol) ' probability']);
        pol = -1;
    else
        %         disp(['   Positive polarity with ' num2str(pospol) ' probability']);
        pol = 1;
    end
else
    %     disp('Could not detect polarity (default is positive polarity)');
    pol = 1;
end







