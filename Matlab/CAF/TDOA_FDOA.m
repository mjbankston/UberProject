function [TDOA_b, TDOA_e, FDOA_b, FDOA_e] = tdoa_fdoa(f0, Pe1_b, ...
    Pe1_e, Pe2_b, Pe2_e, Ve, Pc1_b, Pc1_e, Vc1, Pc2_b, Pc2_e, Vc2)
    % *********************************************************************
    % TDOA_FDOA is for use with SIG_GEN.m in helping to determine what the
    % expected TDOA and FDOA are for two signal vectors.
    %
    % The function takes the following input arguments:
    %
    %
    % f0 -- carrier frequency(assumed to be equal for both signals)
    % Pe1_b -- [X Y Z] Emitter position WRT Collector 1 at 1st sample
    % Pe1_e -- [X Y Z] Emitter position WRT Collector 1 at last sample
    % Pe2_b -- [X Y Z] Emitter position WRT Collector 2 at 1st sample
    % Pe2_e -- [X Y Z] Emitter position WRT Collector 2 at last sample
    % Ve -- [X Y Z] Emitter velocity
    % Pc1_b -- [X Y Z] Collector 1 position at 1st sample
    % Pc1_e -- [X Y Z] Collector 1 position at last sample
    % Vc1 -- [X Y Z] Collector 1 velocity
    % Pc2_b -- [X Y Z] Collector 2 position at 1st sample
    % Pc2_e -- [X Y Z] Collector 2 postion at last sample
    % Vc2 -- [X Y Z] Collector 2 velocity
    %
    % The output variables are the TDOA at the beginning, TDOA at the
    % end, FDOA at the beginning, and FDOA at the end, respectively.
    % Written by: LCDR Joe J. Johnson, USN
    % Last modified: 26 August 2001
    % *********************************************************************
    c = 2.997925e8; % Speed of light
    % The next two lines calculate the Doppler shifts between the emitter
    % and Collector 1 & Collector 2, respectively, at the BEGINNING of the
    % collection (i.e., at the instant of the first sample).
    doppler1_b = f0 / c * dot(Ve - Vc1, Pe1_b - Pc1_b) / norm(Pe1_b - Pc1_b);
    doppler2_b = f0 / c * dot(Ve - Vc2, Pe2_b - Pc2_b) / norm(Pe2_b - Pc2_b);
    % Calculates the FDOA at the BEGINNING of collection time.
    FDOA_b = doppler1_b - doppler2_b;
    % Calculates Doppler shifts between emitter and each collector at the
    % END of the collection time (i.e., at instant of the last sample).
    doppler1_e = f0 / c * dot(Ve - Vc1, Pe1_e - Pc1_e) / norm(Pe1_e - Pc1_e);
    doppler2_e = f0 / c * dot(Ve - Vc2, Pe2_e - Pc2_e) / norm(Pe2_e - Pc2_e);
    % Calculates the FDOA at the END of collection time
    FDOA_e = doppler1_e - doppler2_e;
    % Calculates the TDOA between the two collectors at the BEGINNING
    % and END of collection time.
    TDOA_b = (norm(Pe2_b - Pc2_b) - norm(Pe1_b - Pc1_b)) / c;
    TDOA_e = (norm(Pe2_e - Pc2_e) - norm(Pe1_e - Pc1_e)) / c;
    % Displays the results in the command window.
    disp(' '); disp(' '); disp(' ');
    disp(['At the START of the Collection, TDOA = ', num2str(TDOA_b), ...
    ' seconds.']);
    disp([' FDOA = ', num2str(FDOA_b), ...
    ' Hertz.']);
    disp(' '); disp(' ');
    disp(['At the END of the Collection, TDOA = ', num2str(TDOA_e), ...
    ' seconds.']);
    disp([' FDOA = ', num2str(FDOA_e), ...
    ' Hertz.']);
