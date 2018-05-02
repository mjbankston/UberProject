function [TDOA, FDOA] = CAF(S1, S2, Max_f, fs, Max_t);
    % *********************************************************************
    % CAF takes as inputs two sampled signal vectors (S1 & S2) in analytic
    % signal format, the maximum expected FDOA in Hertz (Max_f), the
    % sampling frequency used to generate S1 & S2 (fs), and the maximum
    % expected TDOA in seconds (Max_t). The function then utilizes
    % Stein's method in [1] to compute coarse estimations of TDOA and
    % FDOA between S1 & S2. Finally, "fine mode" calcualtions are made
    % to compute the final TDOA and FDOA, which are returned to the
    % user via the output arguments.
    % Written by: LCDR Joe J. Johnson, USN
    % Last modified: 17 September 2001
    % *********************************************************************
    clc;
    N = length(S1);
    S1 = reshape(S1, N, 1); % Ensures signals are column vectors due to
    S2 = reshape(S2, N, 1); % Matlab's better efficiency on columns
    S1_orig = S1; % Want to preserve original input signals
    S2_orig = S2; % for later use; S1 & S2 will be
    % manipulated in the fine mode below.
    % The following while loop ensures that the sub-block size, N1, is
    % large enough to ensure proper resolution. If Max_f/fs*N1 were
    % less than 1, then the Freq calculated at the end would always be
    % + or - 1/N1! 2^19 = 524288 is about the limit for efficient
    % processing speed.
    N1 = 1024;

    while (Max_f / fs * N1 < 2) & (N1 < 2^19)
        N1 = 2 * N1;
    end 

    N2 = N 1/2;

    if N1 > N% For cases where resolution calls for
        S1 = [S1; zeros(N1 - N, 1)]; % a sub-block size larger than the
        S2 = [S2; zeros(N1 - N, 1)]; % signal vectors, pad the vectors with
        N = N1; % zeros so that they have a total of
    end % N1 elements.

    % Want magnitude of Max_f, since +&- will be used below
    Max_f = abs(Max_f);
    Number_of_Blocks = length(S1) / N1; % Number of sub-blocks to break
    % the signal into
    Min_v = floor(-Max_f / fs * N1); % Smallest freq bin to search
    Max_v =- Min_v; % Largest freq bin to search
    v_values = Min_v:Max_v; % Vector of all bins to search
    Max_samples = Max_t * fs; % Maximum number of samples to search
    % Finds max number of block shifts (q) that must occur for each
    % R and v below.

    if Max_samples > N2
        q_max = min(ceil((Max_samples - N2) / N1), Number_of_Blocks - 1);
    else q_max = 0;
    end 

    x = 0;
    divisors = Number_of_Blocks:-1:1; % Used to scale "temp" below...
    % *********************************************************************
    % COARSE MODE computations.
    % *********************************************************************

    for v = 1:length(v_values)
        temp(1:N1, 1:q_max + 1) = 0; % Initializing -- saves time....

        for R = 0:Number_of_Blocks - 1
            % temp1 is the FFT of the R'th block of S1, shifted by "v" bins.
            temp1 = fftshift(fft(S1(1 + R * N1:N1 * (R + 1))));
            temp1 = shiftud(temp1, v_values(v), 0);

            for q = 0:q_max
                % R+q cannot exceed the number of sub-blocks

                if R + q > Number_of_Blocks - 1 break
                end 

                % FFT of the (R+q)'th block of S2
                temp2 = fftshift(fft([S2(1 + (R + q) * N1:N2 + N1 * (R + q)); ...
                zeros(N2, 1)]));
                % Multiplies temp1 & temp2, FFTs the product, then adds to
                % previous values for the same value of q (but different R)
                temp(:, q + 1) = temp(:, q + 1) + ...
                abs(fftshift(fft(temp1 .* conj(temp2))));
            end 

        end 

        % Each value of q was used a different # of times, so they must be
        % scaled properly.

        for q_index = 1:q_max + 1
            temp(:, q_index) = temp(:, q_index) / divisors(q_index);
        end 

        % If combination of current v and any q provides a greater value
        % than the previous max, then remember m, Q, & V.

        if max(max(temp)) > x
            x = max(max(temp));
            [m Q] = find(temp == max(max(temp)));
            % Must do this since q starts at 0, but Matlab doesn't allow for
            % zero indexing.
            Q = Q - 1;
            V = v_values(v);
        end 

    end 

    % Coarse estimate of TDOA (in # of samples)
    TDOA_Coarse = Q * N1 + (-N2 + 1 + m);
    % Coarse estimate of FDOA (in Freq Bin #)
    FDOA_Coarse = V / N1 * N;
    % The following 3 lines can be used to display the coarse estimates,
    % if desired.
    %disp(['The coarse TDOA estimate is: ', num2str(TDOA_Coarse), ...
    % ' samples.']);
    %disp(['The coarse FDOA estimate is: ', num2str(FDOA_Coarse / N), ...
    % ' (digital frequency).']);
    % *********************************************************************
    % FINE MODE computations.
    % *********************************************************************
    S2 = conj(S2); % S2 is conjugated in basic CAF definition
    % Vector of freq "bins" to use (DON'T have to be integers!!)
    k_val = FDOA_Coarse - 10:FDOA_Coarse + 10;
    % Vectors of TDOAs to use (must be integers)
    tau_val = TDOA_Coarse - 10:TDOA_Coarse + 10;
    done = 0;
    multiple = 1;
    decimal = 0;

    while ~done% Fine mode iterations continue until user is done.
        % Initialize to make later computations faster
        amb(length(k_val), length(tau_val)) = 0;
        Ntemp = N * multiple;

        for k = 1:length(k_val)% Must loop through all values of k
            % Vector of complex exponentials that will be used
            exponents = exp(-j * 2 * pi * k_val(k) / Ntemp * (0:Ntemp - 1)');
            % Must loop through all potential TDOAs

            for t = 1:length(tau_val)
                % S2 is shifted "tau" samples
                S2temp = shiftud(S2, tau_val(t), 0);
                % Definition of CAF summation
                temp = abs(sum(S1 .* S2temp .* exponents));
                % Save CAF magnitude for the values of k & t
                amb(k, t) = temp;
            end 

        end 

        [k, t] = find(amb == max(max(amb))); % Find the peak of the CAF matrix
        TDOA = tau_val(t); % TDOA and FDOA associated with the peak of the
        FDOA = k_val(k); % CAF plane. These represent the final TDOA
        % & FDOA estimates.
        % The results are displayed.
        disp(' '); disp(' '); disp(' ');
        disp(['The TDOA is ', num2str(TDOA / multiple), ' samples']);
        disp([' or ', num2str(TDOA / (multiple * fs)), ' seconds.']);
        disp(' ');
        disp(['The resolution is ', num2str(0.5 / ...
        (multiple * fs)), ' seconds.']);
        disp(' '); disp(' ');
        disp(['The FDOA is ', num2str(FDOA / N), ...
        ' in digital frequency (k/N)']);
        disp([' or ', num2str(FDOA / N * fs), ' Hz.']); disp(' ');
        disp(['The resolution is ', num2str(0.5 * ...
        (10^decimal) / N * fs), ' Hz.']);
        disp(' '); disp(' '); disp(' ');
        % If the signal length exceeds 524288 elements, max processing
        % capability has been achieved, and the user will not be given
        % the option of refining TDOA any further.

        if Ntemp >= 2^19
            disp('Maximum TDOA processing capability has been achieved.')
            doneT = 1;
        else doneT = 0;
        end 

        % User chooses whether to compute more accurate TDOA &/or
        % FDOA, or to stop fine mode computations.
        disp('Do you desire a solution with finer resolution?');
        disp('Select one of the following:'); disp(' ');

        if ~doneT
            disp('1. Finer resolution for TDOA.');
        else disp(' ');
        end 

        disp('2. Finer resolution for FDOA.');

        if ~doneT
            disp('3. Finer resolution for both TDOA and FDOA.');
        else disp(' ');
        end 

        disp('4. The TDOA and FDOA resolutions are fine enough.');
        disp(' ');
        choice = input('What is your selection? ');

        switch choice
            % TDOA is refined by resampling the signals at twice the
            % previous sampling rate. Increases resolution two-fold.
        case 1

            if ~doneT
                multiple = multiple * 2;
                S1 = interp(S1, 2);
                S2 = interp(S2, 2);
                tau_val = TDOA * 2 - 1:TDOA * 2 + 1;
            else done = 1;
            end 

            clc;
            % FDOA resolution is improved by a factor of 10.
        case 2
            decimal = decimal - 1;
            k_val = FDOA - 5 * 10^decimal:10^decimal:FDOA + 5 * 10^decimal;
            clc;
            % Both TDOA and FDOA resolutions are improved.
        case 3

            if ~doneT
                multiple = multiple * 2;
                S1 = interp(S1, 2);
                S2 = interp(S2, 2);
                tau_val = TDOA * 2 - 1:TDOA * 2 + 1;
                decimal = decimal - 1;
                k_val = FDOA - 5 * 10^decimal:10^decimal:FDOA + ...
                5 * 10^decimal;
            else done = 1;
            end 

            clc;
        otherwise 
            done = 1;
        end 

        if done
            disp(' '); disp(' '); disp('TDOA & FDOA estimation complete.');
        end 

    end 

    % If user wants to see the CAF surface graphically, a call to
    % CAF_peak is made.
    disp(' '); %disp(' '); disp(' ');
    choice = input...
    ('Would you like to see the CAF peak graphically (Y or N)? ', 's');
    choice = upper(choice);

    switch choice
    case 'Y'
        caf_peak(S1_orig, S2_orig, floor(TDOA / multiple) - 50, ...
        floor(TDOA / multiple) + 50, (FDOA - 20) / N, (FDOA + 20) / N, fs);
    end 

    TDOA = TDOA / (multiple * fs); % Returns TDOA in seconds.
    FDOA = FDOA / N * fs; % Returns FDOA in Hertz.
    disp('Program Complete.');
