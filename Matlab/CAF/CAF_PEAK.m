function [TDOA, FDOA, MaxAmb, Amb] = ...
    CAF_peak(S1, S2, Tau_Lo, Tau_Hi, Freq_Lo, Freq_Hi, fs);
    % *********************************************************************
    % CAF_peak(S1, S2, Tau_Lo, Tau_Hi, Freq_Lo, Freq_Hi) takes as input:
    % two signals (S1, S2) that are row or column vectors; a range of
    % time delays (in samples) to search (Tau_Lo, Tau_Hi must be
    % integers between -N & +N); a range of digital frequencies (in
    % fractions of sampling frequency) to search (Freq_Lo, Freq_Hi must
    % be between -1/2 and 1/2, or -(N/2)/N and (N/2)/N, where N is the
    % length of the longer of the two signal vectors); and the sampling
    % frequency, fs.
    %
    %
    % The function computes the Cross Ambiguity Function of the two
    % signals. Four plots are produced which represent four different
    % views of the Cross Ambiguity Function magnitude versus the input
    % Tau and Frequency Offset ranges.
    %
    %
    % The function returns the scalars TDOA, FDOA, and MaxAmb, where
    % TDOA & FDOA are the values of Time Delay and Frequency Offset
    % that cause the Cross Ambiguity Function to peak at a magnitude
    % of MaxAmb. Amb is the matrix of values representing the CAF
    % surface.
    % Written by: LCDR Joe J. Johnson, USN
    % Last modified: 26 August 2001
    % *********************************************************************
    % Ensures that the user enters all SIX required arguments.

    if (nargin < 6)
        error...
        ('6 arguments required: S1, S2, Tau_Lo, Tau_Hi, Freq_Lo, Freq_Hi');
    end 

    % Ensures that both S1 & S2 are row- or column-wise vectors.

    if ((size(S1, 1)~ = 1) & (size(S1, 2)~ = 1)) | ((size(S2, 1)~ = 1) & ...
        (size(S2, 2)~ = 1))
        error('S1 and S2 must be row or column vectors.');
    end 

    N1 = length(S1);
    N2 = length(S2);
    S1 = reshape(S1, N1, 1); % S1 & S2 are reshaped into column-wise
    S2 = reshape(S2, N2, 1); % vectors since MATLAB is more efficient
    % when manipulating columns.
    S1 = [S1; zeros(N2 - N1, 1)]; % Ensure that S1 & S2 are the same size,
    S2 = [S2; zeros(N1 - N2, 1)]; % padding the smaller one w/ 0s as neeeded.
    % This WHILE loop simply ensures that the length of S1 & S2 is a power
    % of two. If not, the vectors are padded with 0s until their length
    % is a power of two. This is not required, but it takes advantage of
    % the fact that MATLAB's FFT computation is significantly faster for
    % lengths which are powers of two!

    while log(length(S1)) / log(2)~ = round(log(length(S1)) / log(2))
        S1(length(S1) + 1) = 0;
        S2(length(S2) + 1) = 0;
    end 

    N = length(S1);
    % Ensures that the Tau values entered are in the valid range.

    if abs(Tau_Lo) > N | abs(Tau_Hi) > N
        error('Tau_Lo and Tau_Hi must be in the range -N to +N.');
    end 

    % Ensures that Tau values entered by the user are integers.

    if (Tau_Lo~ = round(Tau_Lo)) | (Tau_Hi~ = round(Tau_Hi))
        error('Tau_Lo and Tau_Hi must be integers.')
    end 

    % Ensures that the Frequency values entered are in the valid range.

    if abs(Freq_Lo) > 1/2 | abs(Freq_Hi) > 1/2
        error('Freq_Lo and Freq_Hi must be in the range -.5 to +.5');
    end 

    % Ensures that the lower bounds are less than the upper bounds.

    if (Tau_Lo > Tau_Hi) | (Freq_Lo > Freq_Hi)
        error('Lower bounds must be less than upper bounds.')
    end 

    % Freq values converted into integers for processing.
    Freq_Lo = round(Freq_Lo * N);
    Freq_Hi = round(Freq_Hi * N);
    % Creates vectors for the Tau & Freq values entered by the user. Used
    % for plotting...
    TauValues = [Tau_Lo:Tau_Hi];
    FreqValues = [Freq_Lo:Freq_Hi] / N;
    % The IF statement calculates the indices required to isolate the
    % user-defined frequencies from the FFT calculations below.

    if Freq_Lo < 0 & Freq_Hi < 0
        Neg_Freq = (N + Freq_Lo + 1:N + Freq_Hi + 1);
        Pos_Freq = [];
    elseif Freq_Lo < 0 & Freq_Hi >= 0
        Neg_Freq = (N + Freq_Lo + 1:N);
        Pos_Freq = (1:Freq_Hi + 1);
    else 
        Neg_Freq = [];
        Pos_Freq = (Freq_Lo + 1:Freq_Hi + 1);
    end 

    % This FOR loop actually calculates the Cross Ambiguity Function for
    % the given range of Taus and Frequencies. Note that an FFT is
    % performed for each Tau value and then the frequencies of interest
    % are isolated using the Neg_Freq and Pos_Freq vectors obtained above.
    % For each value of Tau, the vector S2 is shifted Tau samples using a
    % call to the separate function "SHIFTUD". Samples shifted out are
    % deleted and zeros fill in on the opposite end.
    % Initializing Amb with 0s makes computations much faster.
    Amb = zeros(length(Neg_Freq) + length(Pos_Freq), length(TauValues));

    for t = 1:length(TauValues)
        temp = fft((S1) .* conj(shiftud(S2, TauValues(t), 0)));
        Amb(:, t) = [temp(Neg_Freq); temp(Pos_Freq)];
    end 

    % Only interested in the Magnitude of the Cross Ambiguity Function.
    Amb = abs(Amb);
    % The following will remove any spike that occurs at Tau = FreqOff = 0.
    % This may be desired in some cases, especially when the spike at (0,0)
    % is due to correlation of the two signals' noise components. The
    % spike, of course, could also indicate that the two signals have no
    % TDOA or FDOA between them.
    % if find(TauValues == 0) & find(FreqValues == 0)
    % Amb(find(FreqValues==0),find(TauValues==0)) = 0;
    % end
    %clc; %Clears the MATLAB command window.
    % The four different views of the Cross Ambiguity Function plots are
    % created here.
    figure% This one is the 3-D view
    mesh(TauValues / fs, FreqValues * fs, Amb);
    xlabel('TDOA (Seconds)'); ylabel('FDOA (Hertz)');
    zlabel('Magnitude');
    title('Cross Ambiguity Function');
    figure
    subplot(2, 1, 1)% This one is the 2-D view along the TDOA axis
    mesh(TauValues / fs, FreqValues * fs, Amb);
    xlabel('TDOA (Seconds)');
    zlabel('Magnitude');
    view(0, 0);
    subplot(2, 1, 2)% This one is the 2-D view along the FDOA axis
    mesh(TauValues / fs, FreqValues * fs, Amb);
    ylabel('FDOA (Hertz)');
    zlabel('Magnitude');
    view(90, 0);
    %This one is a 2-D view looking down on the plane
    figure
    mesh(TauValues / fs, FreqValues * fs, Amb);
    xlabel('TDOA (Seconds)'); ylabel('FDOA (Hertz)');
    zlabel('Magnitude');
    title('Cross Ambiguity Function');
    view(0, 90);
    % Finds the indices of the peak value.
    [DFO, DTO] = find(Amb == max(max(Amb)));
    TDOA = TauValues(DTO); % Finds the actual value of the TDOA.
    FDOA = FreqValues(DFO); % Finds the actual value of the FDOA.
    MaxAmb = max(max(Amb)); % Finds the actual Magnitude of the peak.
    % The remaining lines will display the numerical results of the
    % TDOA & FDOA, if desired. Since the FFT method was used for the
    % calculations, the TDOA is accurate only to within +/- 0.5 samples,
    % and the FDOA is accurate to within +/- 0.5/N in digital frequency.
    % disp(' '); disp(' ');
    % disp(['The TIME LAG (TDOA) is: ', num2str(TDOA), ' Samples.']);
    % disp(' ');
    % disp(['The FREQ OFFSET (FDOA) is: ', num2str(FDOA), ...
    % ' (Fraction of Fs).']);
    % disp(' '); disp(['Maximum Magnitude = ', num2str(MaxAmb)]);
    % disp(' '); disp('-----------------------------');
    % disp('NOTE: If the CAF plot has secondary peaks whose magnitudes');
    % disp(' are within about 80% of the Main Peak''s magnitude,');
    % disp(' then the above results may be unreliable. Likely');
    % disp(' reasons: The true peak is not within the range of,');
    % disp(' Taus & Freq Offsets that you entered or the signals');
    % disp(' may be too noisy to detect the peak.');
