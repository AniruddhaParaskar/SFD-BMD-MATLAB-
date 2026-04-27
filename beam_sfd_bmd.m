clc; clear; close all;

beamType = input('Beam type (1: Simply Supported, 2: Cantilever, 3: Overhang): ');
L = input('Beam length (m): ');

if beamType == 3
    Ls = input('Intermediate support position from left (m): ');
end

x = 0:0.01:L;
S = zeros(size(x));
M = zeros(size(x));

nLoads = input('Number of loads: ');
loads = [];

for k = 1:nLoads
    fprintf('\nLoad %d\n', k);
    type = input('Type (1: Point, 2: UDL, 3: UVL): ');
    if type == 1
        P = input('Magnitude (N): ');
        a = input('Position (m): ');
        loads = [loads; 1 P a 0 0 0];
    elseif type == 2
        w = input('Intensity (N/m): ');
        a = input('Start (m): ');
        b = input('End (m): ');
        loads = [loads; 2 w a b 0 0];
    elseif type == 3
        w1 = input('Start intensity (N/m): ');
        w2 = input('End intensity (N/m): ');
        a  = input('Start (m): ');
        b  = input('End (m): ');
        loads = [loads; 3 w1 w2 a b 0];
    end
end

R1 = 0; R2 = 0;

if beamType == 1
    sumF = 0; sumM = 0;
    for i = 1:size(loads,1)
        if loads(i,1) == 1
            P = loads(i,2); a = loads(i,3);
            sumF = sumF + P;
            sumM = sumM + P*a;
        elseif loads(i,1) == 2
            w = loads(i,2); a = loads(i,3); b = loads(i,4);
            W = w*(b-a);
            xbar = (a+b)/2;
            sumF = sumF + W;
            sumM = sumM + W*xbar;
        elseif loads(i,1) == 3
            w1 = loads(i,2); w2 = loads(i,3);
            a  = loads(i,4); b  = loads(i,5);
            W  = (w1 + w2)/2 * (b-a);
            if (w1 + w2) ~= 0
                xbar = a + (b-a)*(w1 + 2*w2) / (3*(w1 + w2));
            else
                xbar = (a+b)/2;
            end
            sumF = sumF + W;
            sumM = sumM + W*xbar;
        end
    end
    R2 = sumM / L;
    R1 = sumF - R2;

elseif beamType == 2
    sumF = 0;
    for i = 1:size(loads,1)
        if loads(i,1) == 1
            sumF = sumF + loads(i,2);
        elseif loads(i,1) == 2
            w = loads(i,2); a = loads(i,3); b = loads(i,4);
            sumF = sumF + w*(b-a);
        elseif loads(i,1) == 3
            w1 = loads(i,2); w2 = loads(i,3);
            a  = loads(i,4); b  = loads(i,5);
            sumF = sumF + (w1+w2)/2*(b-a);
        end
    end
    R1 = sumF;
    R2 = 0;

elseif beamType == 3
    sumF = 0; sumM = 0;
    for i = 1:size(loads,1)
        if loads(i,1) == 1
            P = loads(i,2); a = loads(i,3);
            sumF = sumF + P;
            sumM = sumM + P*a;
        elseif loads(i,1) == 2
            w = loads(i,2); a = loads(i,3); b = loads(i,4);
            W = w*(b-a);
            xbar = (a+b)/2;
            sumF = sumF + W;
            sumM = sumM + W*xbar;
        elseif loads(i,1) == 3
            w1 = loads(i,2); w2 = loads(i,3);
            a  = loads(i,4); b  = loads(i,5);
            W  = (w1+w2)/2*(b-a);
            if (w1+w2) ~= 0
                xbar = a + (b-a)*(w1+2*w2)/(3*(w1+w2));
            else
                xbar = (a+b)/2;
            end
            sumF = sumF + W;
            sumM = sumM + W*xbar;
        end
    end
    R2 = sumM / Ls;
    R1 = sumF - R2;
end

for i = 1:length(x)
    xi = x(i);
    shear = 0;

    for j = 1:size(loads,1)
        if loads(j,1) == 1
            a = loads(j,3);
            if xi <= a
                shear = shear + loads(j,2);
            end
        elseif loads(j,1) == 2
            a = loads(j,3); b = loads(j,4);
            w = loads(j,2);
            if xi <= a
                shear = shear + w*(b-a);
            elseif xi < b
                shear = shear + w*(b-xi);
            end
        elseif loads(j,1) == 3
            a  = loads(j,4); b = loads(j,5);
            w1 = loads(j,2); w2 = loads(j,3);
            if xi <= a
                shear = shear + (w1+w2)/2*(b-a);
            elseif xi < b
                wx = w1 + (w2-w1)*(xi-a)/(b-a);
                shear = shear + (wx+w2)/2*(b-xi);
            end
        end
    end

    if beamType == 1 && xi < L
        shear = shear - R2;
    elseif beamType == 3 && xi < Ls
        shear = shear - R2;
    end

    S(i) = shear;
end

for i = 2:length(x)
    dx = x(i) - x(i-1);
    M(i) = M(i-1) + S(i-1)*dx;
end
M = -M;

figure;
subplot(2,1,1);
area(x, S, 'FaceAlpha', 0.3, 'LineWidth', 2);
xlabel('Length (m)'); ylabel('Shear Force (N)');
title('Shear Force Diagram'); grid on;

subplot(2,1,2);
area(x, M, 'FaceAlpha', 0.3, 'LineWidth', 2);
xlabel('Length (m)'); ylabel('Bending Moment (N·m)');
title('Bending Moment Diagram'); grid on;

fprintf('\n--- Reactions ---\n');
if beamType == 1
    fprintf('R1 (at x=0)    = %.2f N\n', R1);
    fprintf('R2 (at x=%.2f) = %.2f N\n', L, R2);
elseif beamType == 2
    fprintf('R1 - Fixed end reaction (at x=0) = %.2f N\n', R1);
elseif beamType == 3
    fprintf('R1 (at x=0)    = %.2f N\n', R1);
    fprintf('R2 (at x=%.2f) = %.2f N\n', Ls, R2);
end