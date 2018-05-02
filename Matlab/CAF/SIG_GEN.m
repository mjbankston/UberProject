function [Sa1, Sa2, S1, S2] = sig_gen;
    % *********************************************************************
    % SIG_GEN generates BPSK signal pairs based upon user-defined param-
    % eters and Cartesian emitter-collector geometries. There are
    % no input arguments, since the function queries the user for
    % all required inputs. The function returns four vectors:
    % Sa1, Sa2, S1 & S2. These are the Analytic Signal represen-
    % tations of the two generated signals, and the Real represen-
    % tations of the two signals, respectively.
    %
    % Written by: LCDR Joe J. Johnson, USN
    % Last modified: 26 August 2001
    % *********************************************************************
    clc;
    disp(' ');
    disp('All positions and velocites must be entered in vector format,');
    disp('e.g., [X Y Z] or [X, Y, Z] (including the brackets).');
    disp(' ');
    Pc1(1, :) = input...
    ('Collector 1''s POSITION Vector at time 0 (in meters)? ');
    Vc1 = input('Collector 1''s VELOCITY Vector (in m/s)? '); disp(' ');
    Pc2(1, :) = input...
    ('Collector 2''s POSITION Vector at time 0 (in meters)? ');
    Vc2 = input('Collector 2''s VELOCITY Vector (in m/s)? '); disp(' ');
    Pe(1, :) = input...
    ('Emitter''s POSITION Vector at time 0 (in meters)? ');
    Ve = input('Emitter''s VELOCITY Vector (in m/s)? '); disp(' ');
    % f0 and fs are the same for BOTH collectors!
    f0 = input('Carrier Frequency (in Hz)? ');
    fs = input('Sampling Frequency (in Hz)? ');
    Ts = 1 / fs; % Calculates Sample Period
    Rsym = input('Symbol Rate (in symbols/s)? '); disp(' ');
    Tsym = 1 / Rsym; % Calculates Symbol Period
    N = input('How many samples? '); disp(' ');
    Es_No1 = input('Desired Es/No at Collector 1 (in dB)? ');
    Es_No1 = 10^(Es_No 1/10); % Converts from dB to ratio
    Es_No2 = input('Desired Es/No at Collector 2 (in dB)? ');
    disp(' ');
    Es_No2 = 10^(Es_No 2/10); % Converts from dB to ratio
    Pc1 = [Pc1; zeros(N - 1, 3)]; % Initializing all the matrices makes
    Pe1 = zeros(N, 3); % later computations much faster.
    Pc2 = [Pc2; zeros(N - 1, 3)];
    Pe2 = zeros(N, 3);
    t1 = zeros(1, N);
    t2 = zeros(1, N);
    S1 = zeros(1, N);
    S2 = zeros(1, N);
    A = 1; % Amplitude of Signal
    c = 2.997925e8; % Speed of light in m/s
    Ps = (A^2) / 2; % Power of Signal
    sigma1 = sqrt(Ps * Tsym / Es_No1); % Calculate Noise Amplification fac-
    sigma2 = sqrt(Ps * Tsym / Es_No2); % tors using Es/No = Ps*Tsym/sigma^2
    Noise1 = sigma1 .* randn(N, 1); % Random Noise values for Signal 1
    Noise2 = sigma2 .* randn(N, 1); % Random Noise values for Signal 2
    % Builds the position vectors for the two collectors

    for index = 2:N
        Pc1(index, :) = Pc1(index - 1, :) + Ts * Vc1;
        Pc2(index, :) = Pc2(index - 1, :) + Ts * Vc2;
    end 

    % While loop determines first elements of Pe1 and t1. t1(1) is the
    % time AT THE EMITTER that produces the 1st sample received at
    % collector 1! Pe1(1,:) is the position of the emitter when it
    % produces the 1st sample received by collector 1.
    temp = inf; % Ensures while loop executes at least once
    t1(1) = 0;
    tempPe = Pe(1, :);

    while abs(temp - t1(1)) > 1 / f0
        temp = t1(1);
        t1(1) =- norm(Pc1(1, :) - tempPe) / c;
        tempPe = Pe(1, :) + t1(1) * Ve;
    end 

    Pe1(1, :) = tempPe;
    % While loop determines first elements of Pe2 and t2. t2(1) is the
    % time AT THE EMITTER that produces the 1st sample received at
    % collector 2! Pe2(1,:) is the position of the emitter when it
    % produces the 1st sample received by collector 2.
    temp = inf; % Ensures while loop executes at least once
    t2(1) = 0;
    tempPe = Pe(1, :);

    while abs(temp - t2(1)) > 1 / f0
        temp = t2(1);
        t2(1) =- norm(Pc2(1, :) - tempPe) / c;
        tempPe = Pe(1, :) + t2(1) * Ve;
    end 

    Pe2(1, :) = tempPe;
    % Determines the earliest time at the emitter for this pair of signals.
    StartPoint = min(t1(1), t2(1));
    % Next 2 lines determine offsets needed for signals 1 & 2 to enter the
    % phase vector (P). This simply ensures proper line up so that bit
    % changes occur at the right times.
    SymbolIndex1 = 1 + floor(abs(t1(1) - t2(1)) / Tsym) * (t1(1) > t2(1));
    SymbolIndex2 = 1 + floor(abs(t1(1) - t2(1)) / Tsym) * (t2(1) > t1(1));

    for index = 2:N% Builds the Pe1 and t1 vectors
        temp = inf;
        t1(index) = 0;
        % 1st guess is that emitter will advance exactly Ts seconds.
        tempPe = Pe1(1, :) + (t1(index - 1) + Ts) * Ve;
        % While loop iteratively determines actual time & position for
        % emitter, based on instantaneous geometry.

        while abs(temp - t1(index)) > 1 / f0
            temp = t1(index);
            t1(index) = (index - 1) * Ts - norm(Pc1(index, :) - tempPe) / c;
            % Due to negative times, must multiply Ve by ELAPSED time!
            tempPe = Pe1(1, :) + abs(t1(1) - t1(index)) * Ve;
        end 

        Pe1(index, :) = tempPe;
    end 

    for index = 2:N% Builds the Pe2 and t2 vectors
        temp = inf;
        t2(index) = 0;
        % 1st guess is that emitter will advance exactly Ts seconds.
        tempPe = Pe2(1, :) + (t2(index - 1) + Ts) * Ve;
        % While loop iteratively determines actual time & position for
        % emitter, based on instantaneous geometry.

        while abs(temp - t2(index)) > 1 / f0
            temp = t2(index);
            t2(index) = (index - 1) * Ts - norm(Pc2(index, :) - tempPe) / c;
            % Due to negative times, must multiply Ve by ELAPSED time!
            tempPe = Pe2(1, :) + abs(t2(1) - t2(index)) * Ve;
        end 

        Pe2(index, :) = tempPe;
    end 

    % Could change this seed to whatever you want; or could have user
    % define it as an input. This just ensures, for simulation purposes
    % that every time the program is run, the BPSK signals created will
    % have the same random set of data bits.
    rand('seed', 5);
    % Create enough random #'s to figure phase shift (data bits)
    r = rand(N, 1);
    P = (r > 0.5) * 0 + (r <= 0.5) * 1; % Since BPSK, random # determines
    % if phase is 0 or pi
    % Building Xmitted Signal #1 vector... These represent the pieces of
    % the signal that were transmitted by the emitter to arrive at
    % Collector 1 at its sample intervals.
    S1(1) = A * cos(2 * pi * f0 * t1(1) + P(SymbolIndex1) * pi) + Noise1(1);
    % The if statement inside the loop changes the data bit if the time
    % has advanced into the next symbol period.

    for index = 2:N

        if t1(index) - StartPoint >= (SymbolIndex1) * Tsym
            SymbolIndex1 = SymbolIndex1 + 1;
        end 

        S1(index) = A * cos(2 * pi * f0 * t1(index) + P(SymbolIndex1) * pi) + ...
        Noise1(index);
    end 

    Sa1 = hilbert(S1); % Calculates the ANALYTIC SIGNAL of S1. To
    % compute the COMPLEX ENVELOPE, multiply Sa1
    % by .*exp(-j*2*pi*f0.*t1);
    % Building Xmitted Signal #2 vector... These represent the pieces of
    % the signal that were transmitted by the emitter to arrive at
    % Collector 2 at its sample intervals.
    S2(1) = A * cos(2 * pi * f0 * t2(1) + P(SymbolIndex2) * pi) + Noise2(1);
    % The if statement inside the loop changes the data bit if the time
    % has advanced into the next symbol period.

    for index = 2:N

        if t2(index) - StartPoint >= (SymbolIndex2) * Tsym
            SymbolIndex2 = SymbolIndex2 + 1;
        end 

        S2(index) = A * cos(2 * pi * f0 * t2(index) + P(SymbolIndex2) * pi) + ...
        Noise2(index);
    end 

    Sa2 = hilbert(S2); % Calculates the ANALYTIC SIGNAL of S2. To
    % compute the COMPLEX ENVELOPE, multiply Sa2
    % by .*exp(-j*2*pi*f0.*t2);
    % This function call simply calculates and displays the expected TDOAs
    % and FDOAs at the Beginning and End of the collection time.
    tdoa_fdoa(f0, Pe1(1, :), Pe1(N, :), Pe2(1, :), Pe2(N, :), Ve, Pc1(1, :), ...
    Pc1(N, :), Vc1, Pc2(1, :), Pc2(N, :), Vc2);
