clc

nodes = 100;
hi = 0.00005;
ho = 0.000005;
length = 1;
velocity = 2;
viscosity = 0.02;
over_relaxation_factor = 1.4;

dx = length / (nodes - 1);

x = zeros(1, nodes);
h = zeros(1, nodes);

for i = 1 : nodes
    x(i) = (i - 1) * dx;
    h(i) = (hi - ho) * (1 - (x(i) / length)) + ho;
end

a1 = zeros(1, nodes);
a2 = zeros(1, nodes);
a3 = zeros(1, nodes);
a4 = zeros(1, nodes);
a5 = zeros(1, nodes);
a6 = (-1) * (dx * dx) / 2;

p = zeros(1, nodes);
pnew = zeros(1, nodes);

for iter = 1 : 5000
    sum = 0;
    sum_new = 0;
    for i = 2 : (nodes - 1)
        a1(i) = (h(i + 1) - h(i - 1)) / (2 * dx);
        a2(i) = (p(i + 1) - p(i - 1)) / (2 * dx);
        a3(i) = (p(i + 1) + p(i - 1)) / (dx * dx);
        a4(i) = (6 * viscosity * velocity) / (h(i) ^ 3);
        a5(i) = 3 / h(i);
        pnew(i) = a6 * ((a4(i) - a5(i) * a2(i)) * a1(i) - a3(i));
        p(i) = p(i) + (pnew(i) - p(i)) * over_relaxation_factor;
        sum = sum + abs(p(i) - pnew(i));
        sum_new = sum_new + abs(pnew(i));
    end
    error = sum / sum_new;
    if (error < 0.00001)
        break;
    end
end