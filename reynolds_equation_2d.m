clc
clear

nodes_x= 100;
nodes_z = 100;
hi = 0.00005;
ho = 0.000005;
length = 1;
width = 1;
velocity = 2;
viscosity = 0.02;
over_relaxation_factor = 1.4;

dx = length / (nodes_x - 1);
dz = width / (nodes_z - 1);

x = zeros(1, nodes_x);
h = zeros(nodes_z, nodes_x);

for i = 1 : nodes_x
    for k = 1 : nodes_z
       x(i) = (i - 1) * dx;
       h(i,k) = ho + (hi - ho) * (length - x(i)) / length;
    end
end


a1 = zeros(nodes_x, nodes_z);
a2 = zeros(nodes_x, nodes_z);
a3 = zeros(nodes_x, nodes_z);
a4 = zeros(nodes_x, nodes_z);
a5 = zeros(nodes_x, nodes_z);
a6 = zeros(nodes_x, nodes_z);
a7 = (2 / (dx * dx)) + (2 / (dz * dz));

p = zeros(nodes_x, nodes_z);
p_new = zeros(nodes_x, nodes_z);

for iter = 1 : 5000
    sum = 0;
    sum_new = 0;
    for k = 2 : nodes_x - 1
        for i = 2 : nodes_z - 1
    	    a1(i,k) = (p(i+1,k) - p(i-1,k)) / (2 * dx);
            a2(i,k) = (h(i+1,k) - h(i-1,k)) / (2 * dx);
            a3(i,k) = (6 * viscosity * velocity) / ((h(i,k)) ^ 3);
            a4(i,k) = 3 / h(i,k);
            a5(i,k) = (p(i+1,k) + p(i-1,k)) / (dx ^ 2);
            a6(i,k) = (p(i,k+1) + p(i,k-1)) / (dz ^ 2);
            p_new(i,k) = -(1 / a7) * ((-a4(i,k) * a1(i,k) + a3(i,k)) * a2(i,k) - a5(i,k) - a6(i,k));
            p(i,k) = p(i,k) + (p_new(i,k) - p(i,k)) * over_relaxation_factor;
            sum = sum + abs(p(i,k) - p_new(i,k));
            sum_new = sum_new + abs(p_new(i,k));
        end
    end
    error = sum / sum_new;
    if (error < 0.000001)
        break;
    end
end