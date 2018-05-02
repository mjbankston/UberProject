function y = shiftud(a, n, cs)
    % *********************************************************************
    % SHIFTUD Shift or Circularly Shift Matrix Rows
    % SHIFTUD(A,N) with N<0 shifts the rows of A DOWN N rows.
    % The first N rows are replaced by zeros and the last N
    % rows of A are deleted.
    %
    % SHIFTUD(A,N) with N>0 shifts the rows of A UP N rows.
    % The last N rows are replaced by zeros and the first N
    % rows of A are deleted.
    %
    % SHIFTUD(A,N,C) where C is nonzero performs a circular
    % shift of N rows, where rows circle back to the other
    % side of the matrix. No rows are replaced by zeros.
    %
    % Copyright (c) 1996 by Prentice-Hall, Inc. � Reference [9]
    % *********************************************************************

    if nargin < 3, cs = 0; end% If no third argument, default is False
        cs = cs(1); % Make sure third argument is a scalar
        [r, c] = size(a); % Get dimensions of input
        dn = (n <= 0); % dn is True if shift is down
        n = min(abs(n), r); % Limit shift to less than rows

        if n == 0 | (cs & n == r)% Simple no shift case
            y = a;
        elseif ~cs & dn% No circular and down
            y = [zeros(n, c); a(1:r - n, :)];
        elseif ~cs & ~dn% No circular and up
            y = [a(n + 1:r, :); zeros(n, c)];
        elseif cs & dn% Circular and down
            y = [a(r - n + 1:r, :); a(1:r - n, :)];
        elseif cs & ~dn% Circular and up
            y = [a(n + 1:r, :); a(1:n, :)];
        end 
